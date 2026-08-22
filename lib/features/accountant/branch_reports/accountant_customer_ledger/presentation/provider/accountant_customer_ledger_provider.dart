import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../accountant_customer/data/model/accountant_customer_model.dart';
import '../../../common/pagination/branch_report_pagination.dart';
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
  final BranchReportPageState               pagination;
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
    this.pagination          = const BranchReportPageState(),
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

  // Search/date filtering already happened server-side (date range) and
  // client-side (search text) above — pagination here just slices the
  // resulting [filtered] list for display, no extra server round-trip.
  List<CustomerLedgerModel> get pagedEntries {
    final start = pagination.page * BranchReportPagination.pageSize;
    final list  = filtered;
    if (start >= list.length) return const [];
    final end = (start + BranchReportPagination.pageSize)
        .clamp(0, list.length);
    return list.sublist(start, end);
  }

  double get totalPaid =>
      filtered.fold(0.0, (s, e) => s + e.payAmount);

  double get totalCollected =>
      ledgerEntries.fold(0.0, (s, e) => s + e.payAmount);

  double get currentBalance =>
      filtered.isNotEmpty ? filtered.first.newAmount : 0;

  CustomerLedgerState copyWith({
    List<AccountantCustomerReportModel>? customers,
    Object?  selectedCustomer  = _sentinel,
    List<CustomerLedgerModel>?           ledgerEntries,
    String?                              searchQuery,
    Object?  startDate         = _sentinel,
    Object?  endDate           = _sentinel,
    BranchReportPageState?               pagination,
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
        pagination:         pagination         ?? this.pagination,
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
  void search(String q) => state = state.copyWith(
        searchQuery: q,
        pagination:  const BranchReportPageState(),
      );

  // ── Refresh ────────────────────────────────────────────
  Future<void> refresh() async => _fetchLedger();

  void clearError() =>
      state = state.copyWith(errorMessage: null);

  // ── Pagination — a display slice over the already-fetched,
  //    already-filtered [filtered] list (see CustomerLedgerState.pagedEntries) ──
  void nextPage() {
    if (!state.pagination.hasNextPage) return;
    state = state.copyWith(
      pagination: state.pagination.copyWith(page: state.pagination.page + 1),
    );
    _syncHasNextPage();
  }

  void previousPage() {
    if (!state.pagination.hasPreviousPage) return;
    state = state.copyWith(
      pagination: state.pagination.copyWith(page: state.pagination.page - 1),
    );
    _syncHasNextPage();
  }

  void _syncHasNextPage() {
    final page = state.pagination.page;
    state = state.copyWith(
      pagination: state.pagination.copyWith(
        hasNextPage:
            (page + 1) * BranchReportPagination.pageSize < state.filtered.length,
      ),
    );
  }

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
        ledgerEntries:   entries,
        isLoadingLedger: false,
        pagination: BranchReportPageState(
          page:        0,
          hasNextPage: entries.length > BranchReportPagination.pageSize,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoadingLedger: false, errorMessage: e.toString());
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