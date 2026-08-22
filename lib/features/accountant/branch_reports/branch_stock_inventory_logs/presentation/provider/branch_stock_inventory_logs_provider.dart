import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/branch_stock_inventory_logs_datasource.dart';
import '../../data/model/branch_stock_inventory_logs_model.dart';

// ─────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────
class BranchStockInventoryLogsState {
  final List<BranchStockInventoryLogEntry> entries;
  final int       totalCount;
  final BranchReportPageState pagination;
  final bool      isLoading;
  final String?   errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;

  const BranchStockInventoryLogsState({
    this.entries    = const [],
    this.totalCount = 0,
    this.pagination = const BranchReportPageState(),
    this.isLoading  = false,
    this.errorMessage,
    this.startDate,
    this.endDate,
  });

  BranchStockInventoryLogsState copyWith({
    List<BranchStockInventoryLogEntry>? entries,
    int?                    totalCount,
    BranchReportPageState?  pagination,
    bool?                   isLoading,
    Object?                 errorMessage = _sentinel,
    Object?                 startDate    = _sentinel,
    Object?                 endDate      = _sentinel,
  }) =>
      BranchStockInventoryLogsState(
        entries:    entries    ?? this.entries,
        totalCount: totalCount ?? this.totalCount,
        pagination: pagination ?? this.pagination,
        isLoading:  isLoading  ?? this.isLoading,
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
class BranchStockInventoryLogsNotifier
    extends StateNotifier<BranchStockInventoryLogsState> {
  final BranchStockInventoryLogsDatasource _datasource;
  final String _branchId;

  BranchStockInventoryLogsNotifier(this._datasource, this._branchId)
      : super(const BranchStockInventoryLogsState()) {
    load();
  }

  // ── Load — resets to page 0 and refreshes the total count ──────────────
  Future<void> load() async {
    state = state.copyWith(
      isLoading:    true,
      errorMessage: null,
      pagination:   const BranchReportPageState(),
    );
    try {
      final results = await Future.wait([
        _datasource.fetchLogsPage(
          branchId:  _branchId,
          startDate: state.startDate,
          endDate:   state.endDate,
          page:      0,
        ),
        _datasource.fetchTotalCount(
          branchId:  _branchId,
          startDate: state.startDate,
          endDate:   state.endDate,
        ),
      ]);
      final paged = results[0] as PagedBranchStockInventoryLogs;
      final count = results[1] as int;
      state = state.copyWith(
        entries:    paged.entries,
        totalCount: count,
        isLoading:  false,
        pagination: BranchReportPageState(
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
  //    date-range-wide count ──────────────────────────────────────────────
  Future<void> _loadPage(int page) async {
    state = state.copyWith(
      pagination: state.pagination.copyWith(isLoadingPage: true),
    );
    try {
      final paged = await _datasource.fetchLogsPage(
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
final branchStockInventoryLogsProvider = StateNotifierProvider.autoDispose
    .family<BranchStockInventoryLogsNotifier, BranchStockInventoryLogsState,
        String>((ref, branchId) {
  final datasource = BranchStockInventoryLogsDatasource(
      client: Supabase.instance.client);
  return BranchStockInventoryLogsNotifier(datasource, branchId);
});
