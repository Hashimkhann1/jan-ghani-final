// lib/features/branch/reports/presentation/provider/csr_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/csr_datasource.dart';
import '../../data/model/csr_model.dart';

// ── State ─────────────────────────────────────────────────────
class CsrState {
  final List<CsrEntry> allEntries;
  final String? selectedCustomerId;
  final String? selectedCustomerName;
  final DateTime fromDate;
  final DateTime toDate;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  // Filter toggles
  final bool showSales;
  final bool showReturns;
  final bool showLedger;

  CsrState({
    this.allEntries = const [],
    this.selectedCustomerId,
    this.selectedCustomerName,
    DateTime? fromDate,
    DateTime? toDate,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.showSales = true,
    this.showReturns = true,
    this.showLedger = true,
  })  : fromDate = fromDate ?? _today(),
        toDate = toDate ?? _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ── Filtered entries ──────────────────────────────────────
  List<CsrEntry> get filteredEntries {
    var list = allEntries;

    if (!showSales) {
      list = list.where((e) => e.type != CsrType.sale).toList();
    }
    if (!showReturns) {
      list = list.where((e) => e.type != CsrType.saleReturn).toList();
    }
    if (!showLedger) {
      list = list.where((e) => e.type != CsrType.ledgerPayment).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((e) {
        if (e.entryNo.toLowerCase().contains(q)) return true;
        if (e.cashierName?.toLowerCase().contains(q) ?? false) return true;
        if (e.paymentLabel.toLowerCase().contains(q)) return true;
        if (e.returnReason?.toLowerCase().contains(q) ?? false) return true;
        if (e.notes?.toLowerCase().contains(q) ?? false) return true;
        if (e.items.any((i) => i.productName.toLowerCase().contains(q))) {
          return true;
        }
        return false;
      }).toList();
    }

    return list;
  }

  List<CsrEntry> get filteredSales =>
      filteredEntries.where((e) => e.type == CsrType.sale).toList();

  List<CsrEntry> get filteredReturns =>
      filteredEntries.where((e) => e.type == CsrType.saleReturn).toList();

  List<CsrEntry> get filteredLedger =>
      filteredEntries.where((e) => e.type == CsrType.ledgerPayment).toList();

  // ── Stats ─────────────────────────────────────────────────
  double get totalSaleAmount =>
      filteredSales.fold(0, (s, e) => s + e.grandTotal);
  double get totalReturnAmount =>
      filteredReturns.fold(0, (s, e) => s + e.grandTotal);
  double get netAmount => totalSaleAmount - totalReturnAmount;
  double get totalDiscount =>
      filteredEntries.fold(0, (s, e) => s + e.totalDiscount);
  double get totalLedgerPaid =>
      filteredLedger.fold(0, (s, e) => s + e.grandTotal);
  int get saleCount => filteredSales.length;
  int get returnCount => filteredReturns.length;
  int get ledgerCount => filteredLedger.length;

  double get cashSale => filteredSales
      .where((e) => e.paymentType?.contains('cash') ?? false)
      .fold(0, (s, e) => s + e.grandTotal);

  double get creditSale => filteredSales
      .where((e) => e.paymentType?.contains('credit') ?? false)
      .fold(0, (s, e) => s + e.grandTotal);

  bool get hasCustomer => selectedCustomerId != null;

  // ── CopyWith ──────────────────────────────────────────────
  CsrState copyWith({
    List<CsrEntry>? allEntries,
    String? selectedCustomerId,
    bool clearSelectedCustomer = false,
    String? selectedCustomerName,
    bool clearSelectedCustomerName = false,
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? showSales,
    bool? showReturns,
    bool? showLedger,
  }) =>
      CsrState(
        allEntries: allEntries ?? this.allEntries,
        selectedCustomerId: clearSelectedCustomer
            ? null
            : (selectedCustomerId ?? this.selectedCustomerId),
        selectedCustomerName: clearSelectedCustomerName
            ? null
            : (selectedCustomerName ?? this.selectedCustomerName),
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        searchQuery: searchQuery ?? this.searchQuery,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        showSales: showSales ?? this.showSales,
        showReturns: showReturns ?? this.showReturns,
        showLedger: showLedger ?? this.showLedger,
      );
}

// ── Notifier ──────────────────────────────────────────────────
class CsrNotifier extends StateNotifier<CsrState> {
  final CsrDatasource _ds;
  final Ref _ref;

  CsrNotifier(this._ref)
      : _ds = CsrDatasource(),
        super(CsrState());

  String get _storeId => _ref.read(authProvider).storeId;

  Future<void> load() async {
    if (state.selectedCustomerId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entries = await _ds.getAll(
        storeId: _storeId,
        fromDate: state.fromDate,
        toDate: state.toDate,
        customerId: state.selectedCustomerId!,
      );
      state = state.copyWith(allEntries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void selectCustomer(String? customerId, String? customerName) {
    if (customerId == null) {
      state = state.copyWith(
        clearSelectedCustomer: true,
        clearSelectedCustomerName: true,
        allEntries: [],
      );
    } else {
      final today = CsrState._today();
      state = state.copyWith(
        selectedCustomerId: customerId,
        selectedCustomerName: customerName,
        fromDate: today.subtract(const Duration(days: 30)),
        toDate: today,
      );
      load();
    }
  }

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
    load();
  }

  void setToday() {
    final today = CsrState._today();
    setDateRange(today, today);
  }

  void toggleSales()   => state = state.copyWith(showSales: !state.showSales);
  void toggleReturns() => state = state.copyWith(showReturns: !state.showReturns);
  void toggleLedger()  => state = state.copyWith(showLedger: !state.showLedger);

  void onSearchChanged(String q) => state = state.copyWith(searchQuery: q);
  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────
final csrProvider = StateNotifierProvider<CsrNotifier, CsrState>(
  (ref) => CsrNotifier(ref),
);
