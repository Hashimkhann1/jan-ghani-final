// =============================================================
// expense_report_provider.dart
//
// Platform-aware Expense Report provider:
//   • website / IPA (kIsWeb)  → Supabase (raw fetch + compute), SELECTED warehouse
//   • Windows / Mac / mobile  → local postgres (config warehouse)
// UI/screen same rehta hai — sirf data kahan se aata hai woh badalta hai.
// =============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/expense/data/datasources/expense_report_local_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/expense/data/datasources/expense_report_remote_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/expense/data/datasources/expense_report_source.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/inventory/presentation/providers/inventory_report_provider.dart'
    show reportsWarehouseIdProvider;

// ─────────────────────────────────────────────────────────────
// FILTER MODE
// ─────────────────────────────────────────────────────────────

enum ExpenseDateFilterMode { overall, currentMonth, custom }

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class ExpenseReportState {
  final bool                     isLoading;
  final String?                  error;
  final ExpenseDateFilterMode    filterMode;
  final DateTime?                dateFrom;
  final DateTime?                dateTo;
  final ExpenseReportSummary?    summary;
  final List<ExpenseCategoryRow> categories;

  const ExpenseReportState({
    this.isLoading  = false,
    this.error,
    this.filterMode = ExpenseDateFilterMode.currentMonth,
    this.dateFrom,
    this.dateTo,
    this.summary,
    this.categories = const [],
  });

  ExpenseReportState copyWith({
    bool?                     isLoading,
    String?                   error,
    ExpenseDateFilterMode?    filterMode,
    DateTime?                 dateFrom,
    DateTime?                 dateTo,
    ExpenseReportSummary?     summary,
    List<ExpenseCategoryRow>? categories,
    bool                      clearError     = false,
    bool                      clearDateRange = false,
  }) {
    return ExpenseReportState(
      isLoading:  isLoading  ?? this.isLoading,
      error:      clearError ? null : error ?? this.error,
      filterMode: filterMode ?? this.filterMode,
      dateFrom:   clearDateRange ? null : dateFrom ?? this.dateFrom,
      dateTo:     clearDateRange ? null : dateTo   ?? this.dateTo,
      summary:    summary    ?? this.summary,
      categories: categories ?? this.categories,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class ExpenseReportNotifier extends StateNotifier<ExpenseReportState> {
  final ExpenseReportSource _ds;

  ExpenseReportNotifier(this._ds) : super(const ExpenseReportState()) {
    // Default: current month (1 month)
    final now = DateTime.now();
    state = state.copyWith(
      filterMode: ExpenseDateFilterMode.currentMonth,
      dateFrom:   DateTime(now.year, now.month, 1),
      dateTo:     DateTime(now.year, now.month + 1, 0),
    );
    load();
  }

  Future<void> load() async {
    final overall = state.filterMode == ExpenseDateFilterMode.overall;
    final from = overall ? null : state.dateFrom;
    final to   = overall ? null : state.dateTo;

    // Pichla equal-length period (vs-last % ke liye)
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
        _ds.getCategoryBreakdown(from: from, to: to),
      ]);
      state = state.copyWith(
        isLoading:  false,
        summary:    results[0] as ExpenseReportSummary,
        categories: results[1] as List<ExpenseCategoryRow>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setOverall() {
    state = state.copyWith(
      filterMode:     ExpenseDateFilterMode.overall,
      clearDateRange: true,
    );
    load();
  }

  void setCurrentMonth() {
    final now = DateTime.now();
    state = state.copyWith(
      filterMode: ExpenseDateFilterMode.currentMonth,
      dateFrom:   DateTime(now.year, now.month, 1),
      dateTo:     DateTime(now.year, now.month + 1, 0),
    );
    load();
  }

  void setCustomRange(DateTime from, DateTime to) {
    state = state.copyWith(
      filterMode: ExpenseDateFilterMode.custom,
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

final expenseReportProvider = StateNotifierProvider.autoDispose<
    ExpenseReportNotifier, ExpenseReportState>((ref) {
  final ExpenseReportSource source = kIsWeb
      ? ExpenseReportRemoteDatasource(
          Supabase.instance.client,
          ref.watch(reportsWarehouseIdProvider) ?? AppConfig.warehouseId,
        )
      : ExpenseReportLocalDatasource.instance;
  return ExpenseReportNotifier(source);
});
