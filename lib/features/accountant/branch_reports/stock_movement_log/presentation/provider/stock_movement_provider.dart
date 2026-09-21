import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/stock_movement_datasource.dart';
import '../../data/model/stock_movement_model.dart';

// ═══════════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════════

class StockMovementState {
  /// Every event in the date range. Event-type filtering and paging happen
  /// on this list in memory — the log is merged from several tables, so it
  /// can't be paged server-side.
  final StockMovementReportData data;
  final DateTime                fromDate;
  final DateTime                toDate;
  final StockMovementType?      selectedType;
  final int                     page;
  final bool                    isLoading;
  final String?                 errorMessage;

  StockMovementState({
    this.data = const StockMovementReportData(rows: [], branchName: ''),
    DateTime? fromDate,
    DateTime? toDate,
    this.selectedType,
    this.page      = 0,
    this.isLoading = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// [data] narrowed to [selectedType].
  List<StockMovementRow> get filteredRows => selectedType == null
      ? data.rows
      : data.rows.where((r) => r.entry.type == selectedType).toList();

  List<StockMovementRow> get pageRows {
    final rows  = filteredRows;
    final start = page * BranchReportPagination.pageSize;
    if (start >= rows.length) return const [];
    final end = start + BranchReportPagination.pageSize;
    return rows.sublist(start, end > rows.length ? rows.length : end);
  }

  bool get hasNextPage =>
      (page + 1) * BranchReportPagination.pageSize < filteredRows.length;

  StockMovementState copyWith({
    StockMovementReportData? data,
    DateTime?                fromDate,
    DateTime?                toDate,
    StockMovementType?       selectedType,
    bool                     clearType = false,
    int?                     page,
    bool?                    isLoading,
    String?                  errorMessage,
  }) =>
      StockMovementState(
        data:         data      ?? this.data,
        fromDate:     fromDate  ?? this.fromDate,
        toDate:       toDate    ?? this.toDate,
        selectedType: clearType ? null : (selectedType ?? this.selectedType),
        page:         page      ?? this.page,
        isLoading:    isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

// ═══════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════

class StockMovementNotifier extends StateNotifier<StockMovementState> {
  final StockMovementDatasource _ds;

  StockMovementNotifier({required String branchId})
      : _ds = StockMovementDatasource(branchId: branchId),
        super(StockMovementState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, page: 0);
    try {
      final data = await _ds.fetchReport(
        fromDate: state.fromDate,
        toDate:   state.toDate,
      );
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Load error: $e',
      );
    }
  }

  void nextPage() {
    if (state.hasNextPage) state = state.copyWith(page: state.page + 1);
  }

  void previousPage() {
    if (state.page > 0) state = state.copyWith(page: state.page - 1);
  }

  void setFromDate(DateTime d) {
    state = state.copyWith(
      fromDate: d,
      toDate:   state.toDate.isBefore(d) ? d : state.toDate,
    );
    load();
  }

  void setToDate(DateTime d) {
    state = state.copyWith(
      toDate:   d,
      fromDate: state.fromDate.isAfter(d) ? d : state.fromDate,
    );
    load();
  }

  void setToday() {
    final today = StockMovementState._today();
    state = state.copyWith(fromDate: today, toDate: today);
    load();
  }

  void setType(StockMovementType? type) {
    state = state.copyWith(
      selectedType: type,
      clearType:    type == null,
      page:         0,
    );
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ═══════════════════════════════════════════════════════════
//  PROVIDER — family with branchId
// ═══════════════════════════════════════════════════════════

final stockMovementProvider = StateNotifierProvider.autoDispose
    .family<StockMovementNotifier, StockMovementState, String>(
  (ref, branchId) => StockMovementNotifier(branchId: branchId),
);
