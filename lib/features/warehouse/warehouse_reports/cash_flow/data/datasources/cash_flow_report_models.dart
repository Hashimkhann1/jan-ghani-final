// =============================================================
// cash_flow_report_models.dart
//
// Cash Flow Report ke saare DATA MODELS (plain Dart classes).
//
// Alag file mein isliye taake DONO datasources (local postgres + remote
// Supabase) aur interface (CashFlowReportSource) inhe share kar sakein
// bina circular import ke. Local datasource inhe re-export karta hai,
// isliye provider/screen ke purane imports waise hi chalte rehte hain.
// =============================================================

// Top summary cards.
//  • cashInHand → LIVE current balance (warehouse_finance se, date se nahi badalta)
//  • period in/out → selected date range ka cash in / out
//  • prevPeriodNet → pichle equal-length period ka net (vs-last-period % ke liye)
class CashFlowSummary {
  final double cashInHand;      // LIVE current balance (date se nahi badalta)
  final double periodCashIn;    // selected period ka cash in
  final double periodCashOut;   // selected period ka cash out
  final double prevPeriodNet;   // pichle (equal-length) period ka net — % change ke liye
  final bool   hasPrev;         // prev comparison meaningful hai ya nahi

  const CashFlowSummary({
    required this.cashInHand,
    required this.periodCashIn,
    required this.periodCashOut,
    this.prevPeriodNet = 0,
    this.hasPrev       = false,
  });

  double get periodNet => periodCashIn - periodCashOut;

  // % change vs previous period — null agar compare possible nahi
  double? get changePct {
    if (!hasPrev || prevPeriodNet == 0) return null;
    return (periodNet - prevPeriodNet) / prevPeriodNet.abs() * 100;
  }
}

// Monthly trend (Triple LineChart + Grouped BarChart + Net Flow BarChart).
// Har mahine ka cash in/out aur us mahine ke AAKHRI transaction ka balance.
class MonthlyCashFlowData {
  final DateTime month;
  final double   cashIn;
  final double   cashOut;
  final double   endBalance; // last transaction ka cash_in_hand_after

  const MonthlyCashFlowData({
    required this.month,
    required this.cashIn,
    required this.cashOut,
    required this.endBalance,
  });

  double get netFlow => cashIn - cashOut;
}

// Expense breakdown donut — ek expense head (category) + uska total.
class ExpenseCategoryData {
  final String category;
  final double amount;

  const ExpenseCategoryData({required this.category, required this.amount});
}

// Transaction type breakdown progress bars — ek entry_type ka total (ABS).
class TransactionTypeData {
  final String type;
  final double amount;

  const TransactionTypeData({required this.type, required this.amount});

  String get label {
    switch (type) {
      case 'cash_in':          return 'Cash In';
      case 'purchase':         return 'Purchase';
      case 'supplier_payment': return 'Supplier Payment';
      case 'expense':          return 'Expense';
      default:                 return type;
    }
  }

  bool get isCashIn => type == 'cash_in';
}

// Ek single transaction — recent transactions drill-down list ke liye.
class CashTransactionEntry {
  final String    id;
  final String    entryType;
  final double    amount;          // ABS value
  final double    balanceAfter;
  final String?   notes;
  final String?   byName;
  final DateTime  createdAt;

  const CashTransactionEntry({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.balanceAfter,
    this.notes,
    this.byName,
    required this.createdAt,
  });

  bool get isCashIn => entryType == 'cash_in';

  String get typeLabel {
    switch (entryType) {
      case 'cash_in':          return 'Cash In';
      case 'purchase':         return 'Purchase';
      case 'supplier_payment': return 'Supplier Payment';
      case 'expense':          return 'Expense';
      default:                 return entryType;
    }
  }
}
