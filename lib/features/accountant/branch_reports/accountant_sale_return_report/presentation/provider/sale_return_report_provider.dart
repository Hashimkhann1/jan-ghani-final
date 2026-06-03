import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/sale_return_report_datasource.dart';
import '../../data/model/sale_return_report_model.dart';

// ═══════════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════════

class AccountantSaleReturnState {
  final List<SaleReturnInvoice> returns;
  final List<CustomerOption>    customers;
  final DateTime                fromDate;
  final DateTime                toDate;
  final String?                 selectedCustomerId;
  final String?                 selectedRefundType;
  final bool                    isLoading;
  final bool                    isLoadingCustomers;
  final String?                 errorMessage;

  AccountantSaleReturnState({
    this.returns            = const [],
    this.customers          = const [],
    DateTime?               fromDate,
    DateTime?               toDate,
    this.selectedCustomerId,
    this.selectedRefundType,
    this.isLoading          = false,
    this.isLoadingCustomers = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  SaleReturnSummary get summary => SaleReturnSummary(
    totalReturns:  returns.length,
    totalAmount:   returns.fold(0, (s, r) => s + r.grandTotal),
    totalQuantity: returns.fold(0, (s, r) => s + r.totalQuantity),
    totalDiscount: returns.fold(0, (s, r) => s + r.totalDiscount),
  );

  AccountantSaleReturnState copyWith({
    List<SaleReturnInvoice>? returns,
    List<CustomerOption>?    customers,
    DateTime?                fromDate,
    DateTime?                toDate,
    String?                  selectedCustomerId,
    bool                     clearCustomer = false,
    String?                  selectedRefundType,
    bool                     clearRefund   = false,
    bool?                    isLoading,
    bool?                    isLoadingCustomers,
    String?                  errorMessage,
  }) =>
      AccountantSaleReturnState(
        returns:            returns             ?? this.returns,
        customers:          customers           ?? this.customers,
        fromDate:           fromDate            ?? this.fromDate,
        toDate:             toDate              ?? this.toDate,
        selectedCustomerId: clearCustomer
            ? null
            : (selectedCustomerId  ?? this.selectedCustomerId),
        selectedRefundType: clearRefund
            ? null
            : (selectedRefundType  ?? this.selectedRefundType),
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
    state = state.copyWith(isLoading: true);
    try {
      final returns = await _ds.getReport(
        fromDate:   state.fromDate,
        toDate:     state.toDate,
        customerId: state.selectedCustomerId,
        refundType: state.selectedRefundType,
      );
      state = state.copyWith(returns: returns, isLoading: false);
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