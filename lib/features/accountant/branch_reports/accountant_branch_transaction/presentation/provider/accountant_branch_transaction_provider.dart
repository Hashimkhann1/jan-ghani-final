// lib/features/accountant/branch_reports/accountant_branch_transaction/presentation/provider/accountant_branch_transaction_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/accountant_branch_transaction_datasource.dart';
import '../../data/model/accountant_branch_transaction_model.dart';

// ─────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────
class BranchTransactionState {
  final List<BranchTransactionModel> transactions;
  final int       totalCount;
  final double    totalCashOut;
  final String    branchName;
  final BranchReportPageState pagination;
  final bool      isLoading;
  final String?   errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;

  const BranchTransactionState({
    this.transactions = const [],
    this.totalCount   = 0,
    this.totalCashOut = 0,
    this.branchName   = '',
    this.pagination   = const BranchReportPageState(),
    this.isLoading    = false,
    this.errorMessage,
    this.startDate,
    this.endDate,
  });

  BranchTransactionState copyWith({
    List<BranchTransactionModel>? transactions,
    int?                          totalCount,
    double?                       totalCashOut,
    String?                       branchName,
    BranchReportPageState?        pagination,
    bool?                         isLoading,
    Object?                       errorMessage = _sentinel,
    Object?                       startDate    = _sentinel,
    Object?                       endDate      = _sentinel,
  }) =>
      BranchTransactionState(
        transactions: transactions ?? this.transactions,
        totalCount:   totalCount   ?? this.totalCount,
        totalCashOut: totalCashOut ?? this.totalCashOut,
        branchName:   branchName   ?? this.branchName,
        pagination:   pagination   ?? this.pagination,
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

  // ── Load — resets to page 0 and refreshes the cash-out total ───────────
  Future<void> load() async {
    state = state.copyWith(
      isLoading:  true,
      errorMessage: null,
      pagination: const BranchReportPageState(),
    );
    try {
      final results = await Future.wait([
        _datasource.fetchTransactionsPage(
          branchId:  _branchId,
          startDate: state.startDate,
          endDate:   state.endDate,
          page:      0,
        ),
        _datasource.fetchTransactionTotals(
          branchId:  _branchId,
          startDate: state.startDate,
          endDate:   state.endDate,
        ),
      ]);
      final paged  = results[0] as PagedBranchTransactions;
      final totals = results[1] as BranchTransactionTotals;
      state = state.copyWith(
        transactions: paged.transactions,
        totalCount:   totals.totalCount,
        totalCashOut: totals.totalCashOut,
        isLoading:    false,
        pagination:   BranchReportPageState(
            page: 0, hasNextPage: paged.hasNextPage),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Page navigation — only re-fetches the transaction list, not the
  //    date-range-wide cash-out total ─────────────────────────────────────
  Future<void> _loadPage(int page) async {
    state = state.copyWith(
      pagination: state.pagination.copyWith(isLoadingPage: true),
    );
    try {
      final paged = await _datasource.fetchTransactionsPage(
        branchId:  _branchId,
        startDate: state.startDate,
        endDate:   state.endDate,
        page:      page,
      );
      state = state.copyWith(
        transactions: paged.transactions,
        pagination:   BranchReportPageState(
          page:          page,
          hasNextPage:   paged.hasNextPage,
          isLoadingPage: false,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        pagination:   state.pagination.copyWith(isLoadingPage: false),
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> nextPage() async {
    if (!state.pagination.hasNextPage || state.pagination.isLoadingPage) {
      return;
    }
    await _loadPage(state.pagination.page + 1);
  }

  Future<void> previousPage() async {
    if (!state.pagination.hasPreviousPage || state.pagination.isLoadingPage) {
      return;
    }
    await _loadPage(state.pagination.page - 1);
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