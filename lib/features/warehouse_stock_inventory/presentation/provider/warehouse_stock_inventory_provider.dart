import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/service/stock_inventory/stock_inventory_service.dart';
import '../../data/model/warehouse_stock_inventory_model.dart';


final stockInventoryServiceProvider = Provider<WarehouseStockInventoryService>((ref) {
  return WarehouseStockInventoryService();
});

final stockInventoryProvider = FutureProvider<List<WarehouseStockInventory>>((ref) async {
  final service = ref.watch(stockInventoryServiceProvider);
  return service.getStockInventories();
});