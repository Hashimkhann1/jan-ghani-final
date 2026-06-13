// =============================================================
// supplier_report_remote_datasource.dart
//
// MAQSAD:
//   WEBSITE (kIsWeb) par Supplier Report ka data Supabase se laana.
//   (Windows/Mac/mobile local postgres use karte hain.)
//
// SOCH (kyun no RPC / no view):
//   Supplier data chhota hai (45+, future ~600). Isliye yahan koi RPC
//   function ya view NAHI banayi — bas RAW rows (suppliers + received
//   purchase_orders + supplier_ledger) Supabase se fetch karke saare
//   aggregates APP mein (Dart) compute kar lete hain. Logic local SQL ka
//   exact mirror hai, to web aur desktop ke numbers same aate hain.
//
//   Saare PO-based fetch + supplier fetch PARALLEL hote hain (Future.wait
//   provider mein), isliye chhote data par bohot fast — alag-alag query
//   ho ke bhi latency ek hi query jitni rehti hai.
//
//   Tables (sab READ-ONLY .select()):
//     suppliers          → counts / outstanding / names
//     purchase_orders    → received POs (date-filtered) — totals/trend/agg
//     supplier_ledger    → recent ledger entries
// =============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supplier_report_models.dart';
import 'supplier_report_source.dart';

class SupplierReportRemoteDatasource implements SupplierReportSource {
  final SupabaseClient _client;
  final String _wid; // selected warehouse id (web par config nahi)

  SupplierReportRemoteDatasource(this._client, this._wid);

  // PostgREST ek request mein max ~1000 rows deta hai → pages mein laate hain.
  static const int _pageSize = 1000;

  // ── 1. Summary ─────────────────────────────────────────────
  // Top summary cards. IMPORTANT: supplier counts aur outstanding balance
  // LIVE/current state hote hain — inhe date se filter NAHI karte. Sirf
  // `total purchased` (received POs ka sum) date range follow karta hai.
  @override
  Future<SupplierSummaryData> getSummary({DateTime? from, DateTime? to}) async {
    final suppliers = await _fetchSuppliers();        // saare non-deleted suppliers
    final pos       = await _fetchReceivedPos(from, to); // date-filtered received POs

    int totalActive = 0, clearCount = 0, hasBalanceCount = 0;
    double totalOutstanding = 0;
    for (final s in suppliers) {
      final isActive = s['is_active'] == true;
      final bal = _dbl(s['outstanding_balance']);

      // Outstanding total mein inactive suppliers bhi shaamil hain (local SQL
      // bhi sirf deleted_at filter karta hai, is_active nahi) — exact mirror.
      if (bal > 0) totalOutstanding += bal;

      // Counts sirf ACTIVE suppliers ke (clear = bina baqaya, hasBalance = baqaya).
      if (isActive) {
        totalActive++;
        if (bal > 0) {
          hasBalanceCount++;
        } else if (bal == 0) {
          clearCount++;
        }
      }
    }

    // Total purchased = is period ke saare received POs ka total_amount.
    final totalPurchased =
        pos.fold<double>(0, (a, p) => a + _dbl(p['total_amount']));

    return SupplierSummaryData(
      totalActive:      totalActive,
      totalOutstanding: totalOutstanding,
      clearCount:       clearCount,
      hasBalanceCount:  hasBalanceCount,
      totalPurchased:   totalPurchased,
    );
  }

  // ── 2. Top by outstanding balance — pie ────────────────────
  // Active suppliers jin pe baqaya hai (balance > 0), sabse zyada baqaya
  // wale top `limit`. Yahan dates relevant nahi (live balance).
  @override
  Future<List<SupplierBalanceItem>> getTopByBalance({int limit = 6}) async {
    final suppliers = await _fetchSuppliers();
    final list = suppliers
        .where((s) => s['is_active'] == true && _dbl(s['outstanding_balance']) > 0)
        .toList()
      ..sort((a, b) => _dbl(b['outstanding_balance'])
          .compareTo(_dbl(a['outstanding_balance'])));

    return list.take(limit).map((s) => SupplierBalanceItem(
          name:               (s['name'] ?? '').toString(),
          outstandingBalance: _dbl(s['outstanding_balance']),
          totalOrders:        0,
          totalPurchased:     0,
        )).toList();
  }

