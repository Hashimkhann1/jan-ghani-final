// Updated on 2026-10-02 09:31 AM
// =============================================================
// warehouse_dashboard_provider.dart
// Dashboard v2 (Stitch design) — state + notifier.
//   • loadDashboard()  — pehli load (full-screen spinner)
//   • applyFilter / applyCustomRange — period badla → sab data
//     refresh, screen dikhti rehti hai (isRefreshing)
//   • dashboardNavRequestProvider — "Needs attention" tile / links
//     se sidebar ko screen badalne ka signal
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/warehouse_dashboard_models.dart';
import '../../data/warehouse_dashboard_remote_datasource.dart';

/// Sidebar item ka label (jaise 'Stock', 'Supplier'). Dashboard set karta
/// hai, SideBar sun kar us screen par jata hai aur wapas null kar deta hai.
final dashboardNavRequestProvider = StateProvider<String?>((ref) => null);

class WarehouseDashboardState {
  final DashboardSummary?           summary;
  final List<DashboardTrendPoint>   trend;
  final List<SupplierDue>           supplierDues;
  final List<DashboardLowStockRow>  lowStock;
  final List<DashboardMovement>     movements;
  final bool                        isLoading;     // pehli load
  final bool                        isRefreshing;  // filter / refresh
  final String?                     errorMessage;

  // ── Filter state ──────────────────────────────────────────
  final PurchaseDateFilter activeFilter;
  final DateTime?          customFrom;
  final DateTime?          customTo;

  const WarehouseDashboardState({
    this.summary,
    this.trend        = const [],
    this.supplierDues = const [],
    this.lowStock     = const [],
    this.movements    = const [],
    this.isLoading    = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.activeFilter = PurchaseDateFilter.today,
    this.customFrom,
    this.customTo,
  });

  DashboardPeriod get period =>
      DashboardPeriod.of(activeFilter, customFrom, customTo);

  WarehouseDashboardState copyWith({
    DashboardSummary?           summary,
    List<DashboardTrendPoint>?  trend,
    List<SupplierDue>?          supplierDues,
    List<DashboardLowStockRow>? lowStock,
    List<DashboardMovement>?    movements,
    bool?                       isLoading,
    bool?                       isRefreshing,
    String?                     errorMessage,
    PurchaseDateFilter?         activeFilter,
    DateTime?                   customFrom,
    DateTime?                   customTo,
    bool                        clearError  = false, // ?? se null set nahi hota
    bool                        clearCustom = false,
  }) {
    return WarehouseDashboardState(
      summary:      summary      ?? this.summary,
      trend:        trend        ?? this.trend,
      supplierDues: supplierDues ?? this.supplierDues,
      lowStock:     lowStock     ?? this.lowStock,
      movements:    movements    ?? this.movements,
      isLoading:    isLoading    ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeFilter: activeFilter ?? this.activeFilter,
      customFrom:   clearCustom ? null : (customFrom ?? this.customFrom),
      customTo:     clearCustom ? null : (customTo   ?? this.customTo),
    );
  }
}

class WarehouseDashboardNotifier
    extends StateNotifier<WarehouseDashboardState> {

  final WarehouseDashboardRemoteDataSource _ds;

  WarehouseDashboardNotifier()
      : _ds = WarehouseDashboardRemoteDataSource(),
        super(const WarehouseDashboardState());

  // ── Pehli load — full-screen spinner ──────────────────────
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetchAll();
    state = state.copyWith(isLoading: false);
  }

  // ── Refresh button / filter — screen dikhti rahe ──────────
  Future<void> refresh() async {
    if (state.summary == null) return loadDashboard();
    state = state.copyWith(isRefreshing: true, clearError: true);
    await _fetchAll();
    state = state.copyWith(isRefreshing: false);
  }

  Future<void> applyFilter(PurchaseDateFilter filter) async {
    state = state.copyWith(
      activeFilter: filter,
      clearCustom:  filter != PurchaseDateFilter.custom,
    );
    await refresh();
  }

  Future<void> applyCustomRange(DateTime from, DateTime to) async {
    state = state.copyWith(
      activeFilter: PurchaseDateFilter.custom,
      customFrom:   from,
      customTo:     to,
    );
    await refresh();
  }

  Future<void> _fetchAll() async {
    final period = state.period;
    try {
      final results = await Future.wait([
        _ds.getSummary(period),
        _ds.getTrend(period, state.activeFilter),
        _ds.getSupplierDues(),
        _ds.getLowStock(),
        _ds.getMovements(period),
      ]);
      state = state.copyWith(
        summary:      results[0] as DashboardSummary,
        trend:        results[1] as List<DashboardTrendPoint>,
        supplierDues: results[2] as List<SupplierDue>,
        lowStock:     results[3] as List<DashboardLowStockRow>,
        movements:    results[4] as List<DashboardMovement>,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Dashboard load nahi hua: $e');
    }
  }
}

final warehouseDashboardProvider =
StateNotifierProvider<WarehouseDashboardNotifier, WarehouseDashboardState>(
      (ref) => WarehouseDashboardNotifier(),
);
