// =============================================================
// purchase_report_provider.dart
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/purchase/data/datasources/purchase_report_local_datasource.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class PurchaseReportState {
  final bool isLoading;
  final String? error;
  final PurchaseSummaryData?       summary;
  final List<PoStatusCount>        statusDistribution;
  final List<SupplierPoValue>      topSuppliers;
  final List<MonthlyPoData>        monthlyTrend;
  final List<SupplierCompletionData> supplierCompletion;
  final List<RecentPoEntry>        recentPos;
  final List<RecentPoEntry>        pendingPos;

  const PurchaseReportState({
    this.isLoading          = false,
    this.error,
    this.summary,
    this.statusDistribution = const [],
    this.topSuppliers       = const [],
    this.monthlyTrend       = const [],
    this.supplierCompletion = const [],
    this.recentPos          = const [],
    this.pendingPos         = const [],
  });

  PurchaseReportState copyWith({
    bool?                      isLoading,
    String?                    error,
    PurchaseSummaryData?       summary,
    List<PoStatusCount>?       statusDistribution,
    List<SupplierPoValue>?     topSuppliers,
    List<MonthlyPoData>?       monthlyTrend,
    List<SupplierCompletionData>? supplierCompletion,
    List<RecentPoEntry>?       recentPos,
    List<RecentPoEntry>?       pendingPos,
    bool                       clearError = false,
  }) {
    return PurchaseReportState(
      isLoading:          isLoading          ?? this.isLoading,
      error:              clearError         ? null : error ?? this.error,
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
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _ds.getSummary(),
        _ds.getStatusDistribution(),
        _ds.getTopSuppliersByValue(),
        _ds.getMonthlyTrend(),
        _ds.getSupplierCompletion(),
        _ds.getRecentPos(),
        _ds.getPendingPos(),
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

  Future<void> refresh() => load();
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final purchaseReportProvider =
    StateNotifierProvider<PurchaseReportNotifier, PurchaseReportState>((ref) {
  return PurchaseReportNotifier(PurchaseReportLocalDatasource.instance);
});
