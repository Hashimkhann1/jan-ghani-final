import '../../domain/repositories/accountant_supplier_repository.dart';
import '../datasource/accountant_supplier_remote_datasource.dart';
import '../model/accountant_supplier_model.dart';
import '../model/accountant_supplier_detail_models.dart';

class AccountantSupplierRepositoryImpl
    implements AccountantSupplierRepository {
  final AccountantSupplierRemoteDatasource datasource;
  const AccountantSupplierRepositoryImpl(this.datasource);

  @override
  Future<List<AccountantSupplierModel>> getAllSuppliers(String warehouseId) =>
      datasource.getAllSuppliers(warehouseId);

  @override
  Future<List<AccSupplierLedgerEntry>> getLedger(String supplierId) =>
      datasource.getLedger(supplierId);

  @override
  Future<List<AccSupplierOrder>> getOrders(String supplierId) =>
      datasource.getOrders(supplierId);

  @override
  Future<List<AccSupplierOrderItem>> getOrderItems(String poId) =>
      datasource.getOrderItems(poId);
}
