import '../../data/model/accountant_inventory_model.dart';

abstract class AccountantInventoryRepository {
  Future<List<AccountantInventoryModel>> getInventory(String warehouseId);
}
