import '../../../features/warehouse_stock_inventory/data/mock/stock_inventory_mock_data.dart';
import '../../../features/warehouse_stock_inventory/data/model/warehouse_stock_inventory_model.dart';

class WarehouseStockInventoryService {
  Future<List<WarehouseStockInventory>> getStockInventories() async {
    await Future.delayed(const Duration(seconds: 1));
    return mockStockInventory;
  }
}