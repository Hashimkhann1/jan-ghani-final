// =============================================================
// purchase_report_remote_datasource.dart
//
// MAQSAD:
//   WEBSITE (kIsWeb) par Purchase Report ka data Supabase se laana.
//   (Windows/Mac/mobile local postgres use karte hain — wahan ye file
//    chalti hi nahi; provider platform ke hisaab se source pick karta hai.)
//
// KAISE CHALTA HAI:
//   Ye class `PurchaseReportSource` interface implement karti hai (wahi
//   interface local datasource bhi implement karta hai), isliye provider
//   bina kisi farq ke dono ko interchange kar sakta hai.
//
//   Har method Supabase ka ek READ-ONLY RPC function call karta hai
//   (_client.rpc('...')). RPC functions server par SQL chalate hain aur
//   final aggregate/list wapas dete hain — isliye saari rows client tak
//   nahi aati (fast + optimized). RPC ka SQL local datasource ke SQL ka
//   exact mirror hai, to web aur desktop ke numbers same aate hain.
//
//   Sab functions 3 common params lete hain:
//     p_wid  → warehouse id (selected warehouse, web par config nahi)
//     p_from → start date  (NULL = koi lower bound nahi)
//     p_to   → end date    (NULL = koi upper bound nahi)
//
// RPC FUNCTIONS (Supabase mein, sab read-only):
//   getSummary()              → purchase_report_summary
//   getStatusDistribution()   → purchase_report_status_dist
//   getTopSuppliersByValue()  → purchase_report_top_suppliers      (+ p_limit)
//   getMonthlyTrend()         → purchase_report_monthly_trend
//   getSupplierCompletion()   → purchase_report_supplier_completion (+ p_limit)
//   getRecentPos()            → purchase_report_recent_pos          (+ p_limit)
//   getPendingPos()           → purchase_report_pending_pos
// =============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'purchase_report_models.dart';
import 'purchase_report_source.dart';

class PurchaseReportRemoteDatasource implements PurchaseReportSource {
  final SupabaseClient _client;
  final String _wid; // selected warehouse id (web par config wali nahi)

  PurchaseReportRemoteDatasource(this._client, this._wid);

  // DateTime → 'YYYY-MM-DD' string (RPC ke `date` param ke liye).
  // null rehne par RPC us bound ko ignore kar deta hai (no filter).
  static String? _d(DateTime? v) => v?.toIso8601String().substring(0, 10);

  // ── 1. Summary ─────────────────────────────────────────────
  // RPC: purchase_report_summary → ek hi row (total POs, received value,
  // pending count, is mahine ki received value). Summary cards isi se bharte.
  @override
  Future<PurchaseSummaryData> getSummary({DateTime? from, DateTime? to}) async {
    final res = await _client.rpc('purchase_report_summary', params: {
      'p_wid': _wid,
      'p_from': _d(from),
      'p_to': _d(to),
    });
    final list = (res as List?) ?? const [];
    final m = list.isNotEmpty
        ? list.first as Map<String, dynamic>
        : const <String, dynamic>{};
    return PurchaseSummaryData(
      totalPos:           _int(m['total_pos']),
      totalReceivedValue: _dbl(m['total_received_value']),
      pendingCount:       _int(m['pending_count']),
      thisMonthValue:     _dbl(m['this_month_value']),
    );
  }

  // ── 2. Status distribution ─────────────────────────────────
  // RPC: purchase_report_status_dist → har PO status (received/ordered/
  // partial/draft/cancelled) ka count. Pie chart isi se banta hai.
  @override
  Future<List<PoStatusCount>> getStatusDistribution({DateTime? from, DateTime? to}) async {
    final res = await _client.rpc('purchase_report_status_dist', params: {
      'p_wid': _wid,
      'p_from': _d(from),
      'p_to': _d(to),
    });
    return ((res as List?) ?? const []).map((e) {
      final m = e as Map<String, dynamic>;
      return PoStatusCount(status: m['status'].toString(), count: _int(m['count']));
    }).toList();
  }

