// =============================================================
// warehouse_dashboard_provider.dart
// Warehouse Dashboard ka Riverpod State + Notifier + Provider
// =============================================================

import 'package:flutter_riverpod/legacy.dart';
import '../../domain/warehouse_dashboard_models.dart';
import '../../data/warehouse_dashboard_dummy_data.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

class WarehouseDashboardState {
  final DashboardStats?              stats;
  final List<RecentPurchaseOrder>    recentPOs;
  final List<PendingTransfer>        pendingTransfers;
  final List<LowStockItem>           lowStockItems;
  final List<SupplierDue>            supplierDues;
  final List<StockMovementEntry>     stockMovements;
  final bool                         isLoading;
  final String?                      errorMessage;

  const WarehouseDashboardState({
    this.stats,
    this.recentPOs         = const [],
    this.pendingTransfers  = const [],
    this.lowStockItems     = const [],
    this.supplierDues      = const [],
    this.stockMovements    = const [],
    this.isLoading         = false,
    this.errorMessage,
  });

  WarehouseDashboardState copyWith({
    DashboardStats?             stats,
    List<RecentPurchaseOrder>?  recentPOs,
    List<PendingTransfer>?      pendingTransfers,
    List<LowStockItem>?         lowStockItems,
    List<SupplierDue>?          supplierDues,
    List<StockMovementEntry>?   stockMovements,
    bool?                       isLoading,
    String?                     errorMessage,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class WarehouseDashboardNotifier
    extends StateNotifier<WarehouseDashboardState> {
  WarehouseDashboardNotifier() : super(const WarehouseDashboardState());

  /// Dashboard ka pura data ek baar load karo
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // TODO: Drift se real data:
      // final stats     = await dashboardRepo.getStats(tenantId);
      // final pos       = await poRepo.getRecent(tenantId, limit: 4);
      // final transfers = await transferRepo.getPending(tenantId);
      // final lowStock  = await inventoryRepo.getLowStock(tenantId);
      // final dues      = await supplierRepo.getDues(tenantId);
      // final movements = await movementRepo.getToday(tenantId);

      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        stats:            dummyDashboardStats,
        recentPOs:        dummyRecentPOs,
        pendingTransfers: dummyPendingTransfers,
        lowStockItems:    dummyLowStockItems,
        supplierDues:     dummySupplierDues,
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

  /// Pull-to-refresh
  Future<void> refresh() => loadDashboard();
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final warehouseDashboardProvider = StateNotifierProvider<
    WarehouseDashboardNotifier, WarehouseDashboardState>(
      (ref) => WarehouseDashboardNotifier(),
);