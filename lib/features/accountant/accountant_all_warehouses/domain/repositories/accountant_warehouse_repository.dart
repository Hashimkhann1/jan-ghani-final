import '../../data/model/accountant_warehouse_model.dart';

abstract class AccountantWarehouseRepository {
  Future<List<AccountantWarehouseModel>> getAllWarehouses();
}
