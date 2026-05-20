import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/branch_cash_counter_model.dart';

// ═══════════════════════════════════════════════════════════
//  DATASOURCE
// ═══════════════════════════════════════════════════════════

class BranchCashCounterDatasource {
  final _client = Supabase.instance.client;

  Future<BranchCashCounterSummary> getReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final raw = await _client
        .from('branch_cash_counter')
        .select('''
          counter_date,
          cash_sale, card_sale, credit_sale,
          installment, cash_in, cash_out,
          total_sale, total_amount
        ''')
        .isFilter('deleted_at', null)
        .gte('counter_date',
        fromDate.toIso8601String().substring(0, 10))
        .lte('counter_date',
        toDate.toIso8601String().substring(0, 10))
        .order('counter_date', ascending: false);

    // Multiple counters on same date → sum them
    final Map<String, BranchCashCounterDay> map = {};

    for (final r in (raw as List)) {
      final dateStr = r['counter_date'].toString().substring(0, 10);
      final date    = DateTime.parse(dateStr);
      final prev    = map[dateStr];

      map[dateStr] = BranchCashCounterDay(
        date:        date,
        cashSale:    (prev?.cashSale    ?? 0) + (_dbl(r['cash_sale'])    ?? 0),
        cardSale:    (prev?.cardSale    ?? 0) + (_dbl(r['card_sale'])    ?? 0),
        creditSale:  (prev?.creditSale  ?? 0) + (_dbl(r['credit_sale'])  ?? 0),
        installment: (prev?.installment ?? 0) + (_dbl(r['installment'])  ?? 0),
        cashIn:      (prev?.cashIn      ?? 0) + (_dbl(r['cash_in'])      ?? 0),
        cashOut:     (prev?.cashOut     ?? 0) + (_dbl(r['cash_out'])     ?? 0),
        totalSale:   (prev?.totalSale   ?? 0) + (_dbl(r['total_sale'])   ?? 0),
        totalAmount: (prev?.totalAmount ?? 0) + (_dbl(r['total_amount']) ?? 0),
      );
    }

    final days = map.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double totCash = 0, totCard = 0, totCredit = 0;
    double totInstall = 0, totIn = 0, totOut = 0, totSale = 0;

    for (final d in days) {
      totCash    += d.cashSale;
      totCard    += d.cardSale;
      totCredit  += d.creditSale;
      totInstall += d.installment;
      totIn      += d.cashIn;
      totOut     += d.cashOut;
      totSale    += d.totalSale;
    }

    return BranchCashCounterSummary(
      totalCashSale:    totCash,
      totalCardSale:    totCard,
      totalCreditSale:  totCredit,
      totalInstallment: totInstall,
      totalCashIn:      totIn,
      totalCashOut:     totOut,
      totalSale:        totSale,
      days:             days,
    );
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}