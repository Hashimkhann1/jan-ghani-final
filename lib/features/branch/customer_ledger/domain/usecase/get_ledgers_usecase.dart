import '../../data/model/customer_ledger_model.dart';
import '../repository/i_customer_ledger_repository.dart';
class GetLedgersUseCase {
  final ICustomerLedgerRepository _repo;
  GetLedgersUseCase(this._repo);
  Future<List<CustomerLedgerModel>> call(String storeId) => _repo.getAll(storeId);
}