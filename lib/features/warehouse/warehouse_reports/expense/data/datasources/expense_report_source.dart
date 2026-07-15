// =============================================================
// expense_report_source.dart
//
// Expense Report ke data source ka common CONTRACT (interface).
// Do implementations isko follow karte hain:
//   • ExpenseReportLocalDatasource  → local postgres (Windows/Mac/mobile)
//   • ExpenseReportRemoteDatasource → Supabase raw fetch + Dart compute (web/IPA)
//
// (Expense data chhota hai — isliye web par koi RPC/view NAHI; remote raw
//  rows fetch karke aggregates app mein compute karta hai. Logic local SQL
//  ka exact mirror hai — web/desktop ke numbers same aate hain.)
//
// Provider platform ke hisaab se sahi impl pick karta hai — notifier/screen
// ko farq nahi padta.
// =============================================================

import 'expense_report_models.dart';

abstract interface class ExpenseReportSource {
  // Top hero card: (date-filtered) total kharcha + entries + active days.
  // prevFrom/prevTo → pichle equal-length period ka total (vs-last % ke liye).
  Future<ExpenseReportSummary> getSummary({
    DateTime? from,
    DateTime? to,
    DateTime? prevFrom,
    DateTime? prevTo,
  });

  // Category-wise breakdown — har expense head ka total + entries (amount DESC).
  Future<List<ExpenseCategoryRow>> getCategoryBreakdown({
    DateTime? from,
    DateTime? to,
  });
}
