import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/service/stock_inventory/stock_inventory_service.dart';
import '../../../warehouse_stock_inventory/data/model/warehouse_stock_inventory_model.dart';

// ── Branch uses the same service as Warehouse (read-only) ──
final branchStockServiceProvider = Provider<WarehouseStockInventoryService>((ref) {
  return WarehouseStockInventoryService();
});

final branchStockProvider = FutureProvider<List<WarehouseStockInventory>>((ref) async {
  final service = ref.watch(branchStockServiceProvider);
  return service.getStockInventories();
});

// ── Search filter provider ──
final branchSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Filtered list (derived) ──
final filteredBranchStockProvider = Provider<AsyncValue<List<WarehouseStockInventory>>>((ref) {
  final inventoryAsync = ref.watch(branchStockProvider);
  final query = ref.watch(branchSearchQueryProvider).toLowerCase().trim();

  return inventoryAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((item) {
      return item.productName.toLowerCase().contains(query) ||
          item.barcode.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.companyName.toLowerCase().contains(query) ||
          item.sku.toLowerCase().contains(query);
    }).toList();
  });
});