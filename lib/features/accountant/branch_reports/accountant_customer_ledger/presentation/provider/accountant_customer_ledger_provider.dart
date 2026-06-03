import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../accountant_customer/data/model/accountant_customer_model.dart';
import '../../data/datasource/accountant_customer_ledger_datasource.dart';
import '../../data/model/accountant_customer_ledger_model.dart';

const _sentinel = Object();

// ── State ──────────────────────────────────────────────────
class CustomerLedgerState {
  final List<AccountantCustomerReportModel> customers;
  final AccountantCustomerReportModel?      selectedCustomer;
  final List<CustomerLedgerModel>           ledgerEntries;
  final String                              searchQuery;
  final DateTime?                           startDate;
  final DateTime?                           endDate;
  final bool                                isLoadingCustomers;
  final bool                                isLoadingLedger;
  final String?                             errorMessage;

  const CustomerLedgerState({
    this.customers          = const [],
    this.selectedCustomer,
    this.ledgerEntries      = const [],
    this.searchQuery        = '',
    this.startDate,
    this.endDate,
    this.isLoadingCustomers = false,
    this.isLoadingLedger    = false,
    this.errorMessage,
  });

  /// Search ke baad filtered entries
  List<CustomerLedgerModel> get filtered {
    if (searchQuery.isEmpty) return ledgerEntries;
    final q = searchQuery.toLowerCase();
    return ledgerEntries.where((e) =>
    e.customerName.toLowerCase().contains(q) ||
        (e.notes ?? '').toLowerCase().contains(q),
    ).toList();
  }

  double get totalPaid =>
      filtered.fold(0.0, (s, e) => s + e.payAmount);

  double get currentBalance =>
      filtered.isNotEmpty ? filtered.first.newAmount : 0;

  CustomerLedgerState copyWith({
    List<AccountantCustomerReportModel>? customers,
    Object?  selectedCustomer  = _sentinel,
    List<CustomerLedgerModel>?           ledgerEntries,
    String?                              searchQuery,
    Object?  startDate         = _sentinel,
    Object?  endDate           = _sentinel,
    bool?                                isLoadingCustomers,
    bool?                                isLoadingLedger,
    Object?  errorMessage      = _sentinel,
  }) =>
      CustomerLedgerState(
        customers:          customers          ?? this.customers,
        selectedCustomer:   selectedCustomer  == _sentinel ? this.selectedCustomer  : selectedCustomer  as AccountantCustomerReportModel?,
        ledgerEntries:      ledgerEntries      ?? this.ledgerEntries,
        searchQuery:        searchQuery        ?? this.searchQuery,
        startDate:          startDate         == _sentinel ? this.startDate  : startDate  as DateTime?,
        endDate:            endDate           == _sentinel ? this.endDate    : endDate    as DateTime?,
        isLoadingCustomers: isLoadingCustomers ?? this.isLoadingCustomers,
        isLoadingLedger:    isLoadingLedger    ?? this.isLoadingLedger,
        errorMessage:       errorMessage      == _sentinel ? this.errorMessage : errorMessage as String?,
      );
}

// ── Notifier ───────────────────────────────────────────────
class CustomerLedgerNotifier
    extends StateNotifier<CustomerLedgerState> {
  final AccountantCustomerLedgerDatasource _datasource;

  CustomerLedgerNotifier(this._datasource)
      : super(const CustomerLedgerState(
    // Default: koi date filter nahi — sab data aayega
    startDate: null,
    endDate:   null,
  )) {
    _loadCustomers();
  }

  // ── Load customers (dropdown) ──────────────────────────
  Future<void> _loadCustomers() async {
    state = state.copyWith(isLoadingCustomers: true, errorMessage: null);
    try {
      final customers = await _datasource.fetchCustomers();
      state = state.copyWith(
        customers:          customers,
        isLoadingCustomers: false,
      );
      // if (customers.isNotEmpty) {
      //   await selectCustomer(customers.first);
      // }
      await _fetchLedger();
    } catch (e) {
      state = state.copyWith(
          isLoadingCustomers: false, errorMessage: e.toString());
    }
  }

  // ── Customer select / change ───────────────────────────
  Future<void> selectCustomer(
      AccountantCustomerReportModel customer) async {
    state = state.copyWith(
      selectedCustomer: customer,
      isLoadingLedger:  true,
      errorMessage:     null,
    );
    await _fetchLedger();
  }

  // ── Date filters ───────────────────────────────────────
  Future<void> setStartDate(DateTime? date) async {
    state = state.copyWith(startDate: date);
    await _fetchLedger();
  }

  Future<void> setEndDate(DateTime? date) async {
    state = state.copyWith(endDate: date);
    await _fetchLedger();
  }

  Future<void> clearDates() async {
    state = state.copyWith(startDate: null, endDate: null);
    await _fetchLedger();
  }

  // ── Search ─────────────────────────────────────────────
  void search(String q) =>
      state = state.copyWith(searchQuery: q);

  // ── Refresh ────────────────────────────────────────────
  Future<void> refresh() async => _fetchLedger();

  void clearError() =>
      state = state.copyWith(errorMessage: null);

  // ── Internal fetch ─────────────────────────────────────
  Future<void> _fetchLedger() async {
    state = state.copyWith(isLoadingLedger: true, errorMessage: null);
    try {
      final entries = await _datasource.fetchLedger(
        customerId: state.selectedCustomer?.id, // ✅ null hoga to sab aayega
        startDate:  state.startDate,
        endDate:    state.endDate,
      );
      state = state.copyWith(
          ledgerEntries: entries, isLoadingLedger: false);
    } catch (e) {
      state = state.copyWith(
          isLoadingLedger: false, errorMessage: e.toString());
    }
  }
}

// ── Provider ───────────────────────────────────────────────
final customerLedgerProvider = StateNotifierProvider.autoDispose
    .family<CustomerLedgerNotifier, CustomerLedgerState, String>(
      (ref, branchId) {
    final ds = AccountantCustomerLedgerDatasource(
      client:   Supabase.instance.client,
      branchId: branchId,
    );
    return CustomerLedgerNotifier(ds);
  },
);