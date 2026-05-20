
// ═══════════════════════════════════════════════════════════
//  MODEL
// ═══════════════════════════════════════════════════════════

class BranchCashCounterDay {
  final DateTime date;
  final double   cashSale;
  final double   cardSale;
  final double   creditSale;
  final double   installment;
  final double   cashIn;
  final double   cashOut;
  final double   totalSale;
  final double   totalAmount;

  const BranchCashCounterDay({
    required this.date,
    required this.cashSale,
    required this.cardSale,
    required this.creditSale,
    required this.installment,
    required this.cashIn,
    required this.cashOut,
    required this.totalSale,
    required this.totalAmount,
  });

  double get netCash => cashIn - cashOut;
}

class BranchCashCounterSummary {
  final double                   totalCashSale;
  final double                   totalCardSale;
  final double                   totalCreditSale;
  final double                   totalInstallment;
  final double                   totalCashIn;
  final double                   totalCashOut;
  final double                   totalSale;
  final List<BranchCashCounterDay> days;

  const BranchCashCounterSummary({
    required this.totalCashSale,
    required this.totalCardSale,
    required this.totalCreditSale,
    required this.totalInstallment,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.totalSale,
    required this.days,
  });

  double get netCash => totalCashIn - totalCashOut;
}