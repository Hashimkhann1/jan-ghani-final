import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../branch/customer_ledger/data/model/customer_ledger_model.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/customer_ledger_report_datasource.dart';

const _keep = Object();

class CustomerLedgerReportState {
  final List<CustomerLedgerModel> entries;
  final int totalCount;
  final double totalPaid;
  final BranchReportPageState pagination;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;
  final String search;

  const CustomerLedgerReportState({
    this.entries = const [],
    this.totalCount = 0,
    this.totalPaid = 0,
    this.pagination = const BranchReportPageState(),
    this.isLoading = false,
    this.errorMessage,
    this.startDate,
    this.endDate,
    this.search = '',
  });

  CustomerLedgerReportState copyWith({
    List<CustomerLedgerModel>? entries,
    int? totalCount,
    double? totalPaid,
    BranchReportPageState? pagination,
    bool? isLoading,
    Object? errorMessage = _keep,
    Object? startDate = _keep,
    Object? endDate = _keep,
    String? search,
  }) =>
      CustomerLedgerReportState(
        entries: entries ?? this.entries,
        totalCount: totalCount ?? this.totalCount,
        totalPaid: totalPaid ?? this.totalPaid,
        pagination: pagination ?? this.pagination,
        isLoading: isLoading ?? this.isLoading,
        errorMessage:
            errorMessage == _keep ? this.errorMessage : errorMessage as String?,
        startDate: startDate == _keep ? this.startDate : startDate as DateTime?,
        endDate: endDate == _keep ? this.endDate : endDate as DateTime?,
        search: search ?? this.search,
      );
}

class CustomerLedgerReportNotifier
    extends StateNotifier<CustomerLedgerReportState> {
  final CustomerLedgerReportDatasource _ds;
  final String _branchId;

  CustomerLedgerReportNotifier(this._ds, this._branchId)
      : super(const CustomerLedgerReportState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      pagination: const BranchReportPageState(),
    );
    try {
      final results = await Future.wait([
        _ds.fetchPage(
          branchId: _branchId,
          page: 0,
          startDate: state.startDate,
          endDate: state.endDate,
          search: state.search,
        ),
        _ds.fetchTotals(
          branchId: _branchId,
          startDate: state.startDate,
          endDate: state.endDate,
          search: state.search,
        ),
      ]);
      final paged = results[0] as (List<CustomerLedgerModel>, bool);
      final totals = results[1] as LedgerReportTotals;
      state = state.copyWith(
        entries: paged.$1,
        totalCount: totals.totalCount,
        totalPaid: totals.totalPaid,
        isLoading: false,
        pagination: BranchReportPageState(page: 0, hasNextPage: paged.$2),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> nextPage() async {
    if (!state.pagination.hasNextPage || state.pagination.isLoadingPage) return;
    final page = state.pagination.page + 1;
    state = state.copyWith(
        pagination: state.pagination.copyWith(isLoadingPage: true));
    try {
      final paged = await _ds.fetchPage(
        branchId: _branchId,
        page: page,
        startDate: state.startDate,
        endDate: state.endDate,
        search: state.search,
      );
      state = state.copyWith(
        entries: [...state.entries, ...paged.$1],
        pagination: BranchReportPageState(page: page, hasNextPage: paged.$2),
      );
    } catch (e) {
      state = state.copyWith(
        pagination: state.pagination.copyWith(isLoadingPage: false),
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> applyDateFilter(DateTime? start, DateTime? end) async {
    state = state.copyWith(startDate: start, endDate: end);
    await load();
  }

  Future<void> setSearch(String q) async {
    state = state.copyWith(search: q);
    await load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final customerLedgerReportProvider = StateNotifierProvider.autoDispose
    .family<CustomerLedgerReportNotifier, CustomerLedgerReportState, String>(
  (ref, branchId) => CustomerLedgerReportNotifier(
    CustomerLedgerReportDatasource(client: Supabase.instance.client),
    branchId,
  ),
);
