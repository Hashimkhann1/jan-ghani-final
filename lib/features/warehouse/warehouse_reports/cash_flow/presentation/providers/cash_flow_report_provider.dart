// =============================================================
// cash_flow_report_provider.dart
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/cash_flow/data/datasources/cash_flow_report_local_datasource.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class CashFlowReportState {
  final bool isLoading;
  final String? error;
  final CashFlowSummary?          summary;
  final List<MonthlyCashFlowData> monthlyData;
  final List<ExpenseCategoryData> expenseBreakdown;
  final List<TransactionTypeData> typeBreakdown;

  const CashFlowReportState({
    this.isLoading        = false,
    this.error,
    this.summary,
    this.monthlyData      = const [],
    this.expenseBreakdown = const [],
    this.typeBreakdown    = const [],
  });

  CashFlowReportState copyWith({
    bool?                      isLoading,
    String?                    error,
    CashFlowSummary?           summary,
    List<MonthlyCashFlowData>? monthlyData,
    List<ExpenseCategoryData>? expenseBreakdown,
    List<TransactionTypeData>? typeBreakdown,
    bool                       clearError = false,
  }) {
    return CashFlowReportState(
      isLoading:        isLoading        ?? this.isLoading,
      error:            clearError       ? null : error ?? this.error,
      summary:          summary          ?? this.summary,
      monthlyData:      monthlyData      ?? this.monthlyData,
      expenseBreakdown: expenseBreakdown ?? this.expenseBreakdown,
      typeBreakdown:    typeBreakdown    ?? this.typeBreakdown,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class CashFlowReportNotifier extends StateNotifier<CashFlowReportState> {
  final CashFlowReportLocalDatasource _ds;

  CashFlowReportNotifier(this._ds) : super(const CashFlowReportState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _ds.getSummary(),
        _ds.getMonthlyData(),
        _ds.getExpenseBreakdown(),
        _ds.getTypeBreakdown(),
      ]);

      state = state.copyWith(
        isLoading:        false,
        summary:          results[0] as CashFlowSummary,
        monthlyData:      results[1] as List<MonthlyCashFlowData>,
        expenseBreakdown: results[2] as List<ExpenseCategoryData>,
        typeBreakdown:    results[3] as List<TransactionTypeData>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
