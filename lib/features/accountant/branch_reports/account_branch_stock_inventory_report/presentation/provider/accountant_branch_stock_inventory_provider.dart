import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/pagination/branch_report_pagination.dart';
import '../../data/datasource/accountant_branch_stock_inventory_datasource.dart';
import '../../data/model/accountant_branch_stock_inventory_model.dart';

const _sentinel = Object();

// ── State ─────────────────────────────────────────────────
class AccountantBranchInventoryState {
  final List<AccountantBranchInventoryModel> allItems;
  final List<AccountantBranchInventoryModel> filtered;
  final List<CategoryModel>                  categories;
  final AccountantBranchInventorySummary     summary;
  final String                               searchQuery;
  final StockStatus?                         stockFilter;
  final String?                              categoryFilter;
  final bool                                 deadStockOnly;
  final BranchReportPageState                pagination;
  final bool                                 isLoading;
  final String?                              errorMessage;

  const AccountantBranchInventoryState({
    this.allItems       = const [],
    this.filtered       = const [],
    this.categories     = const [],
    AccountantBranchInventorySummary? summary,
    this.searchQuery    = '',
    this.stockFilter,
    this.categoryFilter,
    this.deadStockOnly  = false,
    this.pagination     = const BranchReportPageState(),
    this.isLoading      = false,
    this.errorMessage,
  }) : summary = summary ?? const AccountantBranchInventorySummary(
    totalProducts:   0,
    inStock:         0,
    lowStock:        0,
    outOfStock:      0,
    totalStockValue: 0,
  );

  // The table/list only ever renders one page's worth of the (already
  // fully loaded, client-side filtered/searched) `filtered` list — the
  // full catalog has to stay in memory anyway for search + the summary
  // cards, so pagination here just windows the already-fetched data.
  List<AccountantBranchInventoryModel> get pageItems {
    final (start, end) = BranchReportPagination.range(pagination.page);
    if (start >= filtered.length) return const [];
    return filtered.sublist(
        start, end + 1 > filtered.length ? filtered.length : end + 1);
  }

  bool get hasNextPage =>
      (pagination.page + 1) * BranchReportPagination.pageSize <
      filtered.length;

