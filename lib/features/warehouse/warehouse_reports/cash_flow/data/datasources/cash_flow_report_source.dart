// =============================================================
// cash_flow_report_source.dart
//
// Cash Flow Report ke data source ka common CONTRACT (interface).
// Do implementations isko follow karte hain:
//   • CashFlowReportLocalDatasource  → local postgres (Windows/Mac/mobile)
//   • CashFlowReportRemoteDatasource → Supabase raw fetch + Dart compute (web)
//
// (Cash flow data chhota hai — ~250 transactions — isliye web par koi
//  RPC/view NAHI; remote raw rows fetch karke aggregates app mein compute
//  karta hai. Logic local SQL ka exact mirror hai.)
//
// Provider platform ke hisaab se sahi impl pick karta hai — notifier/screen
// ko farq nahi padta.
// =============================================================

import 'cash_flow_report_models.dart';

abstract interface class CashFlowReportSource {
  // Summary cards: LIVE cash-in-hand + (date-filtered) period in/out +
  // pichle period ka net (vs-last % ke liye).
  Future<CashFlowSummary> getSummary({
    DateTime? from,
    DateTime? to,
    DateTime? prevFrom,
    DateTime? prevTo,
  });

  // Monthly trend — HAMESHA last 6 months (date filter se independent).
  // Har mahine ka cash in/out + month-end balance.
  Future<List<MonthlyCashFlowData>> getMonthlyData();

  // Expense breakdown donut — top expense heads (date-filtered).
  Future<List<ExpenseCategoryData>> getExpenseBreakdown({DateTime? from, DateTime? to});

  // Transaction type breakdown — har entry_type ka total (date-filtered).
  Future<List<TransactionTypeData>> getTypeBreakdown({DateTime? from, DateTime? to});

  // Recent transactions drill-down list (date + optional type filter, limit).
  Future<List<CashTransactionEntry>> getRecentTransactions({
    DateTime? from,
    DateTime? to,
    String? type,
    int limit,
  });
}
