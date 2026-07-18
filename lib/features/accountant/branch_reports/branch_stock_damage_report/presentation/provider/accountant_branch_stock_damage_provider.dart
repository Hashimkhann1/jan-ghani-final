import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/accountant_branch_stock_damage_datasource.dart';
import '../../data/model/accountant_branch_stock_damage_model.dart';

const _sentinel = Object();

// ── State ─────────────────────────────────────────────────
class AccountantBranchStockDamageState {
  final List<AccountantBranchStockDamageModel> allItems;
  final List<AccountantBranchStockDamageModel> filtered;
  final AccountantBranchStockDamageSummary     summary;
  final String                                 searchQuery;
  final DateTime?                              startDate;
  final DateTime?                              endDate;
  final bool                                   isLoading;
  final String?                                errorMessage;

  const AccountantBranchStockDamageState({
    this.allItems    = const [],
    this.filtered    = const [],
    AccountantBranchStockDamageSummary? summary,
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.isLoading   = false,
    this.errorMessage,
  }) : summary = summary ?? const AccountantBranchStockDamageSummary(
    totalRecords:      0,
    totalDamageQty:    0,
    totalPurchaseLoss: 0,
    totalSaleLoss:     0,
  );

  AccountantBranchStockDamageState copyWith({
    List<AccountantBranchStockDamageModel>? allItems,
    List<AccountantBranchStockDamageModel>? filtered,
    AccountantBranchStockDamageSummary?     summary,
    String?                                 searchQuery,
    Object?                                 startDate    = _sentinel,
    Object?                                 endDate      = _sentinel,
    bool?                                   isLoading,
    Object?                                 errorMessage = _sentinel,
  }) =>
      AccountantBranchStockDamageState(
        allItems:     allItems     ?? this.allItems,
        filtered:     filtered     ?? this.filtered,
        summary:      summary      ?? this.summary,
        searchQuery:  searchQuery  ?? this.searchQuery,
        startDate:    startDate == _sentinel
            ? this.startDate
            : startDate as DateTime?,
        endDate:      endDate == _sentinel
            ? this.endDate
            : endDate as DateTime?,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
      );
}

// ── Notifier ──────────────────────────────────────────────
class AccountantBranchStockDamageNotifier
    extends StateNotifier<AccountantBranchStockDamageState> {
  final AccountantBranchStockDamageDatasource _ds;

  AccountantBranchStockDamageNotifier({required String branchId})
      : _ds = AccountantBranchStockDamageDatasource(branchId: branchId),
        super(const AccountantBranchStockDamageState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _ds.fetchDamage();
      final filtered = _applyFilters(
        items,
        state.searchQuery,
        state.startDate,
        state.endDate,
      );
      state = state.copyWith(
        allItems:  items,
        filtered:  filtered,
        summary:   _buildSummary(filtered),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void search(String q) {
    final filtered = _applyFilters(
      state.allItems,
      q,
      state.startDate,
      state.endDate,
    );
    state = state.copyWith(
      searchQuery: q,
      filtered:    filtered,
      summary:     _buildSummary(filtered),
    );
  }

  /// Set start date (pass null to clear)
  void setStartDate(DateTime? date) {
    final filtered = _applyFilters(
      state.allItems,
      state.searchQuery,
      date,
      state.endDate,
    );
    state = state.copyWith(
      startDate: date,
      filtered:  filtered,
      summary:   _buildSummary(filtered),
    );
  }

  /// Set end date (pass null to clear)
  void setEndDate(DateTime? date) {
    final filtered = _applyFilters(
      state.allItems,
      state.searchQuery,
      state.startDate,
      date,
    );
    state = state.copyWith(
      endDate:  date,
      filtered: filtered,
      summary:  _buildSummary(filtered),
    );
  }

  /// Set both dates together (useful for range pickers)
  void setDateRange(DateTime? start, DateTime? end) {
    final filtered = _applyFilters(
      state.allItems,
      state.searchQuery,
      start,
      end,
    );
    state = state.copyWith(
      startDate: start,
      endDate:   end,
      filtered:  filtered,
      summary:   _buildSummary(filtered),
    );
  }

  void clearDateFilter() {
    final filtered = _applyFilters(
      state.allItems,
      state.searchQuery,
      null,
      null,
    );
    state = state.copyWith(
      startDate: null,
      endDate:   null,
      filtered:  filtered,
      summary:   _buildSummary(filtered),
    );
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  // ── Helpers ───────────────────────────────────────────
  List<AccountantBranchStockDamageModel> _applyFilters(
      List<AccountantBranchStockDamageModel> all,
      String       q,
      DateTime?    start,
      DateTime?    end,
      ) {
    var list = all;

    if (q.isNotEmpty) {
      final lower = q.toLowerCase();
      list = list.where((i) =>
          i.productName.toLowerCase().contains(lower)).toList();
    }

    if (start != null) {
      final s = DateTime(start.year, start.month, start.day);
      list = list.where((i) => !i.createdAt.isBefore(s)).toList();
    }

    if (end != null) {
      // include the whole end day
      final e = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      list = list.where((i) => !i.createdAt.isAfter(e)).toList();
    }

    return list;
  }

  AccountantBranchStockDamageSummary _buildSummary(
      List<AccountantBranchStockDamageModel> items) {
    final qty          = items.fold(0.0, (s, i) => s + i.stockDamage);
    final purchaseLoss = items.fold(0.0, (s, i) => s + i.purchaseLoss);
    final saleLoss     = items.fold(0.0, (s, i) => s + i.saleLoss);

    return AccountantBranchStockDamageSummary(
      totalRecords:      items.length,
      totalDamageQty:    qty,
      totalPurchaseLoss: purchaseLoss,
      totalSaleLoss:     saleLoss,
    );
  }
}

// ── Provider ──────────────────────────────────────────────
final accountantBranchStockDamageProvider = StateNotifierProvider.autoDispose
    .family<AccountantBranchStockDamageNotifier,
    AccountantBranchStockDamageState, String>(
      (ref, branchId) =>
      AccountantBranchStockDamageNotifier(branchId: branchId),
);
