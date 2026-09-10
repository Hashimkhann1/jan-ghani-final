// =============================================================
// inventory_review_remote_datasource.dart
// Accountant/Reviewer side — SUPABASE read + update.
//
// Reviewer accountant app par owner-dual-duty se aata hai. Uska
// koi local postgres nahi — sab kuch Supabase par seedha.
// =============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_batch_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/domain/balance_status.dart';

class InventoryReviewRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  String _dayStart(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

  String _dayAfter(DateTime d) => DateTime(d.year, d.month, d.day)
      .add(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);

  // ─────────────────────────────────────────────────────────
  // Pending items — reviewer ke queue ke liye
  //   status = 'review_pending'
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceItemModel>> fetchPendingItems({int limit = 500}) async {
    final rows = await _client
        .from('inventory_balance_items')
        .select()
        .eq('status', BalanceStatus.reviewPending.code)
        .order('created_at', ascending: true)
        .limit(limit);
    return (rows as List)
        .map((e) => BalanceItemModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // All items (history/report tab)
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceItemModel>> fetchItems({
    DateTime?      fromDate,
    DateTime?      toDate,
    BalanceStatus? status,
    String?        storeId,
    int            limit = 500,
  }) async {
    var q = _client.from('inventory_balance_items').select();
    if (status != null)  q = q.eq('status', status.code);
    if (storeId != null) q = q.eq('store_id', storeId);
    if (fromDate != null) q = q.gte('created_at', _dayStart(fromDate));
    if (toDate   != null) q = q.lt ('created_at', _dayAfter(toDate));

    final rows = await q.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((e) => BalanceItemModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // Batch headers — grouping (jitne batches ke andar pending
  // items hain woh dikhane ke liye)
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceBatchModel>> fetchBatchesByIds(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('inventory_balance_batches')
        .select()
        .inFilter('id', ids.toList());
    return (rows as List)
        .map((e) => BalanceBatchModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // Reviewer action: ACCEPT (single item)
  //   status → branch_pending
  //   reviewer_* fields set
  //   is_synced = true (Supabase update — local warehouse app sync
  //   nahi karti reviewer ki taraf; unko refresh par pata chalega)
  // ─────────────────────────────────────────────────────────
  Future<void> acceptItem({
    required String itemId,
    required String batchId,
    required String reviewerId,
    required String reviewerName,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    // 1. Item update — guarded by current status = 'review_pending' (idempotent)
    await _client
        .from('inventory_balance_items')
        .update({
          'status':                BalanceStatus.branchPending.code,
          'reviewer_id':           reviewerId,
          'reviewer_name':         reviewerName,
          'reviewer_reviewed_at':  now,
          'reviewer_reason':       null,
          'is_synced':             true,
          'synced_at':             now,
        })
        .eq('id', itemId)
        .eq('status', BalanceStatus.reviewPending.code);

    // 2. Log entry
    await _client.from('inventory_balance_log').insert({
      'id':         const Uuid().v4(),
      'item_id':    itemId,
      'batch_id':   batchId,
      'action':     'reviewer_accepted',
      'actor_id':   reviewerId,
      'actor_name': reviewerName,
      'actor_role': 'reviewer',
      'is_synced':  true,
      'synced_at':  now,
    });
  }

  // ─────────────────────────────────────────────────────────
  // Reviewer action: REJECT (single item)
  //   status → reviewer_rejected + reason
  // ─────────────────────────────────────────────────────────
  Future<void> rejectItem({
    required String itemId,
    required String batchId,
    required String reason,
    required String reviewerId,
    required String reviewerName,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('inventory_balance_items')
        .update({
          'status':                BalanceStatus.reviewerRejected.code,
          'reviewer_id':           reviewerId,
          'reviewer_name':         reviewerName,
          'reviewer_reviewed_at':  now,
          'reviewer_reason':       reason,
          'is_synced':             true,
          'synced_at':             now,
        })
        .eq('id', itemId)
        .eq('status', BalanceStatus.reviewPending.code);

    await _client.from('inventory_balance_log').insert({
      'id':         const Uuid().v4(),
      'item_id':    itemId,
      'batch_id':   batchId,
      'action':     'reviewer_rejected',
      'actor_id':   reviewerId,
      'actor_name': reviewerName,
      'actor_role': 'reviewer',
      'notes':      reason,
      'is_synced':  true,
      'synced_at':  now,
    });
  }
}
