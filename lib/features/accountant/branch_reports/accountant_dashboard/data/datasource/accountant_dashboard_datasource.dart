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

  // ── Main method ──────────────────────────────────────────
  Future<AccountantBranchDashboardModel> getDashboard({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    // Sab kuch ek indexed RPC mein (get_branch_dashboard_summary) —
    // 2026_09_25_branch_dashboard_summary.sql.
    final res = await _client.rpc('get_branch_dashboard_summary', params: {
      'p_store_id': branchId,
      'p_from':     _fromStr(fromDate),
      'p_to':       _toStr(toDate),
    });
    final row = (res is List ? (res.isEmpty ? <String, dynamic>{} : res.first) : res)
        as Map<String, dynamic>;
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

  // ── Helper ───────────────────────────────────────────────
  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}

