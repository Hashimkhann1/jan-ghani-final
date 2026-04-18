import '../repository/i_expense_repository.dart';
class DeleteExpenseUseCase {
  final IExpenseRepository _repo;
  DeleteExpenseUseCase(this._repo);
  Future<void> call(String id) => _repo.delete(id);
}