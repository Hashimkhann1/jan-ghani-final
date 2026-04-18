import '../../data/model/customer_ledger_model.dart';

abstract class ICustomerLedgerRepository {
  Future<List<CustomerLedgerModel>> getAll(String storeId);
  Future<List<CustomerLedgerModel>> getByCustomer(String customerId);
  Future<CustomerLedgerModel>       add(CustomerLedgerModel ledger);
  Future<void>                      delete(String id);
  Future<CustomerLedgerModel>       update({
    required String id,
    required double payAmount,
    required double newAmount,
    String?         notes,
  });
}