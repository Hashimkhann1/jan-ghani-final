// =============================================================
// expense_report_models.dart
//
// Expense Report ke saare DATA MODELS (plain Dart classes).
//
// Alag file mein isliye taake DONO datasources (local postgres + remote
// Supabase) aur interface (ExpenseReportSource) inhe share kar sakein bina
// circular import ke. Local datasource inhe re-export karta hai, isliye
// provider/screen ke imports waise hi chalte hain.
// =============================================================

// Top hero card ke liye — poore (date-filtered) period ka total.
//  • totalAmount → period ka total kharcha
//  • entryCount  → kitni expense entries
//  • activeDays  → kitne ALAG din kharcha hua (distinct expense_date)
//  • dailyAverage → total ÷ active days (rozana average / active day)
class ExpenseReportSummary {
  final double totalAmount;
  final int    entryCount;
  final int    activeDays;
  final double prevTotal;   // pichle (equal-length) period ka total
  final bool   hasPrev;     // comparison meaningful hai ya nahi (overall mein nahi)

  const ExpenseReportSummary({
    this.totalAmount = 0,
    this.entryCount  = 0,
    this.activeDays  = 0,
    this.prevTotal   = 0,
    this.hasPrev     = false,
  });

  double get dailyAverage => activeDays > 0 ? totalAmount / activeDays : 0;

  // % change vs pichla period — null agar compare possible nahi.
  // (+ = kharcha barha, − = kharcha kam)
  double? get changePct {
    if (!hasPrev || prevTotal == 0) return null;
    return (totalAmount - prevTotal) / prevTotal.abs() * 100;
  }
}

// Category-wise breakdown ki ek row — ek expense head (category).
//  • head    → expense_head (Salary, Rent, Bills, ...)
//  • amount  → us head ka total
//  • entries → us head ki entries ki count
// Share % screen mein grand total se compute hota hai (data se independent).
class ExpenseCategoryRow {
  final String head;
  final double amount;
  final int    entries;

  const ExpenseCategoryRow({
    required this.head,
    required this.amount,
    required this.entries,
  });
}
