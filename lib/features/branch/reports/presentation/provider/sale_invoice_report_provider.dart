import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/sale_invoice_report_datasource.dart';
import '../../data/model/sale_invoice_report_model.dart';

// ── State ─────────────────────────────────────────────────────
class SaleInvoiceListState {
  final List<SaleInvoiceListModel> allInvoices;
  final List<CashierModel>         cashiers;
  final String?                    selectedCashierId;
  final String?                    selectedCustomerId;   // ← NEW
  final String?                    selectedCustomerName; // ← NEW
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
    this.selectedCustomerId,    // ← NEW
    this.selectedCustomerName,  // ← NEW
    DateTime? fromDate,
    DateTime? toDate,
    this.searchQuery           = '',
    this.isLoading             = false,
    this.isCashiersLoading     = false,
    this.errorMessage,
    this.counterId,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ── Filtered Invoices ─────────────────────────────────────
  List<SaleInvoiceListModel> get filteredInvoices {
    var list = allInvoices;

    // Customer filter
    if (selectedCustomerId != null) {
      list = list.where((inv) => inv.customerId == selectedCustomerId).toList();
    }

    // Search filter
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

  // Customer-specific stats
  bool   get isCustomerSelected  => selectedCustomerId != null;

  double get customerTotalSale   => filteredInvoices.fold(0, (s, i) => s + i.grandTotal);

  double get customerCashSale    => filteredInvoices
      .where((i) => i.paymentType.contains('cash'))
      .fold(0, (s, i) => s + i.grandTotal);

  double get customerCreditSale  => filteredInvoices
      .where((i) => i.paymentType.contains('credit'))
      .fold(0, (s, i) => s + i.grandTotal);

  double get customerTotalDiscount => filteredInvoices.fold(0, (s, i) => s + i.totalDiscount);

  int    get customerInvoiceCount  => filteredInvoices.length;

  // ── CopyWith ──────────────────────────────────────────────
  SaleInvoiceListState copyWith({
    List<SaleInvoiceListModel>? allInvoices,
    List<CashierModel>?         cashiers,
    String?                     selectedCashierId,
    bool                        clearSelectedCashier   = false,
    String?                     selectedCustomerId,
    bool                        clearSelectedCustomer  = false,  // ← NEW
    String?                     selectedCustomerName,
    bool                        clearSelectedCustomerName = false, // ← NEW
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
  String get _userId    => _ref.read(authProvider).user?.id ?? '';

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

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId   = _isManager ? state.selectedCashierId : _userId;
      final invoices = await _ds.getAll(
        storeId:   _storeId,
        fromDate:  state.fromDate,
        toDate:    state.toDate,
        counterId: state.counterId,
        userId:    userId,
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
    final today = SaleInvoiceListState._today();
    setDateRange(today, today);
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

  // ── Customer Filter ────────────────────────────────────────
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