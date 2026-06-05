// =============================================================
// supplier_report_provider.dart
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/supplier/data/datasources/supplier_report_local_datasource.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class SupplierReportState {
  final bool isLoading;
  final String? error;
  final SupplierSummaryData? summary;
  final List<SupplierBalanceItem> topByBalance;
  final List<SupplierPurchaseItem> topByPurchase;
  final List<MonthlyPurchaseData> monthlyTrend;
  final List<SupplierBalanceItem> allSuppliers;
  final List<RecentLedgerEntry> recentLedger;

  const SupplierReportState({
    this.isLoading = false,
    this.error,
    this.summary,
    this.topByBalance  = const [],
    this.topByPurchase = const [],
    this.monthlyTrend  = const [],
    this.allSuppliers  = const [],
    this.recentLedger  = const [],
  });

  SupplierReportState copyWith({
    bool?                      isLoading,
    String?                    error,
    SupplierSummaryData?       summary,
    List<SupplierBalanceItem>? topByBalance,
    List<SupplierPurchaseItem>? topByPurchase,
    List<MonthlyPurchaseData>? monthlyTrend,
    List<SupplierBalanceItem>? allSuppliers,
    List<RecentLedgerEntry>?   recentLedger,
    bool                       clearError = false,
  }) {
    return SupplierReportState(
      isLoading:    isLoading    ?? this.isLoading,
      error:        clearError   ? null : error ?? this.error,
      summary:      summary      ?? this.summary,
      topByBalance: topByBalance ?? this.topByBalance,
      topByPurchase: topByPurchase ?? this.topByPurchase,
      monthlyTrend: monthlyTrend ?? this.monthlyTrend,
      allSuppliers: allSuppliers ?? this.allSuppliers,
      recentLedger: recentLedger ?? this.recentLedger,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class SupplierReportNotifier extends StateNotifier<SupplierReportState> {
  final SupplierReportLocalDatasource _ds;

  SupplierReportNotifier(this._ds) : super(const SupplierReportState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _ds.getSummary(),
        _ds.getTopByBalance(),
        _ds.getTopByPurchase(),
        _ds.getMonthlyTrend(),
        _ds.getAllSuppliers(),
        _ds.getRecentLedger(),
      ]);

      state = state.copyWith(
        isLoading:    false,
        summary:      results[0] as SupplierSummaryData,
        topByBalance: results[1] as List<SupplierBalanceItem>,
        topByPurchase: results[2] as List<SupplierPurchaseItem>,
        monthlyTrend: results[3] as List<MonthlyPurchaseData>,
        allSuppliers: results[4] as List<SupplierBalanceItem>,
        recentLedger: results[5] as List<RecentLedgerEntry>,
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

final supplierReportProvider =
    StateNotifierProvider<SupplierReportNotifier, SupplierReportState>((ref) {
  return SupplierReportNotifier(SupplierReportLocalDatasource.instance);
});