  // ── 3. Top suppliers by value ──────────────────────────────
  // RPC: purchase_report_top_suppliers → sabse zyada PO value wale top
  // `limit` suppliers (bar chart). p_limit se kitne suppliers control hota.
  @override
  Future<List<SupplierPoValue>> getTopSuppliersByValue({
    int limit = 6,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _client.rpc('purchase_report_top_suppliers', params: {
      'p_wid': _wid,
      'p_from': _d(from),
      'p_to': _d(to),
      'p_limit': limit,
    });
    return ((res as List?) ?? const []).map((e) {
      final m = e as Map<String, dynamic>;
      return SupplierPoValue(
        supplierName: (m['supplier_name'] ?? 'Unknown').toString(),
        totalValue:   _dbl(m['total_value']),
      );
    }).toList();
  }

  // ── 4. Monthly trend ───────────────────────────────────────
  // RPC: purchase_report_monthly_trend → month-wise received PO value
  // (line chart). Agar koi date filter na ho to RPC khud last 6 months deta.
  @override
  Future<List<MonthlyPoData>> getMonthlyTrend({DateTime? from, DateTime? to}) async {
    final res = await _client.rpc('purchase_report_monthly_trend', params: {
      'p_wid': _wid,
      'p_from': _d(from),
      'p_to': _d(to),
    });
    return ((res as List?) ?? const []).map((e) {
      final m = e as Map<String, dynamic>;
      return MonthlyPoData(
        month: DateTime.parse(m['month'].toString()),
        total: _dbl(m['total']),
      );
    }).toList();
  }

  // ── 5. Supplier completion ─────────────────────────────────
  // RPC: purchase_report_supplier_completion → har supplier ka ordered vs
  // received (quantity + POs) — delivery completion rate (progress bars).
  @override
  Future<List<SupplierCompletionData>> getSupplierCompletion({
    int limit = 8,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _client.rpc('purchase_report_supplier_completion', params: {
      'p_wid': _wid,
      'p_from': _d(from),
      'p_to': _d(to),
      'p_limit': limit,
    });
    return ((res as List?) ?? const []).map((e) {
      final m = e as Map<String, dynamic>;
      return SupplierCompletionData(
        supplierName:  (m['supplier_name'] ?? 'Unknown').toString(),
        totalOrdered:  _dbl(m['total_ordered']),
        totalReceived: _dbl(m['total_received']),
        totalPos:      _int(m['total_pos']),
        receivedPos:   _int(m['received_pos']),
      );
    }).toList();
  }

  // ── 6. Recent POs ──────────────────────────────────────────
  // RPC: purchase_report_recent_pos → latest `limit` POs (created_at DESC).
  @override
  Future<List<RecentPoEntry>> getRecentPos({
    int limit = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _client.rpc('purchase_report_recent_pos', params: {
      'p_wid': _wid,
      'p_from': _d(from),
      'p_to': _d(to),
      'p_limit': limit,
    });
    return ((res as List?) ?? const []).map((e) => _po(e as Map<String, dynamic>)).toList();
  }

  // ── 7. Pending POs ─────────────────────────────────────────
  // RPC: purchase_report_pending_pos → sirf pending POs (draft/ordered/
  // partial), order_date ASC. "Pending POs" table isi se bharti hai.
  @override
  Future<List<RecentPoEntry>> getPendingPos({DateTime? from, DateTime? to}) async {
    final res = await _client.rpc('purchase_report_pending_pos', params: {
      'p_wid': _wid,
      'p_from': _d(from),
      'p_to': _d(to),
    });
    return ((res as List?) ?? const []).map((e) => _po(e as Map<String, dynamic>)).toList();
  }

  // ── PO row mapper ──────────────────────────────────────────
  // recent_pos aur pending_pos dono ki row shape same hai — ek hi mapper.
  // (order_date/expected_date RPC se text aati hain → parse karte hain.)
  RecentPoEntry _po(Map<String, dynamic> m) => RecentPoEntry(
        poNumber:     (m['po_number'] ?? '').toString(),
        supplierName: m['supplier_name']?.toString(),
        status:       (m['status'] ?? '').toString(),
        orderDate:    DateTime.parse(m['order_date'].toString()),
        expectedDate: m['expected_date'] != null
            ? DateTime.tryParse(m['expected_date'].toString())
            : null,
        totalAmount:  _dbl(m['total_amount']),
        paidAmount:   _dbl(m['paid_amount']),
      );

  // ── Safe parsers ───────────────────────────────────────────
  // Supabase JSON se number kabhi int, kabhi double, kabhi string aa sakta
  // hai — ye helpers har case ko safely handle karte hain.
  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
