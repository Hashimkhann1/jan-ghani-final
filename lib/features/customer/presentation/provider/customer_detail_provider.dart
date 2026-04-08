import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/mock/sale_invoice_mock.dart';
import '../../data/mock/sale_return_mock.dart';
import '../../data/model/sale_invoice_model.dart';
import '../../data/model/sale_return_model.dart';

class CustomerDetailState {
  final String    customerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String    invoiceFilter;
  final String    returnFilter;
  final String    ledgerFilter;
  final String    invoiceSearch;
  final String    returnSearch;

  const CustomerDetailState({
    required this.customerId,
    this.startDate,
    this.endDate,
    this.invoiceFilter = 'all',
    this.returnFilter  = 'all',
    this.ledgerFilter  = 'all',
    this.invoiceSearch = '',
    this.returnSearch  = '',
  });

  CustomerDetailState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool      clearStart = false,
    bool      clearEnd   = false,
    String?   invoiceFilter,
    String?   returnFilter,
    String?   ledgerFilter,
    String?   invoiceSearch,
    String?   returnSearch,
  }) {
    return CustomerDetailState(
      customerId:    customerId,
      startDate:     clearStart ? null : (startDate ?? this.startDate),
      endDate:       clearEnd   ? null : (endDate   ?? this.endDate),
      invoiceFilter: invoiceFilter ?? this.invoiceFilter,
      returnFilter:  returnFilter  ?? this.returnFilter,
      ledgerFilter:  ledgerFilter  ?? this.ledgerFilter,
      invoiceSearch: invoiceSearch ?? this.invoiceSearch,
      returnSearch:  returnSearch  ?? this.returnSearch,
    );
  }
}

class CustomerDetailNotifier extends StateNotifier<CustomerDetailState> {
  CustomerDetailNotifier(String customerId)
      : super(CustomerDetailState(customerId: customerId));

  void setStartDate(DateTime? d) =>
      state = d == null ? state.copyWith(clearStart: true) : state.copyWith(startDate: d);

  void setEndDate(DateTime? d) =>
      state = d == null ? state.copyWith(clearEnd: true) : state.copyWith(endDate: d);

  void setInvoiceFilter(String f) => state = state.copyWith(invoiceFilter: f);
  void setReturnFilter(String f)  => state = state.copyWith(returnFilter: f);
  void setLedgerFilter(String f)  => state = state.copyWith(ledgerFilter: f);
  void setInvoiceSearch(String q) => state = state.copyWith(invoiceSearch: q);
  void setReturnSearch(String q)  => state = state.copyWith(returnSearch: q);

  bool _inRange(DateTime date) {
    final s = state.startDate;
    final e = state.endDate;
    if (s != null && date.isBefore(s)) return false;
    if (e != null && date.isAfter(DateTime(e.year, e.month, e.day, 23, 59, 59))) return false;
    return true;
  }

  List<SaleInvoiceModel> get filteredInvoices {
    return saleInvoiceMockData.where((inv) {
      if (inv.customerId != state.customerId) return false;
      if (!_inRange(inv.date)) return false;
      if (state.invoiceFilter != 'all' && inv.status != state.invoiceFilter) return false;
      if (state.invoiceSearch.isNotEmpty &&
          !inv.invoiceNumber.toLowerCase().contains(state.invoiceSearch.toLowerCase()) &&
          !inv.productSummary.toLowerCase().contains(state.invoiceSearch.toLowerCase())) return false;
      return true;
    }).toList();
  }

  List<SaleReturnModel> get filteredReturns {
    return saleReturnMockData.where((ret) {
      if (ret.customerId != state.customerId) return false;
      if (!_inRange(ret.date)) return false;
      if (state.returnFilter != 'all' && ret.status != state.returnFilter) return false;
      if (state.returnSearch.isNotEmpty &&
          !ret.returnNumber.toLowerCase().contains(state.returnSearch.toLowerCase())) return false;
      return true;
    }).toList();
  }

  double get totalSale    => filteredInvoices.fold(0, (s, e) => s + e.totalAmount);
  double get totalReturn  => filteredReturns.fold(0, (s, e) => s + e.totalReturnAmount);
  double get totalPaid    => filteredInvoices.fold(0, (s, e) => s + e.paidAmount);
  double get totalDue     => filteredInvoices.fold(0, (s, e) => s + e.dueAmount);
}


final customerDetailProvider = StateNotifierProvider.family<CustomerDetailNotifier, CustomerDetailState, String>(
(ref, customerId) => CustomerDetailNotifier(customerId),
);