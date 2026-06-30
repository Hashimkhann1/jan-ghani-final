import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/sale_invoice_report_datasource.dart';
import '../../data/model/sale_invoice_report_model.dart';

// ── State ─────────────────────────────────────────────────────
class SaleInvoiceListState {
  final List<SaleInvoiceListModel> allInvoices;
  final List<CashierModel>         cashiers;
  final String?                    selectedCashierId;
  final String?                    selectedCustomerId;
  final String?                    selectedCustomerName;
  final DateTime fromDate;
  final DateTime toDate;
  final String   searchQuery;
  final bool     isLoading;
  final bool     isCashiersLoading;
  final String?  errorMessage;
  final String?  counterId;

  SaleInvoiceListState({
    this.allInvoices           = const [],
    this.cashiers              = const [],
    this.selectedCashierId,
    this.selectedCustomerId,
    this.selectedCustomerName,
    DateTime? fromDate,
    DateTime? toDate,
    this.searchQuery           = '',
    this.isLoading             = false,
    this.isCashiersLoading     = false,
    this.errorMessage,
    this.counterId,
  })  : fromDate = fromDate ?? _todayStart(),
        toDate   = toDate   ?? _todayEnd();

  static DateTime _todayStart() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, 0, 0, 0);
  }

  static DateTime _todayEnd() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, 23, 59, 59);
  }

  // ── Filtered Invoices ─────────────────────────────────────
  List<SaleInvoiceListModel> get filteredInvoices {
    var list = allInvoices;

    if (selectedCustomerId != null) {
      list = list.where((inv) => inv.customerId == selectedCustomerId).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((inv) {
        if (inv.invoiceNo.toLowerCase().contains(q))                        return true;
        if (inv.customerName?.toLowerCase().contains(q)  ?? false)         return true;
        if (inv.cashierName?.toLowerCase().contains(q)   ?? false)         return true;
        if (inv.paymentType.toLowerCase().contains(q))                     return true;
        if (inv.items.any((i) => i.productName.toLowerCase().contains(q))) return true;
        return false;
      }).toList();
    }

    return list;
  }

  // ── Stats ─────────────────────────────────────────────────
  double get totalGrand    => filteredInvoices.fold(0, (s, i) => s + i.grandTotal);
  double get totalDiscount => filteredInvoices.fold(0, (s, i) => s + i.totalDiscount);
  int    get totalCount    => filteredInvoices.length;

  bool   get isCustomerSelected    => selectedCustomerId != null;
  double get customerTotalSale     => filteredInvoices.fold(0, (s, i) => s + i.grandTotal);
  double get customerCashSale      => filteredInvoices
      .where((i) => i.paymentType.contains('cash'))
      .fold(0, (s, i) => s + i.grandTotal);
  double get customerCreditSale    => filteredInvoices
      .where((i) => i.paymentType.contains('credit'))
      .fold(0, (s, i) => s + i.grandTotal);
  double get customerTotalDiscount => filteredInvoices.fold(0, (s, i) => s + i.totalDiscount);
  int    get customerInvoiceCount  => filteredInvoices.length;

  // ── CopyWith ──────────────────────────────────────────────
  SaleInvoiceListState copyWith({
    List<SaleInvoiceListModel>? allInvoices,
    List<CashierModel>?         cashiers,
    String?                     selectedCashierId,
    bool                        clearSelectedCashier      = false,
    String?                     selectedCustomerId,
    bool                        clearSelectedCustomer     = false,
    String?                     selectedCustomerName,
    bool                        clearSelectedCustomerName = false,
    DateTime?                   fromDate,
    DateTime?                   toDate,
    String?                     searchQuery,
    bool?                       isLoading,
    bool?                       isCashiersLoading,
    String?                     errorMessage,
    String?                     counterId,
    bool                        clearCounterId = false,
  }) =>
      SaleInvoiceListState(
        allInvoices:          allInvoices          ?? this.allInvoices,
        cashiers:             cashiers             ?? this.cashiers,
        selectedCashierId:    clearSelectedCashier
            ? null
            : (selectedCashierId  ?? this.selectedCashierId),
        selectedCustomerId:   clearSelectedCustomer
            ? null
            : (selectedCustomerId ?? this.selectedCustomerId),
        selectedCustomerName: clearSelectedCustomerName
            ? null
            : (selectedCustomerName ?? this.selectedCustomerName),
        fromDate:             fromDate             ?? this.fromDate,
        toDate:               toDate               ?? this.toDate,
        searchQuery:          searchQuery          ?? this.searchQuery,
        isLoading:            isLoading            ?? this.isLoading,
        isCashiersLoading:    isCashiersLoading    ?? this.isCashiersLoading,
        errorMessage:         errorMessage,
        counterId:            clearCounterId
            ? null
            : (counterId ?? this.counterId),
      );
}

