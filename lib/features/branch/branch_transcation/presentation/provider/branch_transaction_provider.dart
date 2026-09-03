import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/service/sync/sync_service.dart';
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
  final String?  syncingRowId;
  final DateTime? startDate;
  final DateTime? endDate;

  const BranchTransactionState({
    this.totalAmount   = 0.0,
    this.cashInHand    = 0.0,
    this.history       = const [],
    this.isLoading     = false,
    this.isSubmitting  = false,
    this.errorMessage,
    this.isSuccess     = false,
    this.syncingRowId,
    this.startDate,
    this.endDate,
  });

  BranchTransactionState copyWith({
    double?   totalAmount,
    double?   cashInHand,
    List<BranchTransactionHistoryModel>? history,
    bool?     isLoading,
    bool?     isSubmitting,
    String?   errorMessage,
    bool?     isSuccess,
    String?   syncingRowId,
    DateTime? startDate,
    DateTime? endDate,
    bool      clearDates = false,
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
        startDate:     clearDates ? null : (startDate ?? this.startDate),
        endDate:       clearDates ? null : (endDate   ?? this.endDate),
      );
}

// ── NOTIFIER ──────────────────────────────────────────────
class BranchTransactionNotifier extends StateNotifier<BranchTransactionState> {
  final BranchTransactionDataSource _ds;
  final Ref _ref;

  BranchTransactionNotifier(this._ref)
      : _ds = BranchTransactionDataSource(),
        super(const BranchTransactionState());

  int _loadReq = 0;

  // ── Load data (uses current startDate/endDate filter agar set ho) ──
  Future<void> loadData() async {
    final storeId = _ref.read(authProvider).storeId;
    if (storeId.isEmpty) return;

    final req = ++_loadReq;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final totalAmount = await _ds.getBranchTotalAmount(storeId);
      final historyList = await _ds.getHistory(
        storeId,
        startDate: state.startDate,
        endDate:   state.endDate,
      );

      if (req != _loadReq) return; // superseded by a newer load

      state = state.copyWith(
        totalAmount: totalAmount,
        history:     historyList,
        isLoading:   false,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('loadData error: $e');
        debugPrint('stack: $stack');
      }
      if (req != _loadReq) return;
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Data load nahi ho saka',
      );
    }
  }

  // ── Date filter set karo aur dobara load karo ──────────
  Future<void> setDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(startDate: start, endDate: end);
    await loadData();
  }

  // ── Date filter clear karo (sab history dikhao) ────────
  Future<void> clearDateRange() async {
    state = state.copyWith(clearDates: true);
    await loadData();
  }

  // ── Cash Out ───────────────────────────────────────────
  Future<void> cashOut(double payAmount) async {
    if (state.isSubmitting) return;

    // Reset any stale success flag from a previous cash out so a failed
    // attempt can never trip the success path.
    state = state.copyWith(isSuccess: false, errorMessage: null);

    if (payAmount <= 0) {
      state = state.copyWith(errorMessage: 'Amount 0 se zyada hona chahiye');
      return;
    }
    if (payAmount > state.totalAmount) {
      state = state.copyWith(errorMessage: 'Amount total se zyada nahi ho sakta');
      return;
    }

    final auth = _ref.read(authProvider);
    if (auth.storeId.isEmpty || auth.userId.isEmpty) {
      state = state.copyWith(errorMessage: 'Session invalid — dobara login karein');
      return;
    }

    state = state.copyWith(isSubmitting: true);

    try {
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

      // Net available ho to turant background sync — pending amount ko
      // janghani_net_amount tak pahunchane ke liye. Fire-and-forget.
      unawaited(SyncService().syncNow());
    } catch (e) {
      if (kDebugMode) debugPrint('cashOut error: $e');
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Cash out nahi ho saka — $msg',
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