import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_transaction_datasource.dart';
import '../../data/model/account_transaction_model.dart';
import '../../data/model/accountant_user_model.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────
final accountantDataSourceProvider = Provider<AccountantDataSource>((ref) => AccountantDataSource(Supabase.instance.client),);

// ── Branch Today Total Amount (local DB) ────────────────────────────────────
final branchTotalAmountProvider = FutureProvider.family<double, String>((ref, branchId) async {
  return ref.read(accountantDataSourceProvider).getBranchTotalAmount(branchId);
});

// ── Active Accountants List ─────────────────────────────────────────────────
final accountantsProvider =
FutureProvider<List<AccountantUserModel>>((ref) async {
  return ref.read(accountantDataSourceProvider).getActiveAccountants();
});

// ── State ───────────────────────────────────────────────────────────────────
class AccountantTransactionState {
  final List<AccountantTransactionModel> transactions;
  final bool    isLoading;
  final String? error;

  const AccountantTransactionState({
    this.transactions = const [],
    this.isLoading    = false,
    this.error,
  });

  double get totalCashIn  =>
      transactions.where((t) => t.isCashIn).fold(0, (s, t) => s + t.amount);
  double get totalCashOut =>
      transactions.where((t) => !t.isCashIn).fold(0, (s, t) => s + t.amount);

  AccountantTransactionState copyWith({
    List<AccountantTransactionModel>? transactions,
    bool?   isLoading,
    String? error,
  }) =>
      AccountantTransactionState(
        transactions: transactions ?? this.transactions,
        isLoading:    isLoading    ?? this.isLoading,
        error:        error,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────
class AccountantTransactionNotifier extends StateNotifier<AccountantTransactionState> {
  final AccountantDataSource _ds;
  final String branchId;

  AccountantTransactionNotifier(this._ds, this.branchId)
      : super(const AccountantTransactionState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _ds.getTransactions(branchId);
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
      final tx = await _ds.cashOut(
        accountantId:    accountantId,
        accountantName:  accountantName,
        branchId:        branchId,
        amount:          amount,
        previousAmount:  branchCurrentBalance,
        remainingAmount: branchCurrentBalance - amount,
        description:     description,
      );
      state = state.copyWith(
        transactions: [tx, ...state.transactions],
        isLoading:    false,
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
      final tx = await _ds.cashIn(
        accountantId:    accountantId,
        accountantName:  accountantName,
        branchId:        branchId,
        amount:          amount,
        previousAmount:  branchCurrentBalance,
        remainingAmount: branchCurrentBalance + amount,
        description:     description,
      );
      state = state.copyWith(
        transactions: [tx, ...state.transactions],
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Cash in fail: $e');
      rethrow;
    }
  }

  Future<void> syncIfOnline() async {
    try {
      await _ds.syncPendingTransactions();
      await load(); // list refresh karo
    } catch (e) {
      print('Sync skip: $e');
    }
  }
}

// ── Provider Family ───────────────────────────────────────────────────────────
final accountantTransactionProvider = StateNotifierProvider.family
<AccountantTransactionNotifier,
    AccountantTransactionState,
    String>(
      (ref, branchId) => AccountantTransactionNotifier(
    ref.read(accountantDataSourceProvider),
    branchId,
  ),
);