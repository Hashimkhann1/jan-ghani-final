import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/branch_transaction_datasource.dart';
import '../../data/model/branch_transaction_history_model.dart';

// ── STATE ─────────────────────────────────────────────────
class BranchTransactionState {
  final double   totalAmount;
  final double   cashInHand;
  final List<BranchTransactionHistoryModel> history;
  final bool     isLoading;
  final bool     isSubmitting;
  final String?  errorMessage;
  final bool     isSuccess;
  final String?  syncingRowId; // konsi row sync ho rahi hai

  const BranchTransactionState({
    this.totalAmount   = 0.0,
    this.cashInHand    = 0.0,
    this.history       = const [],
    this.isLoading     = false,
    this.isSubmitting  = false,
    this.errorMessage,
    this.isSuccess     = false,
    this.syncingRowId,
  });

  BranchTransactionState copyWith({
    double?  totalAmount,
    double?  cashInHand,
    List<BranchTransactionHistoryModel>? history,
    bool?    isLoading,
    bool?    isSubmitting,
    String?  errorMessage,
    bool?    isSuccess,
    String?  syncingRowId,
  }) =>
      BranchTransactionState(
        totalAmount:   totalAmount   ?? this.totalAmount,
        cashInHand:    cashInHand    ?? this.cashInHand,
        history:       history       ?? this.history,
        isLoading:     isLoading     ?? this.isLoading,
        isSubmitting:  isSubmitting  ?? this.isSubmitting,
        errorMessage:  errorMessage,
        isSuccess:     isSuccess     ?? this.isSuccess,
        syncingRowId:  syncingRowId,
      );
}

// ── NOTIFIER ──────────────────────────────────────────────
class BranchTransactionNotifier extends StateNotifier<BranchTransactionState> {
  final BranchTransactionDataSource _ds;
  final Ref _ref;

  BranchTransactionNotifier(this._ref)
      : _ds = BranchTransactionDataSource(),
        super(const BranchTransactionState());

  // ── Load data ──────────────────────────────────────────
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final auth        = _ref.read(authProvider);
      final storeId     = auth.storeId;
      final totalAmount = await _ds.getBranchTotalAmount(storeId);
      final historyList = await _ds.getHistory(storeId);

      state = state.copyWith(
        totalAmount: totalAmount,
        history:     historyList,
        isLoading:   false,
      );
    } catch (e, stack) {
      print('❌ loadData error: $e');
      print('❌ stack: $stack');
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Data load error: $e',
      );
    }
  }

  // ── Cash Out ───────────────────────────────────────────
  Future<void> cashOut(double payAmount) async {
    if (payAmount <= 0) {
      state = state.copyWith(errorMessage: 'Amount 0 se zyada hona chahiye');
      return;
    }
    if (payAmount > state.totalAmount) {
      state = state.copyWith(errorMessage: 'Amount total se zyada nahi ho sakta');
      return;
    }

    state = state.copyWith(
        isSubmitting: true, errorMessage: null, isSuccess: false);

    try {
      final auth      = _ref.read(authProvider);
      final beforeAmt = state.totalAmount;
      final afterAmt  = beforeAmt - payAmount;

      await _ds.cashOut(
        branchId:     auth.storeId,
        assignById:   auth.userId,
        assignByName: auth.fullName,
        beforeAmount: beforeAmt,
        payAmount:    payAmount,
        afterAmount:  afterAmt,
      );

      await loadData();
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Cash out error: $e',
      );
    }
  }

  // ── Sync single pending row ────────────────────────────
  Future<void> syncRow(String rowId, double payAmount) async {
    state = state.copyWith(syncingRowId: rowId, errorMessage: null);
    try {
      await _ds.syncToJanghani(rowId, payAmount);
      await loadData();
      state = state.copyWith(syncingRowId: null);
    } catch (e) {
      state = state.copyWith(
        syncingRowId: null,
        errorMessage: 'Sync error: $e',
      );
    }
  }

  void clearError()   => state = state.copyWith(errorMessage: null);
  void clearSuccess() => state = state.copyWith(isSuccess: false);
}

// ── PROVIDER ──────────────────────────────────────────────
final branchTransactionProvider =
StateNotifierProvider<BranchTransactionNotifier, BranchTransactionState>(
      (ref) => BranchTransactionNotifier(ref),
);