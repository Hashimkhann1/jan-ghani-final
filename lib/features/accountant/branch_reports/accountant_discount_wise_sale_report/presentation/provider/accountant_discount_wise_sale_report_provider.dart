import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/accountant_discount_wise_sale_report_datasource.dart';
import '../../data/model/accountant_discount_wise_sale_report_model.dart';

// ── State ─────────────────────────────────────────────────
class DiscountWiseSaleReportState {
  final List<DiscountReportProduct>          products;
  final List<DiscountReportCustomerOption>   customers;
  final DateTime                             fromDate;
  final DateTime                             toDate;
  final String?                              selectedCustomerId;
  final BranchReportPageState                pagination;
  final bool                                 isLoading;
  final bool                                 isLoadingCustomers;
  final String?                              errorMessage;

  DiscountWiseSaleReportState({
    this.products            = const [],
    this.customers           = const [],
    DateTime?                fromDate,
    DateTime?                toDate,
    this.selectedCustomerId,
    this.pagination          = const BranchReportPageState(),
    this.isLoading           = false,
    this.isLoadingCustomers  = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DiscountReportSummary get summary => DiscountReportSummary(
    totalProducts: products.length,
    totalInvoices: products
        .expand((p) => p.details.map((d) => d.invoiceId))
        .toSet()
        .length,
    totalQuantity: products.fold(0, (s, p) => s + p.totalQuantity),
    totalDiscountAmount: products.fold(0, (s, p) => s + p.totalDiscount),
  );

  // Products are already grouped/sorted from the full fetched dataset —
  // ranking by total discount needs every matching invoice, so pagination
  // here just windows the already-computed, already-sorted product list.
  List<DiscountReportProduct> get pagedProducts {
    final (start, end) = BranchReportPagination.range(pagination.page);
    if (start >= products.length) return const [];
    return products.sublist(
        start, end + 1 > products.length ? products.length : end + 1);
  }

  bool get hasNextPage =>
      (pagination.page + 1) * BranchReportPagination.pageSize <
      products.length;

  DiscountWiseSaleReportState copyWith({
    List<DiscountReportProduct>?        products,
    List<DiscountReportCustomerOption>? customers,
    DateTime?                           fromDate,
    DateTime?                           toDate,
    String?                             selectedCustomerId,
    bool                                clearCustomer = false,
    BranchReportPageState?              pagination,
    bool?                               isLoading,
    bool?                               isLoadingCustomers,
    String?                             errorMessage,
  }) =>
      DiscountWiseSaleReportState(
        products:            products            ?? this.products,
        customers:           customers           ?? this.customers,
        fromDate:            fromDate            ?? this.fromDate,
        toDate:              toDate              ?? this.toDate,
        selectedCustomerId:  clearCustomer
            ? null : (selectedCustomerId ?? this.selectedCustomerId),
        pagination:          pagination          ?? this.pagination,
        isLoading:           isLoading           ?? this.isLoading,
        isLoadingCustomers:  isLoadingCustomers  ?? this.isLoadingCustomers,
        errorMessage:        errorMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────
class DiscountWiseSaleReportNotifier
    extends StateNotifier<DiscountWiseSaleReportState> {
  final DiscountWiseSaleReportDatasource _ds;

  DiscountWiseSaleReportNotifier({required String branchId})
      : _ds = DiscountWiseSaleReportDatasource(branchId: branchId),
        super(DiscountWiseSaleReportState()) {
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
      final products = await _ds.getReport(
        fromDate:   state.fromDate,
        toDate:     state.toDate,
        customerId: state.selectedCustomerId,
      );
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Load error: $e',
      );
    }
  }

  // ── Page navigation — client-side windowing of `products`, no network
  //    call needed since the whole grouped/sorted set is already in memory
  void nextPage() {
    if (!state.hasNextPage) return;
    state = state.copyWith(
      pagination: state.pagination.copyWith(page: state.pagination.page + 1),
    );
  }

  void previousPage() {
    if (!state.pagination.hasPreviousPage) return;
    state = state.copyWith(
      pagination: state.pagination.copyWith(page: state.pagination.page - 1),
    );
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

  void setToday() {
    final today = DiscountWiseSaleReportState._today();
    state = state.copyWith(fromDate: today, toDate: today);
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ── Provider — branchId ke sath ───────────────────────────
final discountWiseSaleReportProvider = StateNotifierProvider.autoDispose
    .family<DiscountWiseSaleReportNotifier, DiscountWiseSaleReportState, String>(
      (ref, branchId) => DiscountWiseSaleReportNotifier(branchId: branchId),
);