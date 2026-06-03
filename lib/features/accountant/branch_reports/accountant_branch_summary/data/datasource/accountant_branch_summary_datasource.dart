import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accountant_branch_summary_model.dart';

// ═══════════════════════════════════════════════════════════
//  DATASOURCE
// ═══════════════════════════════════════════════════════════

class BranchSummaryDatasource {
  final _client = Supabase.instance.client;

  Future<BranchSummaryReport> getReport({
    required String   branchId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final raw = await _client
        .from('branch_summary')
        .select('''
          counter_date,
          total_cash_sale, total_card_sale, total_credit_sale,
          total_installment, total_cash_in, total_cash_out,
          total_expense, total_amount, total_sale
        ''')
        .eq('store_id', branchId)
        .gte('counter_date', fromDate.toIso8601String().substring(0, 10))
        .lte('counter_date', toDate.toIso8601String().substring(0, 10))
        .order('counter_date', ascending: false);

    final List<BranchSummaryDay> days = [];

    for (final r in (raw as List)) {
      final dateStr = r['counter_date'].toString().substring(0, 10);
      days.add(BranchSummaryDay(
        date:             DateTime.parse(dateStr),
        totalCashSale:    _dbl(r['total_cash_sale'])    ?? 0,
        totalCardSale:    _dbl(r['total_card_sale'])    ?? 0,
        totalCreditSale:  _dbl(r['total_credit_sale'])  ?? 0,
        totalInstallment: _dbl(r['total_installment'])  ?? 0,
        totalCashIn:      _dbl(r['total_cash_in'])      ?? 0,
        totalCashOut:     _dbl(r['total_cash_out'])     ?? 0,
        totalExpense:     _dbl(r['total_expense'])      ?? 0,
        totalAmount:      _dbl(r['total_amount'])       ?? 0,
        totalSale:        _dbl(r['total_sale'])         ?? 0,
      ));
    }

    days.sort((a, b) => b.date.compareTo(a.date));

    double totCash = 0, totCard = 0, totCredit = 0;
    double totInstall = 0, totIn = 0, totOut = 0;
    double totExpense = 0, totAmount = 0, totSale = 0;

    for (final d in days) {
      totCash    += d.totalCashSale;
      totCard    += d.totalCardSale;
      totCredit  += d.totalCreditSale;
      totInstall += d.totalInstallment;
      totIn      += d.totalCashIn;
      totOut     += d.totalCashOut;
      totExpense += d.totalExpense;
      totAmount  += d.totalAmount;
      totSale    += d.totalSale;
    }

    return BranchSummaryReport(
      totalCashSale:    totCash,
      totalCardSale:    totCard,
      totalCreditSale:  totCredit,
      totalInstallment: totInstall,
      totalCashIn:      totIn,
      totalCashOut:     totOut,
      totalExpense:     totExpense,
      totalAmount:      totAmount,
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