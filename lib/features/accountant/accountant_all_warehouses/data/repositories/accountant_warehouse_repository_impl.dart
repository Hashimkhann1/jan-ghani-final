import '../../domain/repositories/accountant_warehouse_repository.dart';
import '../datasource/accountant_warehouse_remote_datasource.dart';
import '../model/accountant_warehouse_model.dart';

class AccountantWarehouseRepositoryImpl
    implements AccountantWarehouseRepository {
  final AccountantWarehouseRemoteDatasource datasource;
  const AccountantWarehouseRepositoryImpl(this.datasource);

  @override
  Future<List<AccountantWarehouseModel>> getAllWarehouses() =>
      datasource.getAllWarehouses();
}
