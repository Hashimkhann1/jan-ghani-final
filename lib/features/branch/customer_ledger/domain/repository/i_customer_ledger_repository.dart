import '../../data/datasource/customer_ledger_remote_datasource.dart';
import '../../data/model/customer_ledger_model.dart';

abstract class ICustomerLedgerRepository {
  Future<List<CustomerLedgerModel>> getAll(
    String storeId, {
    DateTime? from,
    DateTime? to,
  });

  /// Server-side paged fetch (ek counter, date + search filter DB par).
  Future<LedgerPage> getPaged(
    String storeId, {
    required String counterId,
    DateTime? from,
    DateTime? to,
    String    search,
    required int limit,
    required int offset,
  });
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