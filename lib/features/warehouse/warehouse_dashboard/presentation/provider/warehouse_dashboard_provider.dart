import 'package:flutter_riverpod/legacy.dart';
import '../../domain/warehouse_dashboard_models.dart';
import '../../data/warehouse_dashboard_remote_datasource.dart';
import '../../data/warehouse_dashboard_dummy_data.dart';

class WarehouseDashboardState {
  final DashboardStats?           stats;
  final List<RecentPurchaseOrder> recentPOs;
  final List<PendingTransfer>     pendingTransfers;
  final List<LowStockItem>        lowStockItems;
  final List<SupplierDue>         supplierDues;
  final List<StockMovementEntry>  stockMovements;
  final bool                      isLoading;
  final String?                   errorMessage;

  // ── Filter state ─────────────────────────────────────────
  final PurchaseDateFilter activeFilter;
  final DateTime?          customFrom;
  final DateTime?          customTo;

  const WarehouseDashboardState({
    this.stats,
    this.recentPOs        = const [],
    this.pendingTransfers = const [],
    this.lowStockItems    = const [],
    this.supplierDues     = const [],
    this.stockMovements   = const [],
    this.isLoading        = false,
    this.errorMessage,
    this.activeFilter     = PurchaseDateFilter.today,
    this.customFrom,
    this.customTo,
  });

  WarehouseDashboardState copyWith({
    DashboardStats?            stats,
    List<RecentPurchaseOrder>? recentPOs,
    List<PendingTransfer>?     pendingTransfers,
    List<LowStockItem>?        lowStockItems,
    List<SupplierDue>?         supplierDues,
    List<StockMovementEntry>?  stockMovements,
    bool?                      isLoading,
    String?                    errorMessage,
    PurchaseDateFilter?        activeFilter,
    DateTime?                  customFrom,
    DateTime?                  customTo,
  }) {
    return WarehouseDashboardState(
      stats:            stats            ?? this.stats,
      recentPOs:        recentPOs        ?? this.recentPOs,
      pendingTransfers: pendingTransfers ?? this.pendingTransfers,
      lowStockItems:    lowStockItems    ?? this.lowStockItems,
      supplierDues:     supplierDues     ?? this.supplierDues,
      stockMovements:   stockMovements   ?? this.stockMovements,
      isLoading:        isLoading        ?? this.isLoading,
      errorMessage:     errorMessage     ?? this.errorMessage,
      activeFilter:     activeFilter     ?? this.activeFilter,
      customFrom:       customFrom       ?? this.customFrom,
      customTo:         customTo         ?? this.customTo,
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
      ]);

      state = state.copyWith(
        stats:            results[0] as DashboardStats,
        recentPOs:        results[1] as List<RecentPurchaseOrder>,
        lowStockItems:    results[2] as List<LowStockItem>,
        supplierDues:     results[3] as List<SupplierDue>,
        pendingTransfers: dummyPendingTransfers,
        stockMovements:   dummyStockMovements,
        isLoading:        false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Dashboard load karne mein masla: $e',
      );
    }
  }

  // ── Filter change — Today, This Week, etc ─────────────────
  Future<void> applyFilter(PurchaseDateFilter filter) async {
    state = state.copyWith(
      activeFilter: filter,
      // Custom dates reset karo jab dusra filter lagao
      customFrom: filter != PurchaseDateFilter.custom ? null : state.customFrom,
      customTo:   filter != PurchaseDateFilter.custom ? null : state.customTo,
    );
    await _reloadStats();
  }

  // ── Custom date range ─────────────────────────────────────
  Future<void> applyCustomRange(DateTime from, DateTime to) async {
    state = state.copyWith(
      activeFilter: PurchaseDateFilter.custom,
      customFrom:   from,
      customTo:     to,
    );
    await _reloadStats();
  }

  // ── Sirf stats reload karo — baaki data same rahega ───────
  Future<void> _reloadStats() async {
    state = state.copyWith(isLoading: true);
    try {
      final stats = await _ds.getStats(
        filter:   state.activeFilter,
        dateFrom: state.customFrom,
        dateTo:   state.customTo,
      );
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Filter apply karne mein masla: $e',
      );
    }
  }

  Future<void> refresh() => loadDashboard();
}

final warehouseDashboardProvider =
StateNotifierProvider<WarehouseDashboardNotifier, WarehouseDashboardState>(
      (ref) => WarehouseDashboardNotifier(),
);