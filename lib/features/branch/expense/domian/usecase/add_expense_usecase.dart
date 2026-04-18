import '../../data/model/expense_model.dart';
import '../repository/i_expense_repository.dart';
class AddExpenseUseCase {
  final IExpenseRepository _repo;
  AddExpenseUseCase(this._repo);
  Future<ExpenseModel> call(ExpenseModel e) => _repo.add(e);
}