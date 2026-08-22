import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/branch_cash_difference_datasource.dart';
import '../../data/model/branch_cash_difference_model.dart';

// ─────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────
class BranchCashDifferenceState {
  final List<BranchCashDifferenceEntry> entries;
  final int       totalCount;
  final double    totalCashIn;
  final double    totalCashOut;
  final BranchReportPageState pagination;
  final bool      isLoading;
  final String?   errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;

  const BranchCashDifferenceState({
    this.entries      = const [],
    this.totalCount   = 0,
    this.totalCashIn  = 0,
    this.totalCashOut = 0,
    this.pagination   = const BranchReportPageState(),
    this.isLoading    = false,
    this.errorMessage,
    this.startDate,
    this.endDate,
  });

  double get netDifference => totalCashIn - totalCashOut;

  BranchCashDifferenceState copyWith({
    List<BranchCashDifferenceEntry>? entries,
    int?                    totalCount,
    double?                 totalCashIn,
    double?                 totalCashOut,
    BranchReportPageState?  pagination,
    bool?                   isLoading,
    Object?                 errorMessage = _sentinel,
    Object?                 startDate    = _sentinel,
    Object?                 endDate      = _sentinel,
  }) =>
      BranchCashDifferenceState(
        entries:      entries      ?? this.entries,
        totalCount:   totalCount   ?? this.totalCount,
        totalCashIn:  totalCashIn  ?? this.totalCashIn,
        totalCashOut: totalCashOut ?? this.totalCashOut,
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
class BranchCashDifferenceNotifier
    extends StateNotifier<BranchCashDifferenceState> {
  final BranchCashDifferenceDatasource _datasource;
  final String _branchId;

  BranchCashDifferenceNotifier(this._datasource, this._branchId)
      : super(const BranchCashDifferenceState()) {
    load();
  }

  // ── Load — resets to page 0 and refreshes the totals ───────────────────
  Future<void> load() async {
    state = state.copyWith(
      isLoading:    true,
      errorMessage: null,
      pagination:   const BranchReportPageState(),
    );
    try {
      final results = await Future.wait([
        _datasource.fetchEntriesPage(
          branchId:  _branchId,
          startDate: state.startDate,
          endDate:   state.endDate,
          page:      0,
        ),
        _datasource.fetchTotals(
          branchId:  _branchId,
          startDate: state.startDate,
          endDate:   state.endDate,
        ),
      ]);
      final paged  = results[0] as PagedBranchCashDifference;
      final totals = results[1] as BranchCashDifferenceTotals;
      state = state.copyWith(
        entries:      paged.entries,
        totalCount:   totals.totalCount,
        totalCashIn:  totals.totalCashIn,
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

  // ── Page navigation — only re-fetches the entry list, not the
  //    date-range-wide totals ─────────────────────────────────────────────
  Future<void> _loadPage(int page) async {
    state = state.copyWith(
      pagination: state.pagination.copyWith(isLoadingPage: true),
    );
    try {
      final paged = await _datasource.fetchEntriesPage(
        branchId:  _branchId,
        startDate: state.startDate,
        endDate:   state.endDate,
        page:      page,
      );
      state = state.copyWith(
        entries:    paged.entries,
        pagination: BranchReportPageState(
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
final branchCashDifferenceProvider = StateNotifierProvider.autoDispose
    .family<BranchCashDifferenceNotifier, BranchCashDifferenceState, String>(
      (ref, branchId) {
    final datasource = BranchCashDifferenceDatasource(
        client: Supabase.instance.client);
    return BranchCashDifferenceNotifier(datasource, branchId);
  },
);
