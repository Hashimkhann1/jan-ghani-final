import '../../domian/repository/i_expense_repository.dart';
import '../datasource/expense_remote_datasource.dart';
import '../model/expense_model.dart';

class ExpenseRepositoryImpl implements IExpenseRepository {
  final ExpenseRemoteDataSource _ds;
  ExpenseRepositoryImpl() : _ds = ExpenseRemoteDataSource();

  @override Future<List<ExpenseModel>> getAll(String storeId) => _ds.getAll(storeId);
  @override Future<ExpenseModel> add(ExpenseModel e) => _ds.add(e);
  @override Future<ExpenseModel> update(ExpenseModel e) => _ds.update(e);
  @override Future<void>  delete(String id) => _ds.delete(id);
}