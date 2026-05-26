import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/sale_return_report_datasource.dart';
import '../../data/model/sale_return_report_model.dart';


// ── State ─────────────────────────────────────────────────────
class SaleReturnState {
  final List<SaleReturnModel>    allReturns;
  final List<CashierReturnModel> cashiers;
  final String?                  selectedCashierId;
  final String?                  selectedCustomerId;
  final String?                  selectedCustomerName;
  final DateTime                 fromDate;
  final DateTime                 toDate;
  final String                   searchQuery;
  final bool                     isLoading;
  final bool                     isCashiersLoading;
  final String?                  errorMessage;
  final String?                  counterId;

  SaleReturnState({
    this.allReturns          = const [],
    this.cashiers            = const [],
    this.selectedCashierId,
    this.selectedCustomerId,
    this.selectedCustomerName,
    DateTime? fromDate,
    DateTime? toDate,
    this.searchQuery         = '',
    this.isLoading           = false,
    this.isCashiersLoading   = false,
    this.errorMessage,
    this.counterId,
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ── Filtered Returns ──────────────────────────────────────
  List<SaleReturnModel> get filteredReturns {
    var list = allReturns;

    if (selectedCustomerId != null) {
      list = list
          .where((r) => r.customerId == selectedCustomerId)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((r) {
        if (r.returnNo.toLowerCase().contains(q))                        return true;
        if (r.customerName?.toLowerCase().contains(q) ?? false)         return true;
        if (r.cashierName?.toLowerCase().contains(q)  ?? false)         return true;
        if (r.refundType.toLowerCase().contains(q))                      return true;
        if (r.returnReason?.toLowerCase().contains(q) ?? false)         return true;
        if (r.items.any((i) => i.productName.toLowerCase().contains(q))) return true;
        return false;
      }).toList();
    }

    return list;
  }

  // ── Stats ─────────────────────────────────────────────────
  double get totalGrand    => filteredReturns.fold(0, (s, r) => s + r.grandTotal);
  double get totalDiscount => filteredReturns.fold(0, (s, r) => s + r.totalDiscount);
  int    get totalCount    => filteredReturns.length;

  bool   get isCustomerSelected    => selectedCustomerId != null;
  double get customerTotalRefund   => filteredReturns.fold(0, (s, r) => s + r.grandTotal);
  double get customerCashRefund    => filteredReturns
      .where((r) => r.refundType.contains('cash'))
      .fold(0, (s, r) => s + r.grandTotal);
  double get customerCreditRefund  => filteredReturns
      .where((r) => r.refundType.contains('credit'))
      .fold(0, (s, r) => s + r.grandTotal);
  double get customerTotalDiscount => filteredReturns.fold(0, (s, r) => s + r.totalDiscount);
  int    get customerReturnCount   => filteredReturns.length;

  // ── CopyWith ──────────────────────────────────────────────
  SaleReturnState copyWith({
    List<SaleReturnModel>?    allReturns,
    List<CashierReturnModel>? cashiers,
    String?                   selectedCashierId,
    bool                      clearSelectedCashier      = false,
    String?                   selectedCustomerId,
    bool                      clearSelectedCustomer     = false,
    String?                   selectedCustomerName,
    bool                      clearSelectedCustomerName = false,
    DateTime?                 fromDate,
    DateTime?                 toDate,
    String?                   searchQuery,
    bool?                     isLoading,
    bool?                     isCashiersLoading,
    String?                   errorMessage,
    String?                   counterId,
    bool                      clearCounterId = false,
  }) =>
      SaleReturnState(
        allReturns:           allReturns           ?? this.allReturns,
        cashiers:             cashiers             ?? this.cashiers,
        selectedCashierId:    clearSelectedCashier
            ? null
            : (selectedCashierId   ?? this.selectedCashierId),
        selectedCustomerId:   clearSelectedCustomer
            ? null
            : (selectedCustomerId  ?? this.selectedCustomerId),
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
class SaleReturnNotifier extends StateNotifier<SaleReturnState> {
  final SaleReturnDatasource _ds;
  final Ref                  _ref;

  SaleReturnNotifier(this._ref, {String? counterId})
      : _ds = SaleReturnDatasource(),
        super(SaleReturnState(counterId: counterId)) {
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
      final userId  = _isManager ? state.selectedCashierId : _userId;
      final returns = await _ds.getAll(
        storeId:   _storeId,
        fromDate:  state.fromDate,
        toDate:    state.toDate,
        counterId: state.counterId,
        userId:    userId,
      );
      state = state.copyWith(allReturns: returns, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
    load();
  }

  void setToday() {
    final today = SaleReturnState._today();
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
final saleReturnProvider =
StateNotifierProvider<SaleReturnNotifier, SaleReturnState>(
      (ref) => SaleReturnNotifier(ref),
);

final saleReturnByCounterProvider = StateNotifierProvider.family
<SaleReturnNotifier, SaleReturnState, String>(
(ref, counterId) => SaleReturnNotifier(ref, counterId: counterId),
);