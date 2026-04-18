import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/sale_invoice_list_datasource.dart';
import '../../data/model/sale_invoice_list_model.dart';

// ── State ─────────────────────────────────────────────────────
class SaleInvoiceListState {
  final List<SaleInvoiceListModel> allInvoices;
  final DateTime fromDate;
  final DateTime toDate;
  final String   searchQuery;
  final bool     isLoading;
  final String?  errorMessage;
  final String?  counterId;   // null = show ALL invoices

  SaleInvoiceListState({
    this.allInvoices  = const [],
    DateTime? fromDate,
    DateTime? toDate,
    this.searchQuery  = '',
    this.isLoading    = false,
    this.errorMessage,
    this.counterId,           // not passed → all invoices
  })  : fromDate = fromDate ?? _today(),
        toDate   = toDate   ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ── Filtered list ─────────────────────────────────────────
  List<SaleInvoiceListModel> get filteredInvoices {
    if (searchQuery.isEmpty) return allInvoices;
    final q = searchQuery.toLowerCase();
    return allInvoices.where((inv) {
      if (inv.invoiceNo.toLowerCase().contains(q))                    return true;
      if (inv.customerName?.toLowerCase().contains(q) ?? false)       return true;
      if (inv.paymentType.toLowerCase().contains(q))                  return true;
      if (inv.items.any((i) => i.productName.toLowerCase().contains(q))) return true;
      return false;
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────
  double get totalGrand    => filteredInvoices.fold(0, (s, i) => s + i.grandTotal);
  double get totalDiscount => filteredInvoices.fold(0, (s, i) => s + i.totalDiscount);
  int    get totalCount    => filteredInvoices.length;

  SaleInvoiceListState copyWith({
    List<SaleInvoiceListModel>? allInvoices,
    DateTime?                   fromDate,
    DateTime?                   toDate,
    String?                     searchQuery,
    bool?                       isLoading,
    String?                     errorMessage,
    String?                     counterId,
    bool                        clearCounterId = false,  // counterId ko null karne ke liye
  }) =>
      SaleInvoiceListState(
        allInvoices:  allInvoices  ?? this.allInvoices,
        fromDate:     fromDate     ?? this.fromDate,
        toDate:       toDate       ?? this.toDate,
        searchQuery:  searchQuery  ?? this.searchQuery,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage,
        counterId:    clearCounterId ? null : (counterId ?? this.counterId),
      );
}

// ── Notifier ──────────────────────────────────────────────────
class SaleInvoiceListNotifier extends StateNotifier<SaleInvoiceListState> {
  final SaleInvoiceListDatasource _ds;
  final Ref _ref;

  SaleInvoiceListNotifier(this._ref, {String? counterId})
      : _ds = SaleInvoiceListDatasource(),
        super(SaleInvoiceListState(counterId: counterId)) {
    load();
  }

  String get _storeId => _ref.read(authProvider).storeId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final invoices = await _ds.getAll(
        storeId:   _storeId,
        fromDate:  state.fromDate,
        toDate:    state.toDate,
        counterId: state.counterId,
      );
      state = state.copyWith(allInvoices: invoices, isLoading: false);
    } catch (e) {
      print('SaleInvoiceList load error: $e');
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

  /// Counter filter set karo — null pass karo to sab dikhega
  void setCounter(String? counterId) {
    state = counterId != null
        ? state.copyWith(counterId: counterId)
        : state.copyWith(clearCounterId: true);
    load();
  }

  void onSearchChanged(String q) => state = state.copyWith(searchQuery: q);
  void clearError()               => state = state.copyWith(errorMessage: null);
}

// ── Provider (all invoices — no counter filter) ───────────────
final saleInvoiceListProvider =
StateNotifierProvider<SaleInvoiceListNotifier, SaleInvoiceListState>(
      (ref) => SaleInvoiceListNotifier(ref),
);

// ── Family provider (specific counter ke liye) ────────────────
final saleInvoiceByCounterProvider = StateNotifierProvider.family<
    SaleInvoiceListNotifier, SaleInvoiceListState, String>(
      (ref, counterId) => SaleInvoiceListNotifier(ref, counterId: counterId),
);