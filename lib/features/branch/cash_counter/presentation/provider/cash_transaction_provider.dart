import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
// import 'package:jan_ghani_final/config/store_config.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import 'cash_counter_provider.dart';
import '../../data/datasource/cash_transaction_remote_datasource.dart';
import '../../data/model/cash_transaction_model.dart';

class CashTransactionState {
  final List<CashTransactionModel> allTransactions;
  final double  todayTotal;
  final bool    isLoading;
  final bool    isSaving;
  final String? errorMessage;

  const CashTransactionState({
    this.allTransactions = const [],
    this.todayTotal      = 0.0,
    this.isLoading       = false,
    this.isSaving        = false,
    this.errorMessage,
  });

  double get totalCashIn  => allTransactions
      .where((t) => t.isCashIn)
      .fold(0, (s, t) => s + t.cashOutAmount);

  double get totalCashOut => allTransactions
      .where((t) => t.isCashOut)
      .fold(0, (s, t) => s + t.cashOutAmount);

  CashTransactionState copyWith({
    List<CashTransactionModel>? allTransactions,
    double?                     todayTotal,
    bool?                       isLoading,
    bool?                       isSaving,
    String?                     errorMessage,
  }) => CashTransactionState(
    allTransactions: allTransactions ?? this.allTransactions,
    todayTotal:      todayTotal      ?? this.todayTotal,
    isLoading:       isLoading       ?? this.isLoading,
    isSaving:        isSaving        ?? this.isSaving,
    errorMessage:    errorMessage,
  );
}

class CashTransactionNotifier extends StateNotifier<CashTransactionState> {
  final CashTransactionRemoteDataSource _ds;
  final Ref    _ref;

  CashTransactionNotifier(this._ref)
      : _ds = CashTransactionRemoteDataSource(),
        super(const CashTransactionState()) {
    load();
  }

  String? get _counterId => _ref.read(authProvider).counterId;

  // ── LOAD — counter specific ───────────────────────────────
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final String _storeId = _ref.watch(authProvider).storeId;
      final transactions = await _ds.getAll(_storeId);
      final todayTotal   = await _ds.getTodayTotal(_storeId, _counterId);

      state = state.copyWith(
        allTransactions: transactions,
        todayTotal:      todayTotal,
        isLoading:       false,
      );
    } catch (e, stack) {
      print('❌ Load error: $e');
      print('❌ Stack: $stack');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  // ── LOAD ALL — store level (owner/manager ke liye) ────────
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final String _storeId = _ref.watch(authProvider).storeId;
      final transactions = await _ds.getAll(_storeId);
      state = state.copyWith(
        allTransactions: transactions,
        isLoading:       false,
      );
    } catch (e, stack) {
      print('❌ LoadAll error: $e');
      print('❌ Stack: $stack');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  // ── ADD TRANSACTION ───────────────────────────────────────
  Future<void> addTransaction({
    required double amount,
    required String transactionType,
    required double previousTotal,  // ← add
    String?         description,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      final remainingAmount = transactionType == 'cash_in' ? previousTotal + amount : previousTotal - amount;
      final String _storeId = _ref.watch(authProvider).storeId;

      final saved = await _ds.add(
        storeId:         _storeId,
        counterId:       _counterId,
        previousAmount:  previousTotal,
        cashOutAmount:   amount,
        remainingAmount: remainingAmount,
        transactionType: transactionType,
        description:     description,
      );

      state = state.copyWith(
        allTransactions: [saved, ...state.allTransactions],
        todayTotal:      remainingAmount,
        isSaving:        false,
      );

      _ref.read(cashCounterProvider.notifier).loadRecords();

    } catch (e, stack) {
      print('❌ Transaction error: $e');
      print('❌ Stack: $stack');
      state = state.copyWith(
          isSaving: false, errorMessage: e.toString());
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final cashTransactionProvider =
StateNotifierProvider<CashTransactionNotifier, CashTransactionState>(
      (ref) => CashTransactionNotifier(ref),
);