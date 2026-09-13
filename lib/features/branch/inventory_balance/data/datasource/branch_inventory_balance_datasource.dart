// =============================================================
// branch_inventory_balance_datasource.dart
// Branch side — SUPABASE direct (like reviewer, see §9.4 of
// INVENTORY_BALANCE.md). Branch's queue = items with
// status='branch_pending' scoped to its own store_id.
//
// Accept = calls RPC `apply_inventory_balance_item` — the RPC
// does the whole "lock stock row → delta apply → stamp item →
// log" atomically in one DB transaction (§7.4).
// =============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_batch_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/domain/balance_status.dart';

class BranchInventoryBalanceApplyException implements Exception {
  final String code;
  const BranchInventoryBalanceApplyException(this.code);

  @override
  String toString() {
    switch (code) {
      case 'item_not_branch_pending':
        return 'Yeh item ab pending nahi hai (pehle hi process ho chuka hoga).';
      case 'stock_row_not_found':
        return 'Is product ki stock row nahi mili.';
      default:
        return 'Apply fail: $code';
    }
  }
}

class BranchInventoryBalanceDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  String _dayStart(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

  String _dayAfter(DateTime d) => DateTime(d.year, d.month, d.day)
      .add(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);

  // ─────────────────────────────────────────────────────────
  // Pending items — branch ke queue ke liye
  //   status = 'branch_pending' AND store_id = @storeId
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceItemModel>> fetchPendingItems({
    required String storeId,
    int limit = 500,
  }) async {
    final rows = await _client
        .from('inventory_balance_items')
        .select()
        .eq('status', BalanceStatus.branchPending.code)
        .eq('store_id', storeId)
        .order('created_at', ascending: true)
        .limit(limit);
    return (rows as List)
        .map((e) => BalanceItemModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // All items for this store (history tab)
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceItemModel>> fetchItems({
    required String storeId,
    DateTime?       fromDate,
    DateTime?       toDate,
    BalanceStatus?  status,
    int             limit = 500,
  }) async {
    var q = _client
        .from('inventory_balance_items')
        .select()
        .eq('store_id', storeId);
    if (status != null)   q = q.eq('status', status.code);
    if (fromDate != null) q = q.gte('created_at', _dayStart(fromDate));
    if (toDate   != null) q = q.lt ('created_at', _dayAfter(toDate));

    final rows = await q.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((e) => BalanceItemModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // Batch headers — grouping (queue mein batch card dikhane ke liye)
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
  // Branch action: ACCEPT + APPLY (atomic RPC — §7.4)
  // ─────────────────────────────────────────────────────────
  Future<void> acceptAndApplyItem({
    required String itemId,
    required String branchUserId,
    required String branchUserName,
  }) async {
    final result = await _client.rpc('apply_inventory_balance_item', params: {
      'p_item_id':          itemId,
      'p_branch_user_id':   branchUserId,
      'p_branch_user_name': branchUserName,
    });

    final map = result is Map
        ? Map<String, dynamic>.from(result)
        : <String, dynamic>{};
    if (map['success'] != true) {
      throw BranchInventoryBalanceApplyException(
          map['error']?.toString() ?? 'unknown_error');
    }
  }

  // ─────────────────────────────────────────────────────────
  // Branch action: REJECT (single item)
  //   status → branch_rejected + reason
  // ─────────────────────────────────────────────────────────
  Future<void> rejectItem({
    required String itemId,
    required String batchId,
    required String reason,
    required String branchUserId,
    required String branchUserName,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('inventory_balance_items')
        .update({
          'status':             BalanceStatus.branchRejected.code,
          'branch_user_id':     branchUserId,
          'branch_user_name':   branchUserName,
          'branch_reviewed_at': now,
          'branch_reason':      reason,
          'is_synced':          true,
          'synced_at':          now,
        })
        .eq('id', itemId)
        .eq('status', BalanceStatus.branchPending.code);

    await _client.from('inventory_balance_log').insert({
      'id':         const Uuid().v4(),
      'item_id':    itemId,
      'batch_id':   batchId,
      'action':     'branch_rejected',
      'actor_id':   branchUserId,
      'actor_name': branchUserName,
      'actor_role': 'branch',
      'notes':      reason,
      'is_synced':  true,
      'synced_at':  now,
    });
  }
}
