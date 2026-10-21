import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/assigned_stock_datasource.dart';
import '../../data/model/assigned_stock_model.dart';

class AssignedStockState {
  final List<AssignedStockTransfer> transfers;
  final DateTime fromDate;
  final DateTime toDate;
  final String? status; // null = all
  final int page;
  final bool isLoading;
  final String? errorMessage;

  AssignedStockState({
    this.transfers = const [],
    DateTime? fromDate,
    DateTime? toDate,
    this.status,
    this.page = 0,
    this.isLoading = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _monthStart(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _monthStart() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, 1);
  }

  List<AssignedStockTransfer> get filtered => status == null
      ? transfers
      : transfers.where((t) => t.status == status).toList();

  List<AssignedStockTransfer> get pageRows {
    final rows  = filtered;
    final start = page * BranchReportPagination.pageSize;
    if (start >= rows.length) return const [];
    final end = start + BranchReportPagination.pageSize;
    return rows.sublist(start, end > rows.length ? rows.length : end);
  }

  bool get hasNextPage =>
      (page + 1) * BranchReportPagination.pageSize < filtered.length;

  double get totalUnits => filtered.fold(0.0, (s, t) => s + t.totalUnits);
  double get totalCost  => filtered.fold(0.0, (s, t) => s + t.totalCost);
  double get totalSale  => filtered.fold(0.0, (s, t) => s + t.totalSale);

  AssignedStockState copyWith({
    List<AssignedStockTransfer>? transfers,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    bool clearStatus = false,
    int? page,
    bool? isLoading,
    String? errorMessage,
  }) =>
      AssignedStockState(
        transfers:    transfers ?? this.transfers,
        fromDate:     fromDate  ?? this.fromDate,
        toDate:       toDate    ?? this.toDate,
        status:       clearStatus ? null : (status ?? this.status),
        page:         page      ?? this.page,
        isLoading:    isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class AssignedStockNotifier extends StateNotifier<AssignedStockState> {
  final AssignedStockDatasource _ds;

  AssignedStockNotifier({required String branchId})
      : _ds = AssignedStockDatasource(branchId: branchId),
        super(AssignedStockState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, page: 0);
    try {
      final data = await _ds.fetch(
          fromDate: state.fromDate, toDate: state.toDate);
      state = state.copyWith(transfers: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
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
      toDate: state.toDate.isBefore(d) ? d : state.toDate,
    );
    load();
  }

  void setToDate(DateTime d) {
    state = state.copyWith(
      toDate: d,
      fromDate: state.fromDate.isAfter(d) ? d : state.fromDate,
    );
    load();
  }

  void setStatus(String? status) => state = state.copyWith(
      status: status, clearStatus: status == null, page: 0);

  void clearError() => state = state.copyWith(errorMessage: null);
}

final assignedStockProvider = StateNotifierProvider.autoDispose
    .family<AssignedStockNotifier, AssignedStockState, String>(
  (ref, branchId) => AssignedStockNotifier(branchId: branchId),
);
