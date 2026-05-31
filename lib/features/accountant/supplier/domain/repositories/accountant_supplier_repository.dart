import '../../data/model/accountant_supplier_model.dart';
import '../../data/model/accountant_supplier_detail_models.dart';

abstract class AccountantSupplierRepository {
  Future<List<AccountantSupplierModel>> getAllSuppliers(String warehouseId);
  Future<List<AccSupplierLedgerEntry>> getLedger(String supplierId);
  Future<List<AccSupplierOrder>> getOrders(String supplierId);
  Future<List<AccSupplierOrderItem>> getOrderItems(String poId);
}
