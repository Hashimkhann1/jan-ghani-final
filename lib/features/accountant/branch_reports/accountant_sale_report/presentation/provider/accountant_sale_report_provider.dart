import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/accountant_sale_report_datasource.dart';
import '../../data/model/accountant_sale_report_model.dart';

// ── State ─────────────────────────────────────────────────
class AccountantSaleReportState {
  final List<SaleReportInvoice> invoices;
  final List<CustomerOption>    customers;
  final DateTime                fromDate;
  final DateTime                toDate;
  final String?                 selectedCustomerId;
  final String?                 selectedPaymentType;
  final bool                    isLoading;
  final bool                    isLoadingCustomers;
  final String?                 errorMessage;

  AccountantSaleReportState({
    this.invoices           = const [],
    this.customers          = const [],
    DateTime?               fromDate,
    DateTime?               toDate,
    this.selectedCustomerId,
    this.selectedPaymentType,
    this.isLoading          = false,
    this.isLoadingCustomers = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  SaleReportSummary get summary => SaleReportSummary(
    totalInvoices: invoices.length,
    totalSale:     invoices.fold(0, (s, i) => s + i.grandTotal),
    totalQuantity: invoices.fold(0, (s, i) => s + i.totalQuantity),
    totalDiscount: invoices.fold(0, (s, i) => s + i.totalDiscount),
  );

  AccountantSaleReportState copyWith({
    List<SaleReportInvoice>? invoices,
    List<CustomerOption>?    customers,
    DateTime?                fromDate,
    DateTime?                toDate,
    String?                  selectedCustomerId,
    bool                     clearCustomer = false,
    String?                  selectedPaymentType,
    bool                     clearPayment  = false,
    bool?                    isLoading,
    bool?                    isLoadingCustomers,
    String?                  errorMessage,
  }) =>
      AccountantSaleReportState(
        invoices:            invoices            ?? this.invoices,
        customers:           customers           ?? this.customers,
        fromDate:            fromDate            ?? this.fromDate,
        toDate:              toDate              ?? this.toDate,
        selectedCustomerId:  clearCustomer
            ? null : (selectedCustomerId  ?? this.selectedCustomerId),
        selectedPaymentType: clearPayment
            ? null : (selectedPaymentType ?? this.selectedPaymentType),
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

  // ── Load report ───────────────────────────────────────────
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final invoices = await _ds.getReport(
        fromDate:    state.fromDate,
        toDate:      state.toDate,
        customerId:  state.selectedCustomerId,
        paymentType: state.selectedPaymentType,
      );
      state = state.copyWith(invoices: invoices, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: 'Load error: $e',
      );
    }
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
    final today = AccountantSaleReportState._today();
    state = state.copyWith(fromDate: today, toDate: today);
    load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ── Provider — branchId ke sath ───────────────────────────
final accountantSaleReportProvider = StateNotifierProvider.autoDispose
    .family<AccountantSaleReportNotifier, AccountantSaleReportState, String>(
      (ref, branchId) => AccountantSaleReportNotifier(branchId: branchId),
);