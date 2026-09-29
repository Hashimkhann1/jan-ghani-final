import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/accountant_dashboard_model.dart';

// ═══════════════════════════════════════════════════════════
//  DATASOURCE
// ═══════════════════════════════════════════════════════════

class AccountantBranchDashboardDatasource {
  final _client = Supabase.instance.client;
  final String  branchId;

  AccountantBranchDashboardDatasource({required this.branchId});

  // ── Date helpers — timezone-safe ─────────────────────────
  // fromDate/toDate ab exact time bhi carry karte hain (time filter),
  // is liye yahan din ki shuruaat/aakhir force nahi ki jaati.
  static String _fromStr(DateTime d) => d.toUtc().toIso8601String();

  static String _toStr(DateTime d) => d.toUtc().toIso8601String();

  // ── RPC call — ek range ka summary row ───────────────────
  Future<Map<String, dynamic>> _summary(DateTime from, DateTime to) async {
    // Sab kuch ek indexed RPC mein (get_branch_dashboard_summary) —
    // 2026_09_25_branch_dashboard_summary.sql.
    final res = await _client.rpc('get_branch_dashboard_summary', params: {
      'p_store_id': branchId,
      'p_from':     _fromStr(from),
      'p_to':       _toStr(to),
    });
    return (res is List ? (res.isEmpty ? <String, dynamic>{} : res.first) : res)
        as Map<String, dynamic>;
  }

  // ── Main method ──────────────────────────────────────────
  Future<AccountantBranchDashboardModel> getDashboard({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final row = await _summary(fromDate, toDate);
    double v(String k) => _dbl(row[k]) ?? 0;

    return AccountantBranchDashboardModel(
      totalSale:             v('total_sale'),
      cashSale:              v('cash_sale'),
      cardSale:              v('card_sale'),
      creditSale:            v('credit_sale'),
      installmentSale:       v('installment'),
      totalAmountReceived:   v('cash_sale') + v('card_sale') + v('installment'),
      totalSaleReturn:       v('total_return'),
      netSale:               v('total_sale') - v('total_return'),
      grossProfit:           v('gross_profit'),
      inventoryValue:        v('stock_purchase'),
      stockSaleValue:        v('stock_sale'),
      cashIn:                v('cash_in'),
      cashOut:               v('cash_out'),
      totalDamage:           v('damage'),
      outstandingReceivable: v('outstanding'),
    );
  }

  // ── Trend (charts) ───────────────────────────────────────
  // weekly  → [endDate] tak pichle 7 din, har din ek bucket
  // monthly → [endDate] tak pichle 6 mahine, har mahina ek bucket
  // Har bucket usi RPC ki parallel call hai (max 7 calls).
  Future<List<DashboardTrendPoint>> getTrend({
    required DateTime            endDate,
    required DashboardTrendPeriod period,
  }) async {
    final buckets = <(String, DateTime, DateTime)>[];
    if (period == DashboardTrendPeriod.weekly) {
      final dayFmt = DateFormat('EEE');
      for (var i = 6; i >= 0; i--) {
        final d = DateTime(endDate.year, endDate.month, endDate.day - i);
        buckets.add((
          dayFmt.format(d),
          d,
          DateTime(d.year, d.month, d.day, 23, 59, 59),
        ));
      }
    } else {
      final monFmt = DateFormat('MMM');
      for (var i = 5; i >= 0; i--) {
        final m = DateTime(endDate.year, endDate.month - i);
        buckets.add((
          monFmt.format(m),
          m,
          DateTime(m.year, m.month + 1, 1).subtract(const Duration(seconds: 1)),
        ));
      }
    }

    final rows = await Future.wait(
        buckets.map((b) => _summary(b.$2, b.$3)));

    return [
      for (var i = 0; i < buckets.length; i++)
        DashboardTrendPoint(
          label:      buckets[i].$1,
          sale:       _dbl(rows[i]['total_sale'])   ?? 0,
          saleReturn: _dbl(rows[i]['total_return']) ?? 0,
          profit:     _dbl(rows[i]['gross_profit']) ?? 0,
          creditSale: _dbl(rows[i]['credit_sale'])  ?? 0,
          installment: _dbl(rows[i]['installment']) ?? 0,
        ),
    ];
  }

  // ── Helper ───────────────────────────────────────────────
  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}

