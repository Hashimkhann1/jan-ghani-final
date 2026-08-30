import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/accountant_profit_loss_datasource.dart';
import '../../data/model/accountant_profit_loss_model.dart';

export '../../data/datasource/accountant_profit_loss_datasource.dart'
    show PnlInvoiceFilter;

// ═══════════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════════

class PnlReportState {
  final PnlSummary? summary;
  final DateTime    fromDate;
  final DateTime    toDate;
  final bool        isLoading;
  final String?     errorMessage;
  final String      storeId;

  // ── Invoices tab: server-paginated, server-counted ──────────
  final List<PnlTransactionRow> rows;
  final PnlInvoiceFilter        filter;
  final int                     page;
  final bool                    hasNextPage;
  final bool                    isLoadingPage;
  final int                     totalCount;
  final int                     profitCount;
  final int                     lossCount;

  PnlReportState({
    this.summary,
    required this.storeId,
    DateTime? fromDate,
    DateTime? toDate,
    this.isLoading     = false,
    this.errorMessage,
    this.rows          = const [],
    this.filter        = PnlInvoiceFilter.all,
    this.page          = 0,
    this.hasNextPage   = false,
    this.isLoadingPage = false,
    this.totalCount    = 0,
    this.profitCount   = 0,
    this.lossCount     = 0,
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

  PnlReportState copyWith({
    PnlSummary? summary,
    DateTime?   fromDate,
    DateTime?   toDate,
    bool?       isLoading,
    String?     errorMessage,
    String?     storeId,
    List<PnlTransactionRow>? rows,
    PnlInvoiceFilter? filter,
    int?  page,
    bool? hasNextPage,
    bool? isLoadingPage,
    int?  totalCount,
    int?  profitCount,
    int?  lossCount,
  }) =>
      PnlReportState(
        summary:       summary       ?? this.summary,
        fromDate:      fromDate      ?? this.fromDate,
        toDate:        toDate        ?? this.toDate,
        isLoading:     isLoading     ?? this.isLoading,
        errorMessage:  errorMessage,
        storeId:       storeId       ?? this.storeId,
        rows:          rows          ?? this.rows,
        filter:        filter        ?? this.filter,
        page:          page          ?? this.page,
        hasNextPage:   hasNextPage   ?? this.hasNextPage,
        isLoadingPage: isLoadingPage ?? this.isLoadingPage,
        totalCount:    totalCount    ?? this.totalCount,
        profitCount:   profitCount   ?? this.profitCount,
        lossCount:     lossCount     ?? this.lossCount,
      );

  int get totalPages => totalCount == 0
      ? 1
      : ((totalCount - 1) ~/ PnlReportDatasource.pageSize) + 1;
}

// ═══════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════

class PnlReportNotifier extends StateNotifier<PnlReportState> {
  final PnlReportDatasource _ds;

  PnlReportNotifier(String storeId)
      : _ds = PnlReportDatasource(),
        super(PnlReportState(storeId: storeId)) {
    load();
  }

  // ── Summary (RPC) + page 0 of the invoices tab + fresh tab
  //    counts, for the current date range / filter. ────────────
  Future<void> load() async {
    state = state.copyWith(isLoading: true, page: 0);
    try {
      final results = await Future.wait([
        _ds.getSummary(
          fromDate: state.fromDate,
          toDate:   state.toDate,
          storeId:  state.storeId,
        ),
        _ds.getTransactionsPage(
          fromDate: state.fromDate,
          toDate:   state.toDate,
          storeId:  state.storeId,
          filter:   state.filter,
          page:     0,
        ),
        _ds.getFilterCount(
          fromDate: state.fromDate,
          toDate:   state.toDate,
          storeId:  state.storeId,
          filter:   PnlInvoiceFilter.profit,
        ),
        _ds.getFilterCount(
          fromDate: state.fromDate,
          toDate:   state.toDate,
          storeId:  state.storeId,
          filter:   PnlInvoiceFilter.loss,
        ),
      ]);

      final summary       = results[0] as PnlSummary;
      final page          = results[1] as PnlTransactionsPage;
      final profitCount   = results[2] as int;
      final lossCount     = results[3] as int;

      state = state.copyWith(
        summary:     summary,
        isLoading:   false,
        rows:        page.rows,
        page:        0,
        hasNextPage: page.rows.length == PnlReportDatasource.pageSize,
        totalCount:  page.totalCount,
        profitCount: profitCount,
        lossCount:   lossCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  // ── Changing the All/Profit/Loss filter re-queries the server
  //    instead of re-filtering an in-memory list. ────────────────
  Future<void> setFilter(PnlInvoiceFilter filter) async {
    if (filter == state.filter) return;
    state = state.copyWith(filter: filter, isLoadingPage: true, page: 0);
    try {
      final page = await _ds.getTransactionsPage(
        fromDate: state.fromDate,
        toDate:   state.toDate,
        storeId:  state.storeId,
        filter:   filter,
        page:     0,
      );
      state = state.copyWith(
        rows:          page.rows,
        totalCount:    page.totalCount,
        hasNextPage:   page.rows.length == PnlReportDatasource.pageSize,
        isLoadingPage: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingPage: false, errorMessage: 'Load error: $e');
    }
  }

  Future<void> nextPage() async {
    if (!state.hasNextPage || state.isLoadingPage) return;
    await _loadPage(state.page + 1);
  }

  Future<void> previousPage() async {
    if (state.page == 0 || state.isLoadingPage) return;
    await _loadPage(state.page - 1);
  }

  Future<void> _loadPage(int page) async {
    state = state.copyWith(isLoadingPage: true);
    try {
      final result = await _ds.getTransactionsPage(
        fromDate: state.fromDate,
        toDate:   state.toDate,
        storeId:  state.storeId,
        filter:   state.filter,
        page:     page,
      );
      state = state.copyWith(
        rows:          result.rows,
        page:          page,
        totalCount:    result.totalCount,
        hasNextPage:   result.rows.length == PnlReportDatasource.pageSize,
        isLoadingPage: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingPage: false, errorMessage: 'Load error: $e');
    }
  }

  Future<List<PnlItem>> loadItems(PnlTransactionRow row) =>
      _ds.getTransactionItems(type: row.type, id: row.id);

  void setFromDate(DateTime d) {
    state = state.copyWith(fromDate: d);
    load();
  }

  void setToDate(DateTime d) {
    state = state.copyWith(toDate: d);
    load();
  }

  void setThisMonth() {
    final n = DateTime.now();
    state = state.copyWith(
      fromDate: DateTime(n.year, n.month, 1),
      toDate:   DateTime(n.year, n.month, n.day),
    );
    load();
  }

  void setToday() {
    final d = PnlReportState._today();
    state = state.copyWith(fromDate: d, toDate: d);
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ═══════════════════════════════════════════════════════════
//  PROVIDER
// ═══════════════════════════════════════════════════════════

final pnlReportProvider =
StateNotifierProvider.family<PnlReportNotifier, PnlReportState, String>(
      (ref, branchId) => PnlReportNotifier(branchId),
);
