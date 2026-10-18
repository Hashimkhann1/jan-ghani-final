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
  // Saare buckets ek RPC call mein.
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

    // Ek hi RPC saare buckets ke liye (get_branch_dashboard_trend) —
    // 2026_10_18_branch_dashboard_trend.sql.
    final res = await _client.rpc('get_branch_dashboard_trend', params: {
      'p_store_id': branchId,
      'p_starts':   [for (final b in buckets) _fromStr(b.$2)],
      'p_ends':     [for (final b in buckets) _toStr(b.$3)],
    });
    final byIdx = <int, Map<String, dynamic>>{
      for (final r in (res as List))
        (r['idx'] as num).toInt(): Map<String, dynamic>.from(r as Map),
    };

    return [
      for (var i = 0; i < buckets.length; i++)
        DashboardTrendPoint(
          label:      buckets[i].$1,
          sale:       _dbl(byIdx[i + 1]?['total_sale'])   ?? 0,
          saleReturn: _dbl(byIdx[i + 1]?['total_return']) ?? 0,
          profit:     _dbl(byIdx[i + 1]?['gross_profit']) ?? 0,
          creditSale: _dbl(byIdx[i + 1]?['credit_sale'])  ?? 0,
          installment: _dbl(byIdx[i + 1]?['installment']) ?? 0,
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

