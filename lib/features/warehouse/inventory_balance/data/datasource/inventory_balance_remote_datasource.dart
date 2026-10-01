// Updated on 2026-10-01 05:10 PM
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
  // [fromDate]/[toDate] (counted_date, dono din shamil) — user ka date
  // filter. Na diye hon to purana default: last [daysBack] din.
  Future<List<PendingCountRow>> fetchPendingCounts({
    required String storeId,
    int daysBack = 7,
    DateTime? fromDate,
    DateTime? toDate,
    Set<String>? excludeCountingIds,
  }) async {
    final now  = DateTime.now();
    final from = fromDate ?? now.subtract(Duration(days: daysBack));
    final to   = toDate ?? now;

    // .range() pages — lambi date range mein 1000+ ginti ho to kat na jaye
    // (pehle .limit(1000) tha). id tie-breaker: same updated_at par
    // pages mein duplicate/miss na ho.
    const pageSize = 1000;
    final list = <Map<String, dynamic>>[];
    try {
      var offset = 0;
      while (true) {
        final rows = await _client
            .from('inventory_counting')
            .select('id, product_id, product_stock, counting_stock, counted_date, updated_at, store_id')
            .eq('store_id', storeId)
            .gte('counted_date', _dayStart(from))
            .lt ('counted_date', _dayAfter(to))
            .order('updated_at', ascending: false)
            .order('id', ascending: true)
            .range(offset, offset + pageSize - 1);
        final page = (rows as List).cast<Map<String, dynamic>>();
        list.addAll(page);
        if (page.length < pageSize) break;
        offset += pageSize;
      }
    } on PostgrestException catch (e) {
      // Missing table (PGRST205) — testing DB par branch schema deploy nahi
      // hui hogi. Empty list return — UI graceful "koi pending nahi" dikhata.
      if (e.code == 'PGRST205') return const [];
      rethrow;
    }

    if (list.isEmpty) return const [];

    // Product IDs unique — warehouse_products se laa lo.
    // ⚠️ .inFilter() saare IDs ko URL query string mein bhejta hai
    // (?id=in.(uuid1,uuid2,...)). Supabase gateway (Kong) ka URL length
    // limit ~8KB hai; 200+ UUIDs par 400 Bad Request return karta.
    // Fix: chunks (200 IDs ≈ 7.4KB URL — safe headroom ke saath).
    final pids = list.map((r) => r['product_id'].toString()).toSet().toList();
    const chunkSize = 200;
    final products = <Map<String, dynamic>>[];
    try {
      for (var i = 0; i < pids.length; i += chunkSize) {
        final end   = (i + chunkSize < pids.length) ? i + chunkSize : pids.length;
        final chunk = pids.sublist(i, end);
        final res = await _client
            .from('warehouse_products')
            .select('id, name, sku, selling_price')
            .inFilter('id', chunk);
        products.addAll((res as List).cast<Map<String, dynamic>>());
      }
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') return const [];
      rethrow;
    }

    final byId = <String, Map<String, dynamic>>{};
    for (final p in products) {
      byId[p['id'].toString()] = p;
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
  // ⚠️ .inFilter() saare IDs URL mein bhejta hai — 200+ IDs par gateway
  // 400 deta (Session 14 wala masla). Isliye 200-200 ke chunks.
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceBatchModel>> fetchBatchesByIds(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    const chunkSize = 200;
    final list = ids.toList();
    final out  = <BalanceBatchModel>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end   = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      final rows = await _client
          .from('inventory_balance_batches')
          .select()
          .inFilter('id', list.sublist(i, end));
      out.addAll((rows as List)
          .map((e) => BalanceBatchModel.fromMap(e as Map<String, dynamic>)));
    }
    return out;
  }

  // ─────────────────────────────────────────────────────────
  // Report refresh — Supabase se items pull (latest status)
  // Pehle limit(500) tha → zyada items par purane chupchaap kat jate
  // (KPI/summary kam). Ab .range() pages (1000-cap safe) — date range ke
  // SAARE items. [maxRows] diya ho to utne par ruk jata hai.
  // ─────────────────────────────────────────────────────────
  Future<List<BalanceItemModel>> fetchItems({
    required String warehouseId,
    DateTime?      fromDate,
    DateTime?      toDate,
    BalanceStatus? status,
    String?        storeId,
    int?           maxRows,
  }) async {
    const pageSize = 1000;
    final out = <BalanceItemModel>[];
    var offset = 0;

    while (true) {
      var q = _client
          .from('inventory_balance_items')
          .select()
          .eq('warehouse_id', warehouseId);

      if (storeId != null)  q = q.eq('store_id', storeId);
      if (status  != null)  q = q.eq('status', status.code);
      if (fromDate != null) q = q.gte('created_at', _dayStart(fromDate));
      if (toDate   != null) q = q.lt ('created_at', _dayAfter(toDate));

      // id tie-breaker — same created_at (ek batch ke items) pages mein
      // duplicate/miss na hon
      final rows = await q
          .order('created_at', ascending: false)
          .order('id', ascending: true)
          .range(offset, offset + pageSize - 1);
      final page = (rows as List)
          .map((e) => BalanceItemModel.fromMap(e as Map<String, dynamic>))
          .toList();
      out.addAll(page);

      if (page.length < pageSize) break;
      if (maxRows != null && out.length >= maxRows) break;
      offset += pageSize;
    }

    return maxRows != null && out.length > maxRows
        ? out.sublist(0, maxRows)
        : out;
  }

  // ─────── helpers ────────
  double _d(dynamic v) => v == null
      ? 0.0
      : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);

  DateTime _parseDate(dynamic v) =>
      v is DateTime ? v : (DateTime.tryParse(v.toString()) ?? DateTime.now());
}
