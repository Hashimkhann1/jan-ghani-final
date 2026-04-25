import 'package:flutter_riverpod/legacy.dart';
import '../../domain/warehouse_dashboard_models.dart';
import '../../data/warehouse_dashboard_remote_datasource.dart';
import '../../data/warehouse_dashboard_dummy_data.dart';

class WarehouseDashboardState {
  final DashboardStats?               stats;
  final List<RecentPurchaseOrder>     recentPOs;
  final List<PendingTransfer>         pendingTransfers;
  final List<LowStockItem>            lowStockItems;
  final List<SupplierDue>             supplierDues;
  final List<StockMovementEntry>      stockMovements;
  final List<PurchaseTrendPoint>      purchaseTrend;
  final List<SupplierOutstandingBar>  supplierOutstandingBars;
  final bool                          isLoading;
  final bool                          isChartLoading;
  final String?                       errorMessage;

  // ── Filter state ──────────────────────────────────────────
  final PurchaseDateFilter activeFilter;
  final DateTime?          customFrom;
  final DateTime?          customTo;

  const WarehouseDashboardState({
    this.stats,
    this.recentPOs              = const [],
    this.pendingTransfers       = const [],
    this.lowStockItems          = const [],
    this.supplierDues           = const [],
    this.stockMovements         = const [],
    this.purchaseTrend          = const [],
    this.supplierOutstandingBars = const [],
    this.isLoading              = false,
    this.isChartLoading         = false,
    this.errorMessage,
    this.activeFilter           = PurchaseDateFilter.today,
    this.customFrom,
    this.customTo,
  });

  WarehouseDashboardState copyWith({
    DashboardStats?               stats,
    List<RecentPurchaseOrder>?    recentPOs,
    List<PendingTransfer>?        pendingTransfers,
    List<LowStockItem>?           lowStockItems,
    List<SupplierDue>?            supplierDues,
    List<StockMovementEntry>?     stockMovements,
    List<PurchaseTrendPoint>?     purchaseTrend,
    List<SupplierOutstandingBar>? supplierOutstandingBars,
    bool?                         isLoading,
    bool?                         isChartLoading,
    String?                       errorMessage,
    PurchaseDateFilter?           activeFilter,
    DateTime?                     customFrom,
    DateTime?                     customTo,
  }) {
    return WarehouseDashboardState(
      stats:                   stats                   ?? this.stats,
      recentPOs:               recentPOs               ?? this.recentPOs,
      pendingTransfers:        pendingTransfers         ?? this.pendingTransfers,
      lowStockItems:           lowStockItems            ?? this.lowStockItems,
      supplierDues:            supplierDues             ?? this.supplierDues,
      stockMovements:          stockMovements           ?? this.stockMovements,
      purchaseTrend:           purchaseTrend            ?? this.purchaseTrend,
      supplierOutstandingBars: supplierOutstandingBars  ?? this.supplierOutstandingBars,
      isLoading:               isLoading               ?? this.isLoading,
      isChartLoading:          isChartLoading           ?? this.isChartLoading,
      errorMessage:            errorMessage            ?? this.errorMessage,
      activeFilter:            activeFilter            ?? this.activeFilter,
      customFrom:              customFrom              ?? this.customFrom,
      customTo:                customTo                ?? this.customTo,
    );
  }
}

class WarehouseDashboardNotifier
    extends StateNotifier<WarehouseDashboardState> {

  final WarehouseDashboardRemoteDataSource _ds;

  WarehouseDashboardNotifier()
      : _ds = WarehouseDashboardRemoteDataSource(),
        super(const WarehouseDashboardState());

  // ── Initial load ──────────────────────────────────────────
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _ds.getStats(filter: state.activeFilter),
        _ds.getRecentPOs(),
        _ds.getLowStockItems(),
        _ds.getSupplierDues(),
        _ds.getPurchaseTrend(filter: state.activeFilter),
        _ds.getSupplierOutstandingBars(),
      ]);

      state = state.copyWith(
        stats:                   results[0] as DashboardStats,
        recentPOs:               results[1] as List<RecentPurchaseOrder>,
        lowStockItems:           results[2] as List<LowStockItem>,
        supplierDues:            results[3] as List<SupplierDue>,
        purchaseTrend:           results[4] as List<PurchaseTrendPoint>,
        supplierOutstandingBars: results[5] as List<SupplierOutstandingBar>,
        pendingTransfers:        dummyPendingTransfers,
        stockMovements:          dummyStockMovements,
        isLoading:               false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Dashboard load karne mein masla: $e',
      );
    }
  }

  // ── Filter change ─────────────────────────────────────────
  Future<void> applyFilter(PurchaseDateFilter filter) async {
    state = state.copyWith(
      activeFilter: filter,
      customFrom: filter != PurchaseDateFilter.custom ? null : state.customFrom,
      customTo:   filter != PurchaseDateFilter.custom ? null : state.customTo,
    );
    await _reloadStatsAndCharts();
  }

  // ── Custom date range ─────────────────────────────────────
  Future<void> applyCustomRange(DateTime from, DateTime to) async {
    state = state.copyWith(
      activeFilter: PurchaseDateFilter.custom,
      customFrom:   from,
      customTo:     to,
    );
    await _reloadStatsAndCharts();
  }

  // ── Stats + Charts reload — filter change pe ─────────────
  Future<void> _reloadStatsAndCharts() async {
    state = state.copyWith(isChartLoading: true);
    try {
      final results = await Future.wait([
        _ds.getStats(
          filter:   state.activeFilter,
          dateFrom: state.customFrom,
          dateTo:   state.customTo,
        ),
        _ds.getPurchaseTrend(
          filter:   state.activeFilter,
          dateFrom: state.customFrom,
          dateTo:   state.customTo,
        ),
      ]);

      state = state.copyWith(
        stats:          results[0] as DashboardStats,
        purchaseTrend:  results[1] as List<PurchaseTrendPoint>,
        isChartLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isChartLoading: false,
        errorMessage:   'Filter apply karne mein masla: $e',
      );
    }
  }

  Future<void> refresh() => loadDashboard();
}

final warehouseDashboardProvider =
StateNotifierProvider<WarehouseDashboardNotifier, WarehouseDashboardState>(
      (ref) => WarehouseDashboardNotifier(),
);