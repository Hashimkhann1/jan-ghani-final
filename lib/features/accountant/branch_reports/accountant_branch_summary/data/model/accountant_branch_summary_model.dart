// ═══════════════════════════════════════════════════════════
//  MODEL
// ═══════════════════════════════════════════════════════════

class BranchSummaryDay {
  final DateTime date;
  final double   totalCashSale;
  final double   totalCardSale;
  final double   totalCreditSale;
  final double   totalInstallment;
  final double   totalCashIn;
  final double   totalCashOut;
  final double   totalExpense;
  final double   totalAmount;
  final double   totalSale;

  const BranchSummaryDay({
    required this.date,
    required this.totalCashSale,
    required this.totalCardSale,
    required this.totalCreditSale,
    required this.totalInstallment,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.totalExpense,
    required this.totalAmount,
    required this.totalSale,
  });
}

class BranchSummaryReport {
  final double                totalCashSale;
  final double                totalCardSale;
  final double                totalCreditSale;
  final double                totalInstallment;
  final double                totalCashIn;
  final double                totalCashOut;
  final double                totalExpense;
  final double                totalAmount;
  final double                totalSale;
  final List<BranchSummaryDay> days;

  const BranchSummaryReport({
    required this.totalCashSale,
    required this.totalCardSale,
    required this.totalCreditSale,
    required this.totalInstallment,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.totalExpense,
    required this.totalAmount,
    required this.totalSale,
    required this.days,
  });
}