  AccountantBranchInventoryState copyWith({
    List<AccountantBranchInventoryModel>? allItems,
    List<AccountantBranchInventoryModel>? filtered,
    List<CategoryModel>?                  categories,
    AccountantBranchInventorySummary?     summary,
    String?                               searchQuery,
    Object?                               stockFilter    = _sentinel,
    Object?                               categoryFilter = _sentinel,
    bool?                                 deadStockOnly,
    BranchReportPageState?                pagination,
    bool?                                 isLoading,
    Object?                               errorMessage   = _sentinel,
  }) =>
      AccountantBranchInventoryState(
        allItems:       allItems       ?? this.allItems,
        filtered:       filtered       ?? this.filtered,
        categories:     categories     ?? this.categories,
        summary:        summary        ?? this.summary,
        searchQuery:    searchQuery    ?? this.searchQuery,
        stockFilter:    stockFilter == _sentinel
            ? this.stockFilter
            : stockFilter as StockStatus?,
        categoryFilter: categoryFilter == _sentinel
            ? this.categoryFilter
            : categoryFilter as String?,
        deadStockOnly:  deadStockOnly  ?? this.deadStockOnly,
        pagination:     pagination     ?? this.pagination,
        isLoading:      isLoading      ?? this.isLoading,
        errorMessage:   errorMessage == _sentinel
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
      final categories = await _ds.fetchCategories();
      final categoryNameById = {
        for (final c in categories) c.id: c.name,
      };
      final items = await _ds.fetchInventory(categoryNameById);

      state = state.copyWith(
        allItems:   items,
        categories: categories, // saari active categories, koi ID-match filter nahi
        filtered:   _applyFilters(
          items,
          state.searchQuery,
          state.stockFilter,
          state.categoryFilter,
          state.deadStockOnly,
        ),
        summary:    _buildSummary(items),
        pagination: const BranchReportPageState(),
        isLoading:  false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void search(String q) {
    state = state.copyWith(
      searchQuery: q,
      filtered:    _applyFilters(
        state.allItems, q, state.stockFilter, state.categoryFilter, state.deadStockOnly,
      ),
      pagination:  const BranchReportPageState(),
    );
  }

  void setStockFilter(StockStatus? filter) {
    state = state.copyWith(
      stockFilter: filter,
      filtered:    _applyFilters(
        state.allItems, state.searchQuery, filter, state.categoryFilter, state.deadStockOnly,
      ),
      pagination:  const BranchReportPageState(),
    );
  }

  void setCategoryFilter(String? categoryId) {
    state = state.copyWith(
      categoryFilter: categoryId,
      filtered:       _applyFilters(
        state.allItems, state.searchQuery, state.stockFilter, categoryId, state.deadStockOnly,
      ),
      pagination:     const BranchReportPageState(),
    );
  }

  void toggleDeadStockOnly() {
    final next = !state.deadStockOnly;
    state = state.copyWith(
      deadStockOnly: next,
      filtered:      _applyFilters(
        state.allItems, state.searchQuery, state.stockFilter, state.categoryFilter, next,
      ),
      pagination:    const BranchReportPageState(),
    );
  }

  // ── Page navigation — client-side windowing of `filtered`, no network
  //    call needed since the whole catalog is already in memory ──────────
  void nextPage() {
    if (!state.hasNextPage) return;
    state = state.copyWith(
      pagination: state.pagination.copyWith(page: state.pagination.page + 1),
    );
  }

  void previousPage() {
    if (!state.pagination.hasPreviousPage) return;
    state = state.copyWith(
      pagination: state.pagination.copyWith(page: state.pagination.page - 1),
    );
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  // ── Helpers ───────────────────────────────────────────
  List<AccountantBranchInventoryModel> _applyFilters(
      List<AccountantBranchInventoryModel> all,
      String       q,
      StockStatus? filter,
      String?      categoryId,
      bool         deadStockOnly,
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
    if (categoryId != null) {
      list = list.where((i) => i.categoryId == categoryId).toList();
    }
    if (deadStockOnly) {
      list = list.where((i) => i.isDeadStock).toList();
    }
    return list;
  }

  AccountantBranchInventorySummary _buildSummary(
      List<AccountantBranchInventoryModel> items) {

    final inStockItems    = items.where((i) => i.stockStatus == StockStatus.inStock).toList();
    final lowStockItems   = items.where((i) => i.stockStatus == StockStatus.lowStock).toList();
    final outOfStockItems = items.where((i) => i.stockStatus == StockStatus.outOfStock).toList();
    final deadStockItems  = items.where((i) => i.isDeadStock).toList();

    double qty(List<AccountantBranchInventoryModel> l)      => l.fold(0, (s, i) => s + i.stock);
    double sale(List<AccountantBranchInventoryModel> l)     => l.fold(0, (s, i) => s + (i.stock * i.salePrice));
    double purchase(List<AccountantBranchInventoryModel> l) => l.fold(0, (s, i) => s + (i.stock * i.purchasePrice));

    return AccountantBranchInventorySummary(
      totalProducts:      items.length,
      inStock:            inStockItems.length,
      lowStock:           lowStockItems.length,
      outOfStock:         outOfStockItems.length,
      deadStock:          deadStockItems.length,
      totalStockValue:    purchase(items),
      totalPurchaseValue: purchase(items),
      totalSaleValue:     sale(items),
      inStockQty:            qty(inStockItems),
      inStockSaleValue:      sale(inStockItems),
      inStockPurchaseValue:  purchase(inStockItems),
      lowStockQty:           qty(lowStockItems),
      lowStockSaleValue:     sale(lowStockItems),
      lowStockPurchaseValue: purchase(lowStockItems),
      outStockQty:           qty(outOfStockItems),
      outStockSaleValue:     sale(outOfStockItems),
      outStockPurchaseValue: purchase(outOfStockItems),
      deadStockQty:            qty(deadStockItems),
      deadStockSaleValue:      sale(deadStockItems),
      deadStockPurchaseValue:  purchase(deadStockItems),
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