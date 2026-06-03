// lib/features/accountant/branch_reports/accountant_branch_transaction/presentation/provider/accountant_branch_transaction_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_branch_transaction_datasource.dart';
import '../../data/model/accountant_branch_transaction_model.dart';

// ─────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────
class BranchTransactionState {
  final List<BranchTransactionModel> transactions;
  final String    branchName;
  final bool      isLoading;
  final String?   errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;

  double get totalCashOut => transactions
      .where((t) => t.isCashOut)
      .fold(0, (s, t) => s + t.payAmount);

  const BranchTransactionState({
    this.transactions = const [],
    this.branchName   = '',
    this.isLoading    = false,
    this.errorMessage,
    this.startDate,
    this.endDate,
  });

  BranchTransactionState copyWith({
    List<BranchTransactionModel>? transactions,
    String?                       branchName,
    bool?                         isLoading,
    Object?                       errorMessage = _sentinel,
    Object?                       startDate    = _sentinel,
    Object?                       endDate      = _sentinel,
  }) =>
      BranchTransactionState(
        transactions: transactions ?? this.transactions,
        branchName:   branchName   ?? this.branchName,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
        startDate: startDate == _sentinel
            ? this.startDate
            : startDate as DateTime?,
        endDate: endDate == _sentinel
            ? this.endDate
            : endDate as DateTime?,
      );
}

const _sentinel = Object();

// ─────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────
class BranchTransactionNotifier
    extends StateNotifier<BranchTransactionState> {
  final BranchTransactionDatasource _datasource;
  final String _branchId;

  BranchTransactionNotifier(this._datasource, this._branchId)
      : super(const BranchTransactionState()) {
    _init();
  }

  /// Pehle branch name fetch karo, phir transactions
  Future<void> _init() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final name = await _datasource.fetchBranchName(_branchId);
      state = state.copyWith(branchName: name);
      await load();
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _datasource.fetchTransactions(
        branchId:  _branchId,
        startDate: state.startDate,
        endDate:   state.endDate,
      );
      state = state.copyWith(transactions: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> applyDateFilter(
      DateTime? startDate, DateTime? endDate) async {
    state = state.copyWith(startDate: startDate, endDate: endDate);
    await load();
  }

  Future<void> clearFilter() async {
    state = state.copyWith(startDate: null, endDate: null);
    await load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ─────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────
final branchTransactionProvider = StateNotifierProvider.autoDispose
    .family<BranchTransactionNotifier, BranchTransactionState, String>(
      (ref, branchId) {
    final datasource = BranchTransactionDatasource(
        client: Supabase.instance.client);
    return BranchTransactionNotifier(datasource, branchId);
  },
);