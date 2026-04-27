import '../../domain/entity/accountant_transaction_entity.dart';
import '../../domain/entity/accountant_user_entity.dart';
import '../../domain/repository/i_accountant_repository.dart';
import '../datasource/accountant_transaction_datasource.dart';

class AccountantRepositoryImpl implements IAccountantRepository {
  final AccountantDataSource _ds;

  const AccountantRepositoryImpl(this._ds);

  @override
  Future<double> getBranchTotalAmount(String branchId) =>
      _ds.getBranchTotalAmount(branchId);

  @override
  Future<List<AccountantUserEntity>> getActiveAccountants() async {
    final models = await _ds.getActiveAccountants();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AccountantTransactionEntity>> getTransactions(
      String branchId) async {
    final models = await _ds.getTransactions(branchId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<AccountantTransactionEntity> cashOut({
    required String accountantId,
    required String accountantName,
    required String branchId,
    required double amount,
    required double previousAmount,
    required double remainingAmount,
    String? description,
  }) async {
    final model = await _ds.cashOut(
      accountantId:    accountantId,
      accountantName:  accountantName,
      branchId:        branchId,
      amount:          amount,
      previousAmount:  previousAmount,
      remainingAmount: remainingAmount,
      description:     description,
    );
    return model.toEntity();
  }

  @override
  Future<AccountantTransactionEntity> cashIn({
    required String accountantId,
    required String accountantName,
    required String branchId,
    required double amount,
    required double previousAmount,
    required double remainingAmount,
    String? description,
  }) async {
    final model = await _ds.cashIn(
      accountantId:    accountantId,
      accountantName:  accountantName,
      branchId:        branchId,
      amount:          amount,
      previousAmount:  previousAmount,
      remainingAmount: remainingAmount,
      description:     description,
    );
    return model.toEntity();
  }

  @override
  Future<void> syncPendingTransactions() => _ds.syncPendingTransactions();
}