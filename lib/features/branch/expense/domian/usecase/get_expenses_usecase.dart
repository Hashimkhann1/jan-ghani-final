import '../../data/model/expense_model.dart';
import '../repository/i_expense_repository.dart';
class GetExpensesUseCase {
  final IExpenseRepository _repo;
  GetExpensesUseCase(this._repo);
  Future<List<ExpenseModel>> call(String storeId) => _repo.getAll(storeId);
}