import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/sale_return_report_datasource.dart';
import '../../data/model/sale_return_report_model.dart';

// ═══════════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════════

class AccountantSaleReturnState {
  final List<SaleReturnInvoice> returns;
  final SaleReturnSummary       summary;
  final List<CustomerOption>    customers;
  final DateTime                fromDate;
  final DateTime                toDate;
  final String?                 selectedCustomerId;
  final String?                 selectedRefundType;
  final BranchReportPageState   pagination;
  final bool                    isLoading;
  final bool                    isLoadingCustomers;
  final String?                 errorMessage;

  AccountantSaleReturnState({
    this.returns            = const [],
    this.summary            = const SaleReturnSummary(
      totalReturns: 0, totalAmount: 0, totalQuantity: 0, totalDiscount: 0,
    ),
    this.customers          = const [],
    DateTime?               fromDate,
    DateTime?               toDate,
    this.selectedCustomerId,
    this.selectedRefundType,
    this.pagination          = const BranchReportPageState(),
    this.isLoading          = false,
    this.isLoadingCustomers = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  AccountantSaleReturnState copyWith({
    List<SaleReturnInvoice>? returns,
    SaleReturnSummary?       summary,
    List<CustomerOption>?    customers,
    DateTime?                fromDate,
    DateTime?                toDate,
    String?                  selectedCustomerId,
    bool                     clearCustomer = false,
    String?                  selectedRefundType,
    bool                     clearRefund   = false,
    BranchReportPageState?   pagination,
    bool?                    isLoading,
    bool?                    isLoadingCustomers,
    String?                  errorMessage,
  }) =>
      AccountantSaleReturnState(
        returns:            returns             ?? this.returns,
        summary:            summary             ?? this.summary,
        customers:          customers           ?? this.customers,
        fromDate:           fromDate            ?? this.fromDate,
        toDate:             toDate              ?? this.toDate,
        selectedCustomerId: clearCustomer
            ? null
            : (selectedCustomerId  ?? this.selectedCustomerId),
        selectedRefundType: clearRefund
            ? null
            : (selectedRefundType  ?? this.selectedRefundType),
        pagination:         pagination          ?? this.pagination,
        isLoading:          isLoading           ?? this.isLoading,
        isLoadingCustomers: isLoadingCustomers  ?? this.isLoadingCustomers,
        errorMessage:       errorMessage,
      );
}

// ═══════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════

class AccountantSaleReturnNotifier
    extends StateNotifier<AccountantSaleReturnState> {
  final AccountantSaleReturnDatasource _ds;

  AccountantSaleReturnNotifier({required String branchId})
      : _ds = AccountantSaleReturnDatasource(branchId: branchId),
        super(AccountantSaleReturnState()) {
    _loadCustomers();
    load();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _ds.getCustomers();
      state = state.copyWith(customers: customers);
    } catch (e) {
      print('❌ Customers error: $e');
    }
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading:  true,
      pagination: const BranchReportPageState(),
    );
    try {
      final results = await Future.wait([
        _ds.getReportPage(
          fromDate:   state.fromDate,
          toDate:     state.toDate,
          customerId: state.selectedCustomerId,
          refundType: state.selectedRefundType,
          page:       0,
        ),
        _ds.getReportSummary(
          fromDate:   state.fromDate,
          toDate:     state.toDate,
          customerId: state.selectedCustomerId,
          refundType: state.selectedRefundType,
        ),
      ]);
      final paged   = results[0] as PagedSaleReturnReport;
      final summary = results[1] as SaleReturnSummary;
      state = state.copyWith(
        returns:    paged.returns,
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

  // ── Page navigation — only re-fetches the return list, not the
  //    date-range-wide summary totals ─────────────────────────────────────
  Future<void> _loadPage(int page) async {
    state = state.copyWith(
      pagination: state.pagination.copyWith(isLoadingPage: true),
    );
    try {
      final paged = await _ds.getReportPage(
        fromDate:   state.fromDate,
        toDate:     state.toDate,
        customerId: state.selectedCustomerId,
        refundType: state.selectedRefundType,
        page:       page,
      );
      state = state.copyWith(
        returns:    paged.returns,
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

  void setRefundType(String? type) {
    state = state.copyWith(
      selectedRefundType: type,
      clearRefund:        type == null,
    );
    load();
  }

  void setToday() {
    final today = AccountantSaleReturnState._today();
    state = state.copyWith(fromDate: today, toDate: today);
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ═══════════════════════════════════════════════════════════
//  PROVIDER — family with branchId
// ═══════════════════════════════════════════════════════════

final accountantSaleReturnProvider = StateNotifierProvider.autoDispose
    .family<AccountantSaleReturnNotifier, AccountantSaleReturnState, String>(
      (ref, branchId) => AccountantSaleReturnNotifier(branchId: branchId),
);