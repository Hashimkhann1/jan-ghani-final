import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/accountant_customer_datasource.dart';
import '../../data/model/accountant_customer_model.dart';

// ── State ─────────────────────────────────────────────────
class AccountantCustomerReportState {
  final List<AccountantCustomerReportModel> allCustomers;
  final List<AccountantCustomerReportModel> filtered;
  final AccountantCustomerReportSummary     summary;
  final String                              searchQuery;
  final String?                             filterType; // null=All | 'credit' | 'cash'
  final bool                                isLoading;
  final String?                             errorMessage;

  const AccountantCustomerReportState({
    this.allCustomers = const [],
    this.filtered     = const [],
    AccountantCustomerReportSummary? summary,
    this.searchQuery  = '',
    this.filterType,
    this.isLoading    = false,
    this.errorMessage,
  }) : summary = summary ?? const AccountantCustomerReportSummary(
    totalCustomers:   0,
    activeCustomers:  0,
    totalOutstanding: 0,
    totalCreditLimit: 0,
  );

  AccountantCustomerReportState copyWith({
    List<AccountantCustomerReportModel>? allCustomers,
    List<AccountantCustomerReportModel>? filtered,
    AccountantCustomerReportSummary?     summary,
    String?                              searchQuery,
    Object?                              filterType   = _sentinel,
    bool?                                isLoading,
    Object?                              errorMessage = _sentinel,
  }) =>
      AccountantCustomerReportState(
        allCustomers: allCustomers ?? this.allCustomers,
        filtered:     filtered     ?? this.filtered,
        summary:      summary      ?? this.summary,
        searchQuery:  searchQuery  ?? this.searchQuery,
        filterType:   filterType  == _sentinel
            ? this.filterType
            : filterType as String?,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
      );
}

const _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────
class AccountantCustomerReportNotifier
    extends StateNotifier<AccountantCustomerReportState> {
  final AccountantCustomerReportDatasource _datasource;

  AccountantCustomerReportNotifier(this._datasource)
      : super(const AccountantCustomerReportState()) {
    load();
  }

  // ── Load ────────────────────────────────────────────────
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final customers = await _datasource.fetchCustomers();
      state = state.copyWith(
        allCustomers: customers,
        filtered:     _applyFilters(customers, state.searchQuery, state.filterType),
        summary:      _buildSummary(customers),
        isLoading:    false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:    false,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Search ───────────────────────────────────────────────
  void search(String q) {
    state = state.copyWith(
      searchQuery: q,
      filtered:    _applyFilters(state.allCustomers, q, state.filterType),
    );
  }

  // ── Filter ───────────────────────────────────────────────
  void setFilter(String? type) {
    state = state.copyWith(
      filterType: type,
      filtered:   _applyFilters(state.allCustomers, state.searchQuery, type),
    );
  }

  // ── Clear Error ──────────────────────────────────────────
  void clearError() => state = state.copyWith(errorMessage: null);

  // ── Helpers ──────────────────────────────────────────────
  List<AccountantCustomerReportModel> _applyFilters(
      List<AccountantCustomerReportModel> all,
      String q,
      String? type,
      ) {
    var list = all;

    if (q.isNotEmpty) {
      final lower = q.toLowerCase();
      list = list.where((c) =>
      c.name.toLowerCase().contains(lower) ||
          c.phone.contains(lower) ||
          c.code.toLowerCase().contains(lower)).toList();
    }

    if (type != null) {
      list = list.where((c) => c.customerType == type).toList();
    }

    return list;
  }

  AccountantCustomerReportSummary _buildSummary(
      List<AccountantCustomerReportModel> customers) {
    return AccountantCustomerReportSummary(
      totalCustomers:   customers.length,
      activeCustomers:  customers.where((c) => c.isActive).length,
      totalOutstanding: customers.fold(0.0, (s, c) => s + c.balance),
      totalCreditLimit: customers.fold(0.0, (s, c) => s + c.creditLimit),
    );
  }
}

// ── Provider ──────────────────────────────────────────────
final accountantCustomerReportProvider = StateNotifierProvider.autoDispose<
    AccountantCustomerReportNotifier, AccountantCustomerReportState>((ref) {
  final datasource = AccountantCustomerReportDatasource(
    client: Supabase.instance.client,
  );
  return AccountantCustomerReportNotifier(datasource);
});