import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_transaction_datasource.dart';
import '../../data/repository/accountant_repository_impl.dart';
import '../../domain/entity/accountant_transaction_entity.dart';
import '../../domain/entity/accountant_user_entity.dart';
import '../../domain/repository/i_accountant_repository.dart';
import '../../domain/usecase/accountant_usecases.dart';

// ── DI ────────────────────────────────────────────────────────────────────────

final _dataSourceProvider = Provider<AccountantDataSource>((ref) => AccountantDataSource(Supabase.instance.client),
);

final accountantRepositoryProvider = Provider<IAccountantRepository>(
      (ref) => AccountantRepositoryImpl(ref.read(_dataSourceProvider)),
);

// ── Use case providers ────────────────────────────────────────────────────────

final _getBranchTotalUseCaseProvider =
Provider((ref) => GetBranchTotalAmountUseCase(
  ref.read(accountantRepositoryProvider),
));

final _getAccountantsUseCaseProvider =
Provider((ref) => GetActiveAccountantsUseCase(
  ref.read(accountantRepositoryProvider),
));

final _getTransactionsUseCaseProvider =
Provider((ref) => GetTransactionsUseCase(
  ref.read(accountantRepositoryProvider),
));

final _cashOutUseCaseProvider = Provider(
      (ref) => CashOutUseCase(ref.read(accountantRepositoryProvider)),
);

final _cashInUseCaseProvider = Provider(
      (ref) => CashInUseCase(ref.read(accountantRepositoryProvider)),
);

final _syncUseCaseProvider = Provider(
      (ref) => SyncPendingTransactionsUseCase(
      ref.read(accountantRepositoryProvider)),
);

// ── Simple FutureProviders ────────────────────────────────────────────────────

final branchTotalAmountProvider =
FutureProvider.family<double, String>((ref, branchId) async {
  return ref.read(_getBranchTotalUseCaseProvider).call(branchId);
});

final accountantsProvider =
FutureProvider<List<AccountantUserEntity>>((ref) async {
  return ref.read(_getAccountantsUseCaseProvider).call();
});

// ── State ─────────────────────────────────────────────────────────────────────

class AccountantTransactionState {
  final List<AccountantTransactionEntity> transactions;
  final bool isLoading;
  final String? error;

  const AccountantTransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  double get totalCashIn =>
      transactions.where((t) => t.isCashIn).fold(0, (s, t) => s + t.amount);
  double get totalCashOut =>
      transactions.where((t) => !t.isCashIn).fold(0, (s, t) => s + t.amount);

  AccountantTransactionState copyWith({
    List<AccountantTransactionEntity>? transactions,
    bool? isLoading,
    String? error,
  }) =>
      AccountantTransactionState(
        transactions: transactions ?? this.transactions,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AccountantTransactionNotifier extends StateNotifier<AccountantTransactionState> {
  final GetTransactionsUseCase _getTransactions;
  final CashOutUseCase _cashOut;
  final CashInUseCase _cashIn;
  final SyncPendingTransactionsUseCase _sync;
  final String branchId;

  AccountantTransactionNotifier({
    required this.branchId,
    required GetTransactionsUseCase getTransactions,
    required CashOutUseCase cashOut,
    required CashInUseCase cashIn,
    required SyncPendingTransactionsUseCase sync,
  })  : _getTransactions = getTransactions,
        _cashOut = cashOut,
        _cashIn = cashIn,
        _sync = sync,
        super(const AccountantTransactionState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _getTransactions(branchId);
      state = state.copyWith(transactions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Load error: $e');
    }
  }

  Future<void> doCashOut({
    required String accountantId,
    required String accountantName,
    required double branchCurrentBalance,
    required double amount,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tx = await _cashOut(CashParams(
        accountantId:    accountantId,
        accountantName:  accountantName,
        branchId:        branchId,
        amount:          amount,
        previousAmount:  branchCurrentBalance,
        remainingAmount: branchCurrentBalance - amount,
        description:     description,
      ));
      state = state.copyWith(
        transactions: [tx, ...state.transactions],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Cash out fail: $e');
      rethrow;
    }
  }

  Future<void> doCashIn({
    required String accountantId,
    required String accountantName,
    required double branchCurrentBalance,
    required double amount,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tx = await _cashIn(CashParams(
        accountantId:    accountantId,
        accountantName:  accountantName,
        branchId:        branchId,
        amount:          amount,
        previousAmount:  branchCurrentBalance,
        remainingAmount: branchCurrentBalance + amount,
        description:     description,
      ));
      state = state.copyWith(
        transactions: [tx, ...state.transactions],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Cash in fail: $e');
      rethrow;
    }
  }

  Future<void> syncIfOnline() async {
    try {
      await _sync();
      await load();
    } catch (e) {
      print('Sync skip: $e');
    }
  }
}

// ── Provider family ───────────────────────────────────────────────────────────

final accountantTransactionProvider = StateNotifierProvider.family<
    AccountantTransactionNotifier,
    AccountantTransactionState,
    String>(
      (ref, branchId) => AccountantTransactionNotifier(
    branchId:        branchId,
    getTransactions: ref.read(_getTransactionsUseCaseProvider),
    cashOut:         ref.read(_cashOutUseCaseProvider),
    cashIn:          ref.read(_cashInUseCaseProvider),
    sync:            ref.read(_syncUseCaseProvider),
  ),
);