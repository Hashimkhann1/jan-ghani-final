import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/accountant_branch_stock_inventory_datasource.dart';
import '../../data/model/accountant_branch_stock_inventory_model.dart';

const _sentinel = Object();

// ── State ─────────────────────────────────────────────────
class AccountantBranchInventoryState {
  final List<AccountantBranchInventoryModel> allItems;
  final List<AccountantBranchInventoryModel> filtered;
  final AccountantBranchInventorySummary     summary;
  final String                               searchQuery;
  final StockStatus?                         stockFilter;
  final bool                                 isLoading;
  final String?                              errorMessage;

  const AccountantBranchInventoryState({
    this.allItems    = const [],
    this.filtered    = const [],
    AccountantBranchInventorySummary? summary,
    this.searchQuery = '',
    this.stockFilter,
    this.isLoading   = false,
    this.errorMessage,
  }) : summary = summary ?? const AccountantBranchInventorySummary(
    totalProducts:   0,
    inStock:         0,
    lowStock:        0,
    outOfStock:      0,
    totalStockValue: 0,
  );

  AccountantBranchInventoryState copyWith({
    List<AccountantBranchInventoryModel>? allItems,
    List<AccountantBranchInventoryModel>? filtered,
    AccountantBranchInventorySummary?     summary,
    String?                               searchQuery,
    Object?                               stockFilter  = _sentinel,
    bool?                                 isLoading,
    Object?                               errorMessage = _sentinel,
  }) =>
      AccountantBranchInventoryState(
        allItems:     allItems     ?? this.allItems,
        filtered:     filtered     ?? this.filtered,
        summary:      summary      ?? this.summary,
        searchQuery:  searchQuery  ?? this.searchQuery,
        stockFilter:  stockFilter == _sentinel
            ? this.stockFilter
            : stockFilter as StockStatus?,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
      );
}

// ── Notifier ──────────────────────────────────────────────
class AccountantBranchInventoryNotifier
    extends StateNotifier<AccountantBranchInventoryState> {
  final AccountantBranchInventoryDatasource _ds;

  AccountantBranchInventoryNotifier({required String branchId})
      : _ds = AccountantBranchInventoryDatasource(branchId: branchId),
        super(const AccountantBranchInventoryState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _ds.fetchInventory();
      state = state.copyWith(
        allItems:  items,
        filtered:  _applyFilters(items, state.searchQuery, state.stockFilter),
        summary:   _buildSummary(items),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void search(String q) {
    state = state.copyWith(
      searchQuery: q,
      filtered:    _applyFilters(state.allItems, q, state.stockFilter),
    );
  }

  void setStockFilter(StockStatus? filter) {
    state = state.copyWith(
      stockFilter: filter,
      filtered:    _applyFilters(state.allItems, state.searchQuery, filter),
    );
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  // ── Helpers ───────────────────────────────────────────
  List<AccountantBranchInventoryModel> _applyFilters(
      List<AccountantBranchInventoryModel> all,
      String       q,
      StockStatus? filter,
      ) {
    var list = all;
    if (q.isNotEmpty) {
      final lower = q.toLowerCase();
      list = list.where((i) =>
      i.productName.toLowerCase().contains(lower) ||
          i.sku.toLowerCase().contains(lower)     ||
          i.barcodes.any((b) => b.contains(lower)),
      ).toList();
    }
    if (filter != null) {
      list = list.where((i) => i.stockStatus == filter).toList();
    }
    return list;
  }

  AccountantBranchInventorySummary _buildSummary(
      List<AccountantBranchInventoryModel> items) {

    final inStockItems    = items.where((i) => i.stockStatus == StockStatus.inStock).toList();
    final lowStockItems   = items.where((i) => i.stockStatus == StockStatus.lowStock).toList();
    final outOfStockItems = items.where((i) => i.stockStatus == StockStatus.outOfStock).toList();

    double qty(List<AccountantBranchInventoryModel> l)      => l.fold(0, (s, i) => s + i.stock);
    double sale(List<AccountantBranchInventoryModel> l)     => l.fold(0, (s, i) => s + (i.stock * i.salePrice));
    double purchase(List<AccountantBranchInventoryModel> l) => l.fold(0, (s, i) => s + (i.stock * i.purchasePrice));

    return AccountantBranchInventorySummary(
      totalProducts:      items.length,
      inStock:            inStockItems.length,
      lowStock:           lowStockItems.length,
      outOfStock:         outOfStockItems.length,
      totalStockValue:    purchase(items),
      totalPurchaseValue: purchase(items),
      totalSaleValue:     sale(items),
      // InStock
      inStockQty:            qty(inStockItems),
      inStockSaleValue:      sale(inStockItems),
      inStockPurchaseValue:  purchase(inStockItems),
      // LowStock
      lowStockQty:           qty(lowStockItems),
      lowStockSaleValue:     sale(lowStockItems),
      lowStockPurchaseValue: purchase(lowStockItems),
      // OutOfStock
      outStockQty:           qty(outOfStockItems),
      outStockSaleValue:     sale(outOfStockItems),
      outStockPurchaseValue: purchase(outOfStockItems),
    );
  }
}

// ── Provider ──────────────────────────────────────────────
final accountantBranchInventoryProvider = StateNotifierProvider.autoDispose
    .family<AccountantBranchInventoryNotifier,
    AccountantBranchInventoryState, String>(
      (ref, branchId) =>
      AccountantBranchInventoryNotifier(branchId: branchId),
);