// ── Notifier ──────────────────────────────────────────────────
class SaleInvoiceListNotifier extends StateNotifier<SaleInvoiceListState> {
  final SaleInvoiceListDatasource _ds;
  final Ref _ref;

  SaleInvoiceListNotifier(this._ref, {String? counterId})
      : _ds = SaleInvoiceListDatasource(),
        super(SaleInvoiceListState(counterId: counterId)) {
    _init();
  }

  String get _storeId   => _ref.read(authProvider).storeId;
  bool   get _isManager => _ref.read(authProvider).user?.role == 'store_manager';

  Future<void> _init() async {
    if (_isManager) await _loadCashiers();
    await load();
  }

  Future<void> _loadCashiers() async {
    state = state.copyWith(isCashiersLoading: true);
    try {
      final list = await _ds.getCashiers(storeId: _storeId);
      state = state.copyWith(cashiers: list, isCashiersLoading: false);
    } catch (e) {
      state = state.copyWith(isCashiersLoading: false);
    }
  }

  // ── Ab Manager aur Cashier dono ko ALL invoices dikhengi.
  //    selectedCashierId sirf manual filter dropdown ke liye hai.
  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final invoices = await _ds.getAll(
        storeId:   _storeId,
        fromDate:  state.fromDate,
        toDate:    state.toDate,
        counterId: state.counterId,
        userId:    state.selectedCashierId,
      );
      state = state.copyWith(allInvoices: invoices, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
    load();
  }

  void setToday() {
    setDateRange(
      SaleInvoiceListState._todayStart(),
      SaleInvoiceListState._todayEnd(),
    );
  }

  void setCounter(String? counterId) {
    state = counterId != null
        ? state.copyWith(counterId: counterId)
        : state.copyWith(clearCounterId: true);
    load();
  }

  void selectCashier(String? cashierId) {
    state = cashierId != null
        ? state.copyWith(selectedCashierId: cashierId)
        : state.copyWith(clearSelectedCashier: true);
    load();
  }

  void selectCustomer(String? customerId, String? customerName) {
    if (customerId == null) {
      state = state.copyWith(
        clearSelectedCustomer:     true,
        clearSelectedCustomerName: true,
      );
    } else {
      state = state.copyWith(
        selectedCustomerId:   customerId,
        selectedCustomerName: customerName,
      );
    }
  }

  void onSearchChanged(String q) => state = state.copyWith(searchQuery: q);
  void clearError()               => state = state.copyWith(errorMessage: null);
}

// ── Providers ─────────────────────────────────────────────────
final saleInvoiceListProvider =
StateNotifierProvider<SaleInvoiceListNotifier, SaleInvoiceListState>(
      (ref) => SaleInvoiceListNotifier(ref),
);

final saleInvoiceByCounterProvider = StateNotifierProvider.family
<SaleInvoiceListNotifier, SaleInvoiceListState, String>(
      (ref, counterId) => SaleInvoiceListNotifier(ref, counterId: counterId),
);