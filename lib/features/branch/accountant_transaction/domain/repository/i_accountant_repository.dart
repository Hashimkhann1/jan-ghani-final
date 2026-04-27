import '../entity/accountant_transaction_entity.dart';
import '../entity/accountant_user_entity.dart';

abstract class IAccountantRepository {
  Future<double> getBranchTotalAmount(String branchId);

  Future<List<AccountantUserEntity>> getActiveAccountants();

  Future<List<AccountantTransactionEntity>> getTransactions(String branchId);

  Future<AccountantTransactionEntity> cashOut({
    required String accountantId,
    required String accountantName,
    required String branchId,
    required double amount,
    required double previousAmount,
    required double remainingAmount,
    String? description,
  });

  Future<AccountantTransactionEntity> cashIn({
    required String accountantId,
    required String accountantName,
    required String branchId,
    required double amount,
    required double previousAmount,
    required double remainingAmount,
    String? description,
  });

  Future<void> syncPendingTransactions();
}