import '../../domain/repositories/accountant_inventory_repository.dart';
import '../datasource/accountant_inventory_remote_datasource.dart';
import '../model/accountant_inventory_model.dart';

class AccountantInventoryRepositoryImpl
    implements AccountantInventoryRepository {
  final AccountantInventoryRemoteDatasource datasource;
  const AccountantInventoryRepositoryImpl(this.datasource);

  @override
  Future<List<AccountantInventoryModel>> getInventory(String warehouseId) =>
      datasource.getInventory(warehouseId);
}
