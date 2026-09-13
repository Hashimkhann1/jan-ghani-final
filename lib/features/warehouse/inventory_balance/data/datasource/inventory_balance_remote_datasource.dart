// Updated on 2026-09-12 12:50 PM
// =============================================================
// inventory_balance_remote_datasource.dart
// Warehouse app ka Supabase-side READ layer.
//
// Kaam ke 2 use-cases:
//   1. "Create Batch" panel — Supabase se pending inventory_counting
//      rows (last 7 din, given store, jo abhi tak kisi batch mein
//      consume nahi hui) fetch karo + product name/price join karo.
//   2. Report/history refresh — Supabase se inventory_balance_items
//      ke latest status pull karo (reviewer + branch ke updates
//      dikhen). Sync ek-taraf hai (local → Supabase), isliye branch
//      ke changes SIRF Supabase par visible hote hain.
// =============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/balance_status.dart';
import '../model/balance_batch_model.dart';
import '../model/balance_item_model.dart';

class InventoryBalanceRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  // Local sync ki behad common date-boundary helpers.
  String _dayStart(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

  String _dayAfter(DateTime d) => DateTime(d.year, d.month, d.day)
      .add(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);

  // ─────────────────────────────────────────────────────────
  // Pending counts — inventory_counting rows for a store,
  // filtered by counted_date (last N days), joined with
  // warehouse_products (name, sku, sale_price).
  //
  // consumedCountingIds — jo IDs pehle se local batch mein hain
  // unko UI par filter karke chhupa dega. (yahan bhi filter
  // apply kar sakte to double-fetch bache).
  // ─────────────────────────────────────────────────────────
  Future<List<PendingCountRow>> fetchPendingCounts({
    required String storeId,
    int daysBack = 7,
    Set<String>? excludeCountingIds,
  }) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: daysBack));

    List rows;
    try {
      rows = await _client
          .from('inventory_counting')
          .select('id, product_id, product_stock, counting_stock, counted_date, updated_at, store_id')
          .eq('store_id', storeId)
          .gte('counted_date', _dayStart(from))
          .lt ('counted_date', _dayAfter(now))
          .order('updated_at', ascending: false)
          .limit(1000);
    } on PostgrestException catch (e) {
      // Missing table (PGRST205) — testing DB par branch schema deploy nahi
      // hui hogi. Empty list return — UI graceful "koi pending nahi" dikhata.
      if (e.code == 'PGRST205') return const [];
      rethrow;
    }

    final list = (rows).cast<Map<String, dynamic>>();

    if (list.isEmpty) return const [];

    // Product IDs unique — ek shot mein warehouse_products se laa lo.
    final pids = list.map((r) => r['product_id'].toString()).toSet().toList();
    List products;
    try {
      products = await _client
          .from('warehouse_products')
          .select('id, name, sku, selling_price')
          .inFilter('id', pids);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') return const [];
      rethrow;
    }

    final byId = <String, Map<String, dynamic>>{};
    for (final p in products) {
      final m = p as Map<String, dynamic>;
      byId[m['id'].toString()] = m;
    }

    final result = <PendingCountRow>[];
    for (final r in list) {
      final countingId = r['id'].toString();
      if (excludeCountingIds != null && excludeCountingIds.contains(countingId)) {
        continue;
      }
      final p = byId[r['product_id'].toString()];
      if (p == null) continue; // product mila hi nahi — skip

      result.add(PendingCountRow(
        countingId:    countingId,
        productId:     r['product_id'].toString(),
        productName:   (p['name'] ?? '').toString(),
        productSku:    p['sku']?.toString(),
        systemStock:   _d(r['product_stock']),
        physicalStock: _d(r['counting_stock']),
        unitPrice:     _d(p['selling_price']),
        // updated_at (full timestamp, UTC) preferred — display side toLocal()
        // karega. Fallback: counted_date (sirf date, midnight ho jayega).
        countedAt:     _parseDate(r['updated_at'] ?? r['counted_date']),
        storeId:       storeId,
      ));
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────
  // Batch headers by ids (report grouping)
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
  // Report refresh — Supabase se items pull (latest status)
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceItemModel>> fetchItems({
    required String warehouseId,
    DateTime?      fromDate,
    DateTime?      toDate,
    BalanceStatus? status,
    String?        storeId,
    int            limit = 500,
  }) async {
    var q = _client
        .from('inventory_balance_items')
        .select()
        .eq('warehouse_id', warehouseId);

    if (storeId != null)  q = q.eq('store_id', storeId);
    if (status  != null)  q = q.eq('status', status.code);
    if (fromDate != null) q = q.gte('created_at', _dayStart(fromDate));
    if (toDate   != null) q = q.lt ('created_at', _dayAfter(toDate));

    final rows = await q.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((e) => BalanceItemModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ─────── helpers ────────
  double _d(dynamic v) => v == null
      ? 0.0
      : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);

  DateTime _parseDate(dynamic v) =>
      v is DateTime ? v : (DateTime.tryParse(v.toString()) ?? DateTime.now());
}
