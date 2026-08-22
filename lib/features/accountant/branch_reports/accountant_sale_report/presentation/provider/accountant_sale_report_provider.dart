import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/accountant_sale_report_datasource.dart';
import '../../data/model/accountant_sale_report_model.dart';

// ── State ─────────────────────────────────────────────────
class AccountantSaleReportState {
  final List<SaleReportInvoice> invoices;
  final SaleReportSummary       summary;
  final List<CustomerOption>    customers;
  final DateTime                fromDate;
  final DateTime                toDate;
  final String?                 selectedCustomerId;
  final String?                 selectedPaymentType;
  final BranchReportPageState   pagination;
  final bool                    isLoading;
  final bool                    isLoadingCustomers;
  final String?                 errorMessage;

  AccountantSaleReportState({
    this.invoices           = const [],
    this.summary            = const SaleReportSummary(
      totalInvoices: 0, totalSale: 0, totalQuantity: 0, totalDiscount: 0,
    ),
    this.customers          = const [],
    DateTime?               fromDate,
    DateTime?               toDate,
    this.selectedCustomerId,
    this.selectedPaymentType,
    this.pagination          = const BranchReportPageState(),
    this.isLoading          = false,
    this.isLoadingCustomers = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _startOfToday(),
        toDate   = toDate   ?? _endOfToday();

  static DateTime _startOfToday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _endOfToday() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, 23, 59, 59);
  }

  AccountantSaleReportState copyWith({
    List<SaleReportInvoice>? invoices,
    SaleReportSummary?       summary,
    List<CustomerOption>?    customers,
    DateTime?                fromDate,
    DateTime?                toDate,
    String?                  selectedCustomerId,
    bool                     clearCustomer = false,
    String?                  selectedPaymentType,
    bool                     clearPayment  = false,
    BranchReportPageState?   pagination,
    bool?                    isLoading,
    bool?                    isLoadingCustomers,
    String?                  errorMessage,
  }) =>
      AccountantSaleReportState(
        invoices:            invoices            ?? this.invoices,
        summary:             summary             ?? this.summary,
        customers:           customers           ?? this.customers,
        fromDate:            fromDate            ?? this.fromDate,
        toDate:              toDate              ?? this.toDate,
        selectedCustomerId:  clearCustomer
            ? null : (selectedCustomerId  ?? this.selectedCustomerId),
        selectedPaymentType: clearPayment
            ? null : (selectedPaymentType ?? this.selectedPaymentType),
        pagination:          pagination          ?? this.pagination,
        isLoading:           isLoading           ?? this.isLoading,
        isLoadingCustomers:  isLoadingCustomers  ?? this.isLoadingCustomers,
        errorMessage:        errorMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────
class AccountantSaleReportNotifier
    extends StateNotifier<AccountantSaleReportState> {
  final AccountantSaleReportDatasource _ds;

  AccountantSaleReportNotifier({required String branchId})
      : _ds = AccountantSaleReportDatasource(branchId: branchId),
        super(AccountantSaleReportState()) {
    _loadCustomers();
    load();
  }

  // ── Load customers ────────────────────────────────────────
  Future<void> _loadCustomers() async {
    try {
      final customers = await _ds.getCustomers();
      state = state.copyWith(customers: customers);
    } catch (e) {
      print('❌ Customers error: $e');
    }
  }

  // ── Load report — resets to page 0 and refreshes the summary ───────────
  Future<void> load() async {
    state = state.copyWith(
      isLoading:  true,
      pagination: const BranchReportPageState(),
    );
    try {
      final results = await Future.wait([
        _ds.getReportPage(
          fromDate:    state.fromDate,
          toDate:      state.toDate,
          customerId:  state.selectedCustomerId,
          paymentType: state.selectedPaymentType,
          page:        0,
        ),
        _ds.getReportSummary(
          fromDate:    state.fromDate,
          toDate:      state.toDate,
          customerId:  state.selectedCustomerId,
          paymentType: state.selectedPaymentType,
        ),
      ]);
      final paged   = results[0] as PagedSaleReport;
      final summary = results[1] as SaleReportSummary;
      state = state.copyWith(
        invoices:   paged.invoices,
        summary:    summary,
        isLoading:  false,
        pagination: BranchReportPageState(
            page: 0, hasNextPage: paged.hasNextPage),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Load error: $e',
      );
    }
  }

  // ── Page navigation — only re-fetches the invoice list, not the
  //    date-range-wide summary totals ─────────────────────────────────────
  Future<void> _loadPage(int page) async {
    state = state.copyWith(
      pagination: state.pagination.copyWith(isLoadingPage: true),
    );
    try {
      final paged = await _ds.getReportPage(
        fromDate:    state.fromDate,
        toDate:      state.toDate,
        customerId:  state.selectedCustomerId,
        paymentType: state.selectedPaymentType,
        page:        page,
      );
      state = state.copyWith(
        invoices:   paged.invoices,
        pagination: BranchReportPageState(
          page:          page,
          hasNextPage:   paged.hasNextPage,
          isLoadingPage: false,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        pagination:   state.pagination.copyWith(isLoadingPage: false),
        errorMessage: 'Load error: $e',
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

  void setFromDate(DateTime d) {
    state = state.copyWith(fromDate: d);
    load();
  }

  void setToDate(DateTime d) {
    state = state.copyWith(toDate: d);
    load();
  }

  void setCustomer(String? id) {
    state = state.copyWith(
      selectedCustomerId: id,
      clearCustomer:      id == null,
    );
    load();
  }

  void setPaymentType(String? type) {
    state = state.copyWith(
      selectedPaymentType: type,
      clearPayment:        type == null,
    );
    load();
  }

  void setToday() {
    state = state.copyWith(
      fromDate: AccountantSaleReportState._startOfToday(),
      toDate:   AccountantSaleReportState._endOfToday(),
    );
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ── Provider — scoped by branchId ─────────────────────────
final accountantSaleReportProvider = StateNotifierProvider.autoDispose
    .family<AccountantSaleReportNotifier, AccountantSaleReportState, String>(
      (ref, branchId) => AccountantSaleReportNotifier(branchId: branchId),
);