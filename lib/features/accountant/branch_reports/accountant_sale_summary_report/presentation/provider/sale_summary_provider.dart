import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/sale_summary_datasource.dart';
import '../../data/model/sale_summary_model.dart';

class SaleSummaryState {
  final SaleSummary          summary;
  final List<SummaryInvoice> invoices;
  final BranchReportPageState pagination;
  final List<SummaryCustomer> customers;
  final DateTime             fromDate;
  final DateTime             toDate;
  final String?              selectedCustomerId;
  final bool                 isLoading;
  final String?              errorMessage;

  SaleSummaryState({
    this.summary            = const SaleSummary(),
    this.invoices           = const [],
    this.pagination         = const BranchReportPageState(),
    this.customers          = const [],
    DateTime?               fromDate,
    DateTime?               toDate,
    this.selectedCustomerId,
    this.isLoading          = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? startOfToday(),
        toDate   = toDate   ?? endOfToday();

  static DateTime startOfToday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime endOfToday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, 23, 59, 59);
  }

  SaleSummaryState copyWith({
    SaleSummary?           summary,
    List<SummaryInvoice>?  invoices,
    BranchReportPageState? pagination,
    List<SummaryCustomer>? customers,
    DateTime?              fromDate,
    DateTime?              toDate,
    String?                selectedCustomerId,
    bool                   clearCustomer = false,
    bool?                  isLoading,
    String?                errorMessage,
  }) =>
      SaleSummaryState(
        summary:            summary   ?? this.summary,
        invoices:           invoices  ?? this.invoices,
        pagination:         pagination ?? this.pagination,
        customers:          customers ?? this.customers,
        fromDate:           fromDate  ?? this.fromDate,
        toDate:             toDate    ?? this.toDate,
        selectedCustomerId: clearCustomer
            ? null : (selectedCustomerId ?? this.selectedCustomerId),
        isLoading:          isLoading ?? this.isLoading,
        errorMessage:       errorMessage,
      );
}

class SaleSummaryNotifier extends StateNotifier<SaleSummaryState> {
  final SaleSummaryDatasource _ds;

  SaleSummaryNotifier({required String branchId})
      : _ds = SaleSummaryDatasource(branchId: branchId),
        super(SaleSummaryState()) {
    _loadCustomers();
    load();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _ds.getCustomers();
      state = state.copyWith(customers: customers);
    } catch (_) {}
  }

  /// Every invoice for the current date range / customer — for export.
  Future<List<SummaryInvoice>> fetchAllForExport() => _ds.getAllInvoices(
        fromDate:   state.fromDate,
        toDate:     state.toDate,
        customerId: state.selectedCustomerId,
      );


  Future<void> load() async {
    state = state.copyWith(
      isLoading:  true,
      pagination: const BranchReportPageState(),
    );
    try {
      final results = await Future.wait([
        _ds.getSummary(
          fromDate:   state.fromDate,
          toDate:     state.toDate,
          customerId: state.selectedCustomerId,
        ),
        _ds.getInvoicesPage(
          fromDate:   state.fromDate,
          toDate:     state.toDate,
          customerId: state.selectedCustomerId,
          page:       0,
        ),
      ]);
      final paged = results[1] as PagedSummaryInvoices;
      state = state.copyWith(
        summary:    results[0] as SaleSummary,
        invoices:   paged.invoices,
        isLoading:  false,
        pagination: BranchReportPageState(page: 0, hasNextPage: paged.hasNextPage),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  Future<void> _loadPage(int page) async {
    state = state.copyWith(
      pagination: state.pagination.copyWith(isLoadingPage: true),
    );
    try {
      final paged = await _ds.getInvoicesPage(
        fromDate:   state.fromDate,
        toDate:     state.toDate,
        customerId: state.selectedCustomerId,
        page:       page,
      );
      state = state.copyWith(
        invoices:   paged.invoices,
        pagination: BranchReportPageState(page: page, hasNextPage: paged.hasNextPage),
      );
    } catch (e) {
      state = state.copyWith(
        pagination:   state.pagination.copyWith(isLoadingPage: false),
        errorMessage: 'Load error: $e',
      );
    }
  }

  Future<void> nextPage() async {
    if (!state.pagination.hasNextPage || state.pagination.isLoadingPage) return;
    await _loadPage(state.pagination.page + 1);
  }

  Future<void> previousPage() async {
    if (!state.pagination.hasPreviousPage || state.pagination.isLoadingPage) return;
    await _loadPage(state.pagination.page - 1);
  }

  void setFromDate(DateTime d) {
    state = state.copyWith(fromDate: d);
    load();
  }

  void setToDate(DateTime d) {
    state = state.copyWith(toDate: d);
    load();
  }

  void setCustomer(String? id) {
    state = state.copyWith(selectedCustomerId: id, clearCustomer: id == null);
    load();
  }

  void setToday() {
    state = state.copyWith(
      fromDate: SaleSummaryState.startOfToday(),
      toDate:   SaleSummaryState.endOfToday(),
    );
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final saleSummaryProvider = StateNotifierProvider.autoDispose
    .family<SaleSummaryNotifier, SaleSummaryState, String>(
  (ref, branchId) => SaleSummaryNotifier(branchId: branchId),
);
