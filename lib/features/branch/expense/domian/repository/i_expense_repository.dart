import '../../data/model/expense_model.dart';

abstract class IExpenseRepository {
  Future<List<ExpenseModel>> getAll(String storeId);
  Future<ExpenseModel>       add(ExpenseModel expense);
  Future<ExpenseModel>       update(ExpenseModel expense);
  Future<void>               delete(String id);
}