// =============================================================
// cash_flow_report_provider.dart
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/cash_flow/data/datasources/cash_flow_report_local_datasource.dart';

// ─────────────────────────────────────────────────────────────
// FILTER MODE
// ─────────────────────────────────────────────────────────────

enum DateFilterMode { overall, currentMonth, custom }

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class CashFlowReportState {
  final bool isLoading;
  final String? error;
  final DateFilterMode            filterMode;
  final DateTime?                 dateFrom;
  final DateTime?                 dateTo;
  final CashFlowSummary?          summary;
  final List<MonthlyCashFlowData> monthlyData;
  final List<ExpenseCategoryData> expenseBreakdown;
  final List<TransactionTypeData> typeBreakdown;
  final List<CashTransactionEntry> transactions;

  const CashFlowReportState({
    this.isLoading        = false,
    this.error,
    this.filterMode       = DateFilterMode.currentMonth,
    this.dateFrom,
    this.dateTo,
    this.summary,
    this.monthlyData      = const [],
    this.expenseBreakdown = const [],
    this.typeBreakdown    = const [],
    this.transactions     = const [],
  });

  CashFlowReportState copyWith({
    bool?                       isLoading,
    String?                     error,
    DateFilterMode?             filterMode,
    DateTime?                   dateFrom,
    DateTime?                   dateTo,
    CashFlowSummary?            summary,
    List<MonthlyCashFlowData>?  monthlyData,
    List<ExpenseCategoryData>?  expenseBreakdown,
    List<TransactionTypeData>?  typeBreakdown,
    List<CashTransactionEntry>? transactions,
    bool                        clearError     = false,
    bool                        clearDateRange = false,
  }) {
    return CashFlowReportState(
      isLoading:        isLoading        ?? this.isLoading,
      error:            clearError       ? null : error ?? this.error,
      filterMode:       filterMode       ?? this.filterMode,
      dateFrom:         clearDateRange   ? null : dateFrom ?? this.dateFrom,
      dateTo:           clearDateRange   ? null : dateTo   ?? this.dateTo,
      summary:          summary          ?? this.summary,
      monthlyData:      monthlyData      ?? this.monthlyData,
      expenseBreakdown: expenseBreakdown ?? this.expenseBreakdown,
      typeBreakdown:    typeBreakdown    ?? this.typeBreakdown,
      transactions:     transactions     ?? this.transactions,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class CashFlowReportNotifier extends StateNotifier<CashFlowReportState> {
  final CashFlowReportLocalDatasource _ds;

  CashFlowReportNotifier(this._ds) : super(const CashFlowReportState()) {
    // Default: current month
    final now = DateTime.now();
    state = state.copyWith(
      filterMode: DateFilterMode.currentMonth,
      dateFrom:   DateTime(now.year, now.month, 1),
      dateTo:     DateTime(now.year, now.month + 1, 0),
    );
    load();
  }

  Future<void> load() async {
    final overall = state.filterMode == DateFilterMode.overall;
    final from = overall ? null : state.dateFrom;
    final to   = overall ? null : state.dateTo;

    // Previous equal-length period (for % change KPI)
    DateTime? prevFrom, prevTo;
    if (!overall && from != null && to != null) {
      final lenDays = to.difference(from).inDays + 1;
      prevTo   = from.subtract(const Duration(days: 1));
      prevFrom = prevTo.subtract(Duration(days: lenDays - 1));
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _ds.getSummary(from: from, to: to, prevFrom: prevFrom, prevTo: prevTo),
        _ds.getMonthlyData(),
        _ds.getExpenseBreakdown(from: from, to: to),
        _ds.getTypeBreakdown(from: from, to: to),
        _ds.getRecentTransactions(from: from, to: to),
      ]);

      state = state.copyWith(
        isLoading:        false,
        summary:          results[0] as CashFlowSummary,
        monthlyData:      results[1] as List<MonthlyCashFlowData>,
        expenseBreakdown: results[2] as List<ExpenseCategoryData>,
        typeBreakdown:    results[3] as List<TransactionTypeData>,
        transactions:     results[4] as List<CashTransactionEntry>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setOverall() {
    state = state.copyWith(
      filterMode:     DateFilterMode.overall,
      clearDateRange: true,
    );
    load();
  }

  void setCurrentMonth() {
    final now = DateTime.now();
    state = state.copyWith(
      filterMode: DateFilterMode.currentMonth,
      dateFrom:   DateTime(now.year, now.month, 1),
      dateTo:     DateTime(now.year, now.month + 1, 0),
    );
    load();
  }

  void setCustomRange(DateTime from, DateTime to) {
    state = state.copyWith(
      filterMode: DateFilterMode.custom,
      dateFrom:   from,
      dateTo:     to,
    );
    load();
  }

  Future<void> refresh() => load();
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final cashFlowReportProvider =
    StateNotifierProvider<CashFlowReportNotifier, CashFlowReportState>((ref) {
  return CashFlowReportNotifier(CashFlowReportLocalDatasource.instance);
});
