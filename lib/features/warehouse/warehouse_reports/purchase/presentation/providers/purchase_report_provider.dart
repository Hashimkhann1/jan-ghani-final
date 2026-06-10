// =============================================================
// purchase_report_provider.dart
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/purchase/data/datasources/purchase_report_local_datasource.dart';

// ─────────────────────────────────────────────────────────────
// FILTER MODE
// ─────────────────────────────────────────────────────────────

enum DateFilterMode { overall, currentMonth, custom }

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class PurchaseReportState {
  final bool isLoading;
  final String? error;
  final DateFilterMode               filterMode;
  final DateTime?                    dateFrom;
  final DateTime?                    dateTo;
  final PurchaseSummaryData?         summary;
  final List<PoStatusCount>          statusDistribution;
  final List<SupplierPoValue>        topSuppliers;
  final List<MonthlyPoData>          monthlyTrend;
  final List<SupplierCompletionData> supplierCompletion;
  final List<RecentPoEntry>          recentPos;
  final List<RecentPoEntry>          pendingPos;

  const PurchaseReportState({
    this.isLoading          = false,
    this.error,
    this.filterMode         = DateFilterMode.currentMonth,
    this.dateFrom,
    this.dateTo,
    this.summary,
    this.statusDistribution = const [],
    this.topSuppliers       = const [],
    this.monthlyTrend       = const [],
    this.supplierCompletion = const [],
    this.recentPos          = const [],
    this.pendingPos         = const [],
  });

  PurchaseReportState copyWith({
    bool?                        isLoading,
    String?                      error,
    DateFilterMode?              filterMode,
    DateTime?                    dateFrom,
    DateTime?                    dateTo,
    PurchaseSummaryData?         summary,
    List<PoStatusCount>?         statusDistribution,
    List<SupplierPoValue>?       topSuppliers,
    List<MonthlyPoData>?         monthlyTrend,
    List<SupplierCompletionData>? supplierCompletion,
    List<RecentPoEntry>?         recentPos,
    List<RecentPoEntry>?         pendingPos,
    bool                         clearError     = false,
    bool                         clearDateRange = false,
  }) {
    return PurchaseReportState(
      isLoading:          isLoading          ?? this.isLoading,
      error:              clearError         ? null : error ?? this.error,
      filterMode:         filterMode         ?? this.filterMode,
      dateFrom:           clearDateRange     ? null : dateFrom ?? this.dateFrom,
      dateTo:             clearDateRange     ? null : dateTo   ?? this.dateTo,
      summary:            summary            ?? this.summary,
      statusDistribution: statusDistribution ?? this.statusDistribution,
      topSuppliers:       topSuppliers       ?? this.topSuppliers,
      monthlyTrend:       monthlyTrend       ?? this.monthlyTrend,
      supplierCompletion: supplierCompletion ?? this.supplierCompletion,
      recentPos:          recentPos          ?? this.recentPos,
      pendingPos:         pendingPos         ?? this.pendingPos,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class PurchaseReportNotifier extends StateNotifier<PurchaseReportState> {
  final PurchaseReportLocalDatasource _ds;

  PurchaseReportNotifier(this._ds) : super(const PurchaseReportState()) {
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
    final from = state.filterMode == DateFilterMode.overall ? null : state.dateFrom;
    final to   = state.filterMode == DateFilterMode.overall ? null : state.dateTo;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _ds.getSummary(from: from, to: to),
        _ds.getStatusDistribution(from: from, to: to),
        _ds.getTopSuppliersByValue(from: from, to: to),
        _ds.getMonthlyTrend(from: from, to: to),
        _ds.getSupplierCompletion(from: from, to: to),
        _ds.getRecentPos(from: from, to: to),
        _ds.getPendingPos(from: from, to: to),
      ]);

      state = state.copyWith(
        isLoading:          false,
        summary:            results[0] as PurchaseSummaryData,
        statusDistribution: results[1] as List<PoStatusCount>,
        topSuppliers:       results[2] as List<SupplierPoValue>,
        monthlyTrend:       results[3] as List<MonthlyPoData>,
        supplierCompletion: results[4] as List<SupplierCompletionData>,
        recentPos:          results[5] as List<RecentPoEntry>,
        pendingPos:         results[6] as List<RecentPoEntry>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setOverall() {
    state = state.copyWith(
      filterMode:    DateFilterMode.overall,
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

final purchaseReportProvider =
    StateNotifierProvider<PurchaseReportNotifier, PurchaseReportState>((ref) {
  return PurchaseReportNotifier(PurchaseReportLocalDatasource.instance);
});
