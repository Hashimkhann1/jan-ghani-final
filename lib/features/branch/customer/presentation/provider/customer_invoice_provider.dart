// customer_invoice_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/customer_invoice_datasource.dart';
import '../../data/model/customer_invoice_model.dart';

class CustomerInvoiceState {
  final List<CustomerInvoiceModel> invoices;
  final String   customerId;
  final String   customerName;
  final DateTime fromDate;
  final DateTime toDate;
  final String   searchQuery;
  final bool     isLoading;
  final String?  errorMessage;

  CustomerInvoiceState({
    this.invoices     = const [],
    required this.customerId,
    required this.customerName,
    DateTime? fromDate,
    DateTime? toDate,
    this.searchQuery  = '',
    this.isLoading    = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  List<CustomerInvoiceModel> get filteredInvoices {
    if (searchQuery.isEmpty) return invoices;
    final q = searchQuery.toLowerCase();
    return invoices.where((inv) {
      if (inv.invoiceNo.toLowerCase().contains(q))                        return true;
      if (inv.paymentType.toLowerCase().contains(q))                      return true;
      if (inv.items.any((i) => i.productName.toLowerCase().contains(q)))  return true;
      return false;
    }).toList();
  }

  double get totalSale     => filteredInvoices.fold(0, (s, i) => s + i.grandTotal);
  double get totalDiscount => filteredInvoices.fold(0, (s, i) => s + i.totalDiscount);
  double get cashSale      => filteredInvoices
      .where((i) => i.paymentType.contains('cash'))
      .fold(0, (s, i) => s + i.grandTotal);
  double get creditSale    => filteredInvoices
      .where((i) => i.paymentType.contains('credit'))
      .fold(0, (s, i) => s + i.grandTotal);
  int    get invoiceCount  => filteredInvoices.length;

  CustomerInvoiceState copyWith({
    List<CustomerInvoiceModel>? invoices,
    DateTime?                   fromDate,
    DateTime?                   toDate,
    String?                     searchQuery,
    bool?                       isLoading,
    String?                     errorMessage,
  }) => CustomerInvoiceState(
    invoices:     invoices     ?? this.invoices,
    customerId:   customerId,
    customerName: customerName,
    fromDate:     fromDate     ?? this.fromDate,
    toDate:       toDate       ?? this.toDate,
    searchQuery:  searchQuery  ?? this.searchQuery,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

class CustomerInvoiceNotifier extends StateNotifier<CustomerInvoiceState> {
  final CustomerInvoiceDatasource _ds;
  final Ref _ref;

  CustomerInvoiceNotifier(this._ref, {
    required String customerId,
    required String customerName,
  })  : _ds = CustomerInvoiceDatasource(),
        super(CustomerInvoiceState(
        customerId:   customerId,
        customerName: customerName,
      )) {
    load();
  }

  String get _storeId => _ref.read(authProvider).storeId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final invoices = await _ds.getByCustomer(
        storeId:    _storeId,
        customerId: state.customerId,
        fromDate:   state.fromDate,
        toDate:     state.toDate,
      );
      state = state.copyWith(invoices: invoices, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
    load();
  }

  void setToday() {
    final today = CustomerInvoiceState._today();
    setDateRange(today, today);
  }

  void onSearchChanged(String q) => state = state.copyWith(searchQuery: q);
  void clearError()               => state = state.copyWith(errorMessage: null);
}

final customerInvoiceProvider = StateNotifierProvider.family
<CustomerInvoiceNotifier,
    CustomerInvoiceState,
    ({String customerId, String customerName})>(
      (ref, args) => CustomerInvoiceNotifier(
    ref,
    customerId:   args.customerId,
    customerName: args.customerName,
  ),
);