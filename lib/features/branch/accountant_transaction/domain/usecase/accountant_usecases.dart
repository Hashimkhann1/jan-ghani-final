import '../entity/accountant_transaction_entity.dart';
import '../entity/accountant_user_entity.dart';
import '../repository/i_accountant_repository.dart';

// ── params ────────────────────────────────────────────────────────────────────

class CashParams {
  final String accountantId;
  final String accountantName;
  final String branchId;
  final double amount;
  final double previousAmount;
  final double remainingAmount;
  final String? description;

  const CashParams({
    required this.accountantId,
    required this.accountantName,
    required this.branchId,
    required this.amount,
    required this.previousAmount,
    required this.remainingAmount,
    this.description,
  });
}

// ── use cases ─────────────────────────────────────────────────────────────────

class GetBranchTotalAmountUseCase {
  final IAccountantRepository _repo;
  const GetBranchTotalAmountUseCase(this._repo);

  Future<double> call(String branchId) => _repo.getBranchTotalAmount(branchId);
}

class GetActiveAccountantsUseCase {
  final IAccountantRepository _repo;
  const GetActiveAccountantsUseCase(this._repo);

  Future<List<AccountantUserEntity>> call() => _repo.getActiveAccountants();
}

class GetTransactionsUseCase {
  final IAccountantRepository _repo;
  const GetTransactionsUseCase(this._repo);

  Future<List<AccountantTransactionEntity>> call(String branchId) =>
      _repo.getTransactions(branchId);
}

class CashOutUseCase {
  final IAccountantRepository _repo;
  const CashOutUseCase(this._repo);

  Future<AccountantTransactionEntity> call(CashParams p) => _repo.cashOut(
    accountantId: p.accountantId,
    accountantName: p.accountantName,
    branchId: p.branchId,
    amount: p.amount,
    previousAmount: p.previousAmount,
    remainingAmount: p.remainingAmount,
    description: p.description,
  );
}

class CashInUseCase {
  final IAccountantRepository _repo;
  const CashInUseCase(this._repo);

  Future<AccountantTransactionEntity> call(CashParams p) => _repo.cashIn(
    accountantId: p.accountantId,
    accountantName: p.accountantName,
    branchId: p.branchId,
    amount: p.amount,
    previousAmount: p.previousAmount,
    remainingAmount: p.remainingAmount,
    description: p.description,
  );
}

class SyncPendingTransactionsUseCase {
  final IAccountantRepository _repo;
  const SyncPendingTransactionsUseCase(this._repo);

  Future<void> call() => _repo.syncPendingTransactions();
}