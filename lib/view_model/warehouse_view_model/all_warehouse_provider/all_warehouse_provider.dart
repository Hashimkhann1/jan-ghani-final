import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/model/warehouse_model/warehouse_model.dart';
import 'package:jan_ghani_final/res/dummy/dummy_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WAREHOUSE STATE
// ─────────────────────────────────────────────────────────────────────────────

class WarehouseState {
  final List<WarehouseModel> warehouses;
  final bool isLoading;

  const WarehouseState({
    this.warehouses = const [],
    this.isLoading = false,
  });

  WarehouseState copyWith({
    List<WarehouseModel>? warehouses,
    bool? isLoading,
  }) {
    return WarehouseState(
      warehouses: warehouses ?? this.warehouses,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // ── Computed stats ──────────────────────────────────────────────────────
  int get warehouseCount => warehouses.length;
  int get uniqueProducts =>
      warehouses.fold(0, (s, w) => s + w.productCount);
  int get totalUnits => warehouses.fold(0, (s, w) => s + w.unitCount);
  int get lowStockTotal =>
      warehouses.fold(0, (s, w) => s + w.lowStockCount);
}

// ─────────────────────────────────────────────────────────────────────────────
// WAREHOUSE NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class AllWarehouseNotifier extends StateNotifier<WarehouseState> {
  AllWarehouseNotifier()
      : super(WarehouseState(warehouses: DummyData.dummyWarehouses));

  void addWarehouse(WarehouseModel warehouse) {
    state = state.copyWith(
      warehouses: [...state.warehouses, warehouse],
    );
  }

  void removeWarehouse(int id) {
    state = state.copyWith(
      warehouses:
      state.warehouses.where((w) => w.id != id).toList(),
    );
  }

  void updateWarehouse(WarehouseModel updated) {
    state = state.copyWith(
      warehouses: state.warehouses.map((w) {
        return w.id == updated.id ? updated : w;
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final allWarehouseProvider =
StateNotifierProvider<AllWarehouseNotifier, WarehouseState>(
      (ref) => AllWarehouseNotifier(),
);