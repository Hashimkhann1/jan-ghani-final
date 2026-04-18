import '../../domain/repository/i_customer_ledger_repository.dart';
import '../datasource/customer_ledger_remote_datasource.dart';
import '../model/customer_ledger_model.dart';

class CustomerLedgerRepositoryImpl implements ICustomerLedgerRepository {
  final CustomerLedgerRemoteDataSource _ds;
  CustomerLedgerRepositoryImpl() : _ds = CustomerLedgerRemoteDataSource();

  @override Future<List<CustomerLedgerModel>> getAll(String storeId)       => _ds.getAll(storeId);
  @override Future<List<CustomerLedgerModel>> getByCustomer(String id)     => _ds.getByCustomer(id);
  @override Future<CustomerLedgerModel>       add(CustomerLedgerModel l)   => _ds.add(l);
  @override Future<void>                      delete(String id)            => _ds.delete(id);
  @override
  Future<CustomerLedgerModel> update({
    required String id,
    required double payAmount,
    required double newAmount,
    String?         notes,
  }) => _ds.update(
    id:        id,
    payAmount: payAmount,
    newAmount: newAmount,
    notes:     notes,
  );
}