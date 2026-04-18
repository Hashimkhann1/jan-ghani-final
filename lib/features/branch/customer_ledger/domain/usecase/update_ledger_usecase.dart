import '../repository/i_customer_ledger_repository.dart';
import '../../data/model/customer_ledger_model.dart';

class UpdateLedgerUseCase {
  final ICustomerLedgerRepository _repo;
  UpdateLedgerUseCase(this._repo);

  Future<CustomerLedgerModel> call({
    required String id,
    required double payAmount,
    required double newAmount,
    String?         notes,
  }) => _repo.update(
    id:        id,
    payAmount: payAmount,
    newAmount: newAmount,
    notes:     notes,
  );
}