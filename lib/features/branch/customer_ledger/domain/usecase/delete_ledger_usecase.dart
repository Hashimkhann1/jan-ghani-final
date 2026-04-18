import '../repository/i_customer_ledger_repository.dart';
class DeleteLedgerUseCase {
  final ICustomerLedgerRepository _repo;
  DeleteLedgerUseCase(this._repo);
  Future<void> call(String id) => _repo.delete(id);
}