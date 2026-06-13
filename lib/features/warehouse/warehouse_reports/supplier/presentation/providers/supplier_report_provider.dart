// =============================================================
// supplier_report_provider.dart
// =============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/supplier/data/datasources/supplier_report_local_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/supplier/data/datasources/supplier_report_remote_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/supplier/data/datasources/supplier_report_source.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/inventory/presentation/providers/inventory_report_provider.dart'
    show reportsWarehouseIdProvider;

// ─────────────────────────────────────────────────────────────
// FILTER MODE
// ─────────────────────────────────────────────────────────────

enum DateFilterMode { overall, currentMonth, custom }

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class SupplierReportState {
  final bool isLoading;
  final String? error;
  final DateFilterMode             filterMode;
  final DateTime?                  dateFrom;
  final DateTime?                  dateTo;
  final BalanceStatusFilter        balanceStatus;
  final SupplierSummaryData?       summary;
  final List<SupplierBalanceItem>  topByBalance;
  final List<SupplierPurchaseItem> topByPurchase;
  final List<MonthlyPurchaseData>  monthlyTrend;
  final List<SupplierBalanceItem>  allSuppliers;
  final List<RecentLedgerEntry>    recentLedger;

  const SupplierReportState({
    this.isLoading     = false,
    this.error,
    this.filterMode    = DateFilterMode.currentMonth,
    this.dateFrom,
    this.dateTo,
    this.balanceStatus = BalanceStatusFilter.all,
    this.summary,
    this.topByBalance  = const [],
    this.topByPurchase = const [],
    this.monthlyTrend  = const [],
    this.allSuppliers  = const [],
    this.recentLedger  = const [],
  });

  SupplierReportState copyWith({
    bool?                       isLoading,
    String?                     error,
    DateFilterMode?             filterMode,
    DateTime?                   dateFrom,
    DateTime?                   dateTo,
    BalanceStatusFilter?        balanceStatus,
    SupplierSummaryData?        summary,
    List<SupplierBalanceItem>?  topByBalance,
    List<SupplierPurchaseItem>? topByPurchase,
    List<MonthlyPurchaseData>?  monthlyTrend,
    List<SupplierBalanceItem>?  allSuppliers,
    List<RecentLedgerEntry>?    recentLedger,
    bool                        clearError     = false,
    bool                        clearDateRange = false,
  }) {
    return SupplierReportState(
      isLoading:     isLoading     ?? this.isLoading,
      error:         clearError    ? null : error ?? this.error,
      filterMode:    filterMode    ?? this.filterMode,
      dateFrom:      clearDateRange ? null : dateFrom ?? this.dateFrom,
      dateTo:        clearDateRange ? null : dateTo   ?? this.dateTo,
      balanceStatus: balanceStatus ?? this.balanceStatus,
      summary:       summary       ?? this.summary,
      topByBalance:  topByBalance  ?? this.topByBalance,
      topByPurchase: topByPurchase ?? this.topByPurchase,
      monthlyTrend:  monthlyTrend  ?? this.monthlyTrend,
      allSuppliers:  allSuppliers  ?? this.allSuppliers,
      recentLedger:  recentLedger  ?? this.recentLedger,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class SupplierReportNotifier extends StateNotifier<SupplierReportState> {
  final SupplierReportSource _ds;

  SupplierReportNotifier(this._ds) : super(const SupplierReportState()) {
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
        _ds.getTopByBalance(),
        _ds.getTopByPurchase(from: from, to: to),
        _ds.getMonthlyTrend(from: from, to: to),
        _ds.getAllSuppliers(from: from, to: to, balanceStatus: state.balanceStatus),
        _ds.getRecentLedger(from: from, to: to),
      ]);

      state = state.copyWith(
        isLoading:     false,
        summary:       results[0] as SupplierSummaryData,
        topByBalance:  results[1] as List<SupplierBalanceItem>,
        topByPurchase: results[2] as List<SupplierPurchaseItem>,
        monthlyTrend:  results[3] as List<MonthlyPurchaseData>,
        allSuppliers:  results[4] as List<SupplierBalanceItem>,
        recentLedger:  results[5] as List<RecentLedgerEntry>,
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

  void setBalanceStatus(BalanceStatusFilter status) {
    if (status == state.balanceStatus) return;
    state = state.copyWith(balanceStatus: status);
    load();
  }

  Future<void> refresh() => load();
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final supplierReportProvider = StateNotifierProvider.autoDispose<
    SupplierReportNotifier, SupplierReportState>((ref) {
  // Platform ke hisaab se data source:
  //  • website (kIsWeb)   → Supabase (raw fetch + compute), SELECTED warehouse
  //  • Windows/Mac/mobile → local postgres (config warehouse), unchanged
  // autoDispose + watch: selected warehouse badle to rebuild + reload.
  final SupplierReportSource source = kIsWeb
      ? SupplierReportRemoteDatasource(
          Supabase.instance.client,
          ref.watch(reportsWarehouseIdProvider) ?? AppConfig.warehouseId,
        )
      : SupplierReportLocalDatasource.instance;
  return SupplierReportNotifier(source);
});