  // ── 3. Top by purchase volume — bar ────────────────────────
  // Har active supplier ka (date-filtered) received PO total nikaal ke,
  // sabse zyada kharidari wale top `limit` suppliers. (0 wale skip.)
  @override
  Future<List<SupplierPurchaseItem>> getTopByPurchase({
    int limit = 6,
    DateTime? from,
    DateTime? to,
  }) async {
    final suppliers = await _fetchSuppliers();
    final pos       = await _fetchReceivedPos(from, to);

    // supplier_id → uske POs ka total (ek baar loop, fir lookup).
    final sumById = <String, double>{};
    for (final p in pos) {
      final sid = p['supplier_id']?.toString();
      if (sid == null) continue;
      sumById[sid] = (sumById[sid] ?? 0) + _dbl(p['total_amount']);
    }

    final items = suppliers
        .where((s) => s['is_active'] == true)
        .map((s) => SupplierPurchaseItem(
              name:           (s['name'] ?? '').toString(),
              totalPurchased: sumById[s['id'].toString()] ?? 0,
            ))
        .where((i) => i.totalPurchased > 0) // local HAVING SUM > 0
        .toList()
      ..sort((a, b) => b.totalPurchased.compareTo(a.totalPurchased));

    return items.take(limit).toList();
  }

