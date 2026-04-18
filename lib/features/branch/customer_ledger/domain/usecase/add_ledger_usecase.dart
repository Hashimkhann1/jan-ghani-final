// add_ledger_usecase.dart
import '../../data/model/customer_ledger_model.dart';
import '../repository/i_customer_ledger_repository.dart';
class AddLedgerUseCase {
  final ICustomerLedgerRepository _repo;
  AddLedgerUseCase(this._repo);
  Future<CustomerLedgerModel> call(CustomerLedgerModel l) => _repo.add(l);
}
