import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/customer_report_datasource.dart';
import '../../data/model/customer_invoice_model.dart';
import '../../data/model/customer_return_model.dart';
import '../../data/model/specific_customer_ledger_model.dart';

// ═════════════════════════════════════════════════════════════
// 0. ARGS
// ═════════════════════════════════════════════════════════════

class CustomerReportArgs {
  final String customerId;
  final String customerName;

  const CustomerReportArgs({
    required this.customerId,
    required this.customerName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is CustomerReportArgs && other.customerId == customerId);

  @override
  int get hashCode => customerId.hashCode;
}

// ─── Shared date helpers ──────────────────────────────────────
DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Current month ka 1st day — default "from" date
DateTime _monthStart() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, 1);
}

// ═════════════════════════════════════════════════════════════
// 1. INVOICE PROVIDER
// ═════════════════════════════════════════════════════════════

class CustomerReportInvoiceState {
  final List<CustomerInvoiceModel> invoices;
  final String customerId;
  final String customerName;
  final DateTime fromDate;
  final DateTime toDate;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  CustomerReportInvoiceState({
    this.invoices = const [],
    required this.customerId,
    required this.customerName,
    DateTime? fromDate,
    DateTime? toDate,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _monthStart(), // ← current month
        toDate = toDate ?? _today();

  List<CustomerInvoiceModel> get filtered {
    if (searchQuery.isEmpty) return invoices;
    final q = searchQuery.toLowerCase();
    return invoices.where((inv) {
      if (inv.invoiceNo.toLowerCase().contains(q)) return true;
      if (inv.paymentType.toLowerCase().contains(q)) return true;
      if (inv.items.any((i) => i.productName.toLowerCase().contains(q))) return true;
      return false;
    }).toList();
  }

  double get totalSale => filtered.fold(0, (s, i) => s + i.grandTotal);
  double get totalDiscount => filtered.fold(0, (s, i) => s + i.totalDiscount);
  double get totalProfit => filtered.fold(0.0, (s, i) => s + i.totalProfit);
  double get cashSale => filtered
      .where((i) => i.paymentType.contains('cash'))
      .fold(0, (s, i) => s + i.grandTotal);
  double get creditSale => filtered
      .where((i) => i.paymentType.contains('credit'))
      .fold(0, (s, i) => s + i.grandTotal);
  int get invoiceCount => filtered.length;

  CustomerReportInvoiceState copyWith({
    List<CustomerInvoiceModel>? invoices,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) =>
      CustomerReportInvoiceState(
        invoices: invoices ?? this.invoices,
        customerId: customerId,
        customerName: customerName,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        searchQuery: searchQuery ?? this.searchQuery,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class CustomerReportInvoiceNotifier
    extends StateNotifier<CustomerReportInvoiceState> {
  final CustomerReportDatasource _ds;

  CustomerReportInvoiceNotifier({
    required String customerId,
    required String customerName,
  })  : _ds = CustomerReportDatasource(),
        super(CustomerReportInvoiceState(
        customerId: customerId,
        customerName: customerName,
        // current month default
        fromDate: _monthStart(),
        toDate: _today(),
      )) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final invoices = await _ds.fetchInvoicesPublic(
        customerId: state.customerId,
        fromDate: state.fromDate,
        toDate: state.toDate,
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

  void setToday() => setDateRange(_today(), _today());

  void setThisMonth() => setDateRange(_monthStart(), _today());

  void onSearchChanged(String q) => state = state.copyWith(searchQuery: q);
}

final customerReportInvoiceProvider = StateNotifierProvider.family<
    CustomerReportInvoiceNotifier,
    CustomerReportInvoiceState,
    CustomerReportArgs>(
      (ref, args) => CustomerReportInvoiceNotifier(
    customerId: args.customerId,
    customerName: args.customerName,
  ),
);

// ═════════════════════════════════════════════════════════════
// 2. RETURN PROVIDER
// ═════════════════════════════════════════════════════════════

class CustomerReportReturnState {
  final List<CustomerReturnInvoice> returns;
  final String customerId;
  final String customerName;
  final DateTime fromDate;
  final DateTime toDate;
  final bool isLoading;
  final String? errorMessage;

  CustomerReportReturnState({
    this.returns = const [],
    required this.customerId,
    required this.customerName,
    DateTime? fromDate,
    DateTime? toDate,
    this.isLoading = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _monthStart(), // ← current month
        toDate = toDate ?? _today();

  CustomerReturnSummary get summary => CustomerReturnSummary(
    totalReturns: returns.length,
    totalAmount: returns.fold(0, (s, r) => s + r.grandTotal),
    totalQuantity: returns.fold(0, (s, r) => s + r.totalQuantity),
    totalDiscount: returns.fold(0, (s, r) => s + r.totalDiscount),
  );

  CustomerReportReturnState copyWith({
    List<CustomerReturnInvoice>? returns,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isLoading,
    String? errorMessage,
  }) =>
      CustomerReportReturnState(
        returns: returns ?? this.returns,
        customerId: customerId,
        customerName: customerName,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class CustomerReportReturnNotifier
    extends StateNotifier<CustomerReportReturnState> {
  final CustomerReportDatasource _ds;

  CustomerReportReturnNotifier({
    required String customerId,
    required String customerName,
  })  : _ds = CustomerReportDatasource(),
        super(CustomerReportReturnState(
        customerId: customerId,
        customerName: customerName,
        fromDate: _monthStart(),
        toDate: _today(),
      )) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final returns = await _ds.fetchReturnsPublic(
        customerId: state.customerId,
        fromDate: state.fromDate,
        toDate: state.toDate,
      );
      state = state.copyWith(returns: returns, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
    load();
  }

  void setFromDate(DateTime d) => setDateRange(d, state.toDate);
  void setToDate(DateTime d) => setDateRange(state.fromDate, d);
  void setToday() => setDateRange(_today(), _today());
  void setThisMonth() => setDateRange(_monthStart(), _today());
}

final customerReportReturnProvider = StateNotifierProvider.family<
    CustomerReportReturnNotifier,
    CustomerReportReturnState,
    CustomerReportArgs>(
      (ref, args) => CustomerReportReturnNotifier(
    customerId: args.customerId,
    customerName: args.customerName,
  ),
);

// ═════════════════════════════════════════════════════════════
// 3. LEDGER PROVIDER
// ═════════════════════════════════════════════════════════════

class CustomerReportLedgerState {
  final List<SpecificCustomerLedgerModel> ledger;
  final String customerId;
  final String customerName;
  final DateTime fromDate;
  final DateTime toDate;
  final bool isLoading;
  final String? errorMessage;

  CustomerReportLedgerState({
    this.ledger = const [],
    required this.customerId,
    required this.customerName,
    DateTime? fromDate,
    DateTime? toDate,
    this.isLoading = false,
    this.errorMessage,
  })  : fromDate = fromDate ?? _monthStart(), // ← current month
        toDate = toDate ?? _today();

  double get totalPaid => ledger.fold(0, (s, r) => s + r.payAmount);
  double get currentBalance => ledger.isEmpty ? 0 : ledger.first.newAmount;

  CustomerReportLedgerState copyWith({
    List<SpecificCustomerLedgerModel>? ledger,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isLoading,
    String? errorMessage,
  }) =>
      CustomerReportLedgerState(
        ledger: ledger ?? this.ledger,
        customerId: customerId,
        customerName: customerName,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class CustomerReportLedgerNotifier
    extends StateNotifier<CustomerReportLedgerState> {
  final CustomerReportDatasource _ds;

  CustomerReportLedgerNotifier({
    required String customerId,
    required String customerName,
  })  : _ds = CustomerReportDatasource(),
        super(CustomerReportLedgerState(
        customerId: customerId,
        customerName: customerName,
        fromDate: _monthStart(),
        toDate: _today(),
      )) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final ledger = await _ds.fetchLedgerPublic(
        customerId: state.customerId,
        fromDate: state.fromDate,
        toDate: state.toDate,
      );
      state = state.copyWith(ledger: ledger, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
    load();
  }

  void setThisMonth() => setDateRange(_monthStart(), _today());
}

final customerReportLedgerProvider = StateNotifierProvider.family<
    CustomerReportLedgerNotifier,
    CustomerReportLedgerState,
    CustomerReportArgs>(
      (ref, args) => CustomerReportLedgerNotifier(
    customerId: args.customerId,
    customerName: args.customerName,
  ),
);