  // ── 4. Monthly trend — line ────────────────────────────────
  @override
  Future<List<MonthlyPurchaseData>> getMonthlyTrend({DateTime? from, DateTime? to}) async {
    DateTime? f = from, t = to;
    if (from == null && to == null) {
      // default: last 6 months (current month - 5 se aaj tak)
      final now = DateTime.now();
      f = DateTime(now.year, now.month - 5, 1);
      t = null;
    }

    final pos = await _fetchReceivedPos(f, t);

    final byMonth = <DateTime, double>{};
    for (final p in pos) {
      final od = _parseDate(p['order_date']);
      final key = DateTime(od.year, od.month, 1);
      byMonth[key] = (byMonth[key] ?? 0) + _dbl(p['total_amount']);
    }

    final list = byMonth.entries
        .map((e) => MonthlyPurchaseData(month: e.key, total: e.value))
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));
    return list;
  }

  // ── 5. All suppliers table ─────────────────────────────────
  // Saare active suppliers + unka (date-filtered) PO aggregation
  // (orders count + purchased sum), balanceStatus filter (all/outstanding/
  // clear) ke saath, outstanding DESC sorted.
  @override
  Future<List<SupplierBalanceItem>> getAllSuppliers({
    DateTime? from,
    DateTime? to,
    BalanceStatusFilter balanceStatus = BalanceStatusFilter.all,
  }) async {
    final suppliers = await _fetchSuppliers();
    final pos       = await _fetchReceivedPos(from, to);

    // PO aggregation per supplier (orders count + purchased sum)
    final orders    = <String, int>{};
    final purchased = <String, double>{};
    for (final p in pos) {
      final sid = p['supplier_id']?.toString();
      if (sid == null) continue;
      orders[sid]    = (orders[sid] ?? 0) + 1;
      purchased[sid] = (purchased[sid] ?? 0) + _dbl(p['total_amount']);
    }

    // Active suppliers + balance-status filter
    Iterable<Map<String, dynamic>> list =
        suppliers.where((s) => s['is_active'] == true);
    switch (balanceStatus) {
      case BalanceStatusFilter.outstanding:
        list = list.where((s) => _dbl(s['outstanding_balance']) > 0);
        break;
      case BalanceStatusFilter.clear:
        list = list.where((s) => _dbl(s['outstanding_balance']) == 0);
        break;
      case BalanceStatusFilter.all:
        break;
    }

    final items = list.map((s) {
      final id = s['id'].toString();
      return SupplierBalanceItem(
        name:               (s['name'] ?? '').toString(),
        phone:              s['phone']?.toString(),
        code:               s['code']?.toString(),
        outstandingBalance: _dbl(s['outstanding_balance']),
        totalOrders:        orders[id] ?? 0,
        totalPurchased:     purchased[id] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));

    return items;
  }

  // ── 6. Recent ledger entries ───────────────────────────────
  // supplier_ledger + supplier name (inner join = sirf valid supplier wale).
  @override
  Future<List<RecentLedgerEntry>> getRecentLedger({
    int limit = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    var q = _client
        .from('supplier_ledger')
        .select('id, entry_type, amount, balance_after, notes, created_at, suppliers!inner(name)')
        .eq('warehouse_id', _wid);
    if (from != null) q = q.gte('created_at', _dayStart(from));
    if (to   != null) q = q.lt('created_at', _dayAfter(to));

    final res = await q.order('created_at', ascending: false).limit(limit);

    return (res as List).map((e) {
      final m = e as Map<String, dynamic>;
      final sup = m['suppliers'];
      final name = (sup is Map) ? (sup['name'] ?? '').toString() : '';
      return RecentLedgerEntry(
        id:           m['id'].toString(),
        supplierName: name,
        entryType:    (m['entry_type'] ?? '').toString(),
        amount:       _dbl(m['amount']),
        balanceAfter: _dbl(m['balance_after']),
        notes:        m['notes']?.toString(),
        createdAt:    _parseDate(m['created_at']),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────
  // RAW FETCH (paginated — 1000-cap safe)
  // ─────────────────────────────────────────────────────────

  // Saare non-deleted suppliers (active + inactive dono — counts/outstanding
  // ke liye). is_active flag rows mein hai, methods khud filter karte hain.
  Future<List<Map<String, dynamic>>> _fetchSuppliers() async {
    final out = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final res = await _client
          .from('suppliers')
          .select('id, name, phone, code, outstanding_balance, is_active')
          .eq('warehouse_id', _wid)
          .filter('deleted_at', 'is', null)
          .order('name', ascending: true)
          .range(offset, offset + _pageSize - 1);
      final rows = (res as List).cast<Map<String, dynamic>>();
      out.addAll(rows);
      if (rows.length < _pageSize) break;
      offset += _pageSize;
    }
    return out;
  }

  // Received POs (date-filtered). Local `order_date::date >= from AND <= to`
  // ko mirror karte hain: gte(from-midnight) + lt(to+1 din) → poora `to` din.
  Future<List<Map<String, dynamic>>> _fetchReceivedPos(DateTime? from, DateTime? to) async {
    final out = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      var q = _client
          .from('purchase_orders')
          .select('supplier_id, total_amount, order_date')
          .eq('warehouse_id', _wid)
          .filter('deleted_at', 'is', null)
          .eq('status', 'received');
      if (from != null) q = q.gte('order_date', _dayStart(from));
      if (to   != null) q = q.lt('order_date', _dayAfter(to));

      final res = await q
          .order('order_date', ascending: true)
          .range(offset, offset + _pageSize - 1);
      final rows = (res as List).cast<Map<String, dynamic>>();
      out.addAll(rows);
      if (rows.length < _pageSize) break;
      offset += _pageSize;
    }
    return out;
  }

  // ── Helpers ────────────────────────────────────────────────
  static String _dayStart(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

  static String _dayAfter(DateTime d) => DateTime(d.year, d.month, d.day)
      .add(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);

  static DateTime _parseDate(dynamic v) =>
      v is DateTime ? v : (DateTime.tryParse(v.toString()) ?? DateTime.now());

  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
