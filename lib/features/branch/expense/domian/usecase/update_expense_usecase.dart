import '../../data/model/expense_model.dart';
import '../repository/i_expense_repository.dart';
class UpdateExpenseUseCase {
  final IExpenseRepository _repo;
  UpdateExpenseUseCase(this._repo);
  Future<ExpenseModel> call(ExpenseModel e) => _repo.update(e);
}