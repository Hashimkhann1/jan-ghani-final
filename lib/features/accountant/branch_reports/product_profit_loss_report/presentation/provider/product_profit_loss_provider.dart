import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/product_profit_loss_datasource.dart';
import '../../data/model/product_profit_loss_model.dart';

const _sentinel = Object();

class ProductProfitLossState {
  final List<ProductProfitLossModel> allItems;
  final List<ProductProfitLossModel> filtered;
  final List<ProductPnlCategory>     categories;
  final Set<String>                  selectedIds;
  final DateTime                     fromDate;
  final DateTime                     toDate;
  final String                       searchQuery;
  final String?                      categoryFilter;
  final bool                         onlyWithActivity;
  final bool                         isLoading;
  final String?                      errorMessage;

  const ProductProfitLossState({
    this.allItems         = const [],
    this.filtered         = const [],
    this.categories       = const [],
    this.selectedIds      = const {},
    required this.fromDate,
    required this.toDate,
    this.searchQuery      = '',
    this.categoryFilter,
    this.onlyWithActivity = false,
    this.isLoading        = false,
    this.errorMessage,
  });

  /// Rows the PDF/summary should use: the ticked products if any are
  /// ticked, otherwise everything currently visible.
  List<ProductProfitLossModel> get exportItems => selectedIds.isEmpty
      ? filtered
      : filtered.where((i) => selectedIds.contains(i.productId)).toList();

  bool get allFilteredSelected =>
      filtered.isNotEmpty &&
      filtered.every((i) => selectedIds.contains(i.productId));

  ProductProfitLossState copyWith({
    List<ProductProfitLossModel>? allItems,
    List<ProductProfitLossModel>? filtered,
    List<ProductPnlCategory>?     categories,
    Set<String>?                  selectedIds,
    DateTime?                     fromDate,
    DateTime?                     toDate,
    String?                       searchQuery,
    Object?                       categoryFilter = _sentinel,
    bool?                         onlyWithActivity,
    bool?                         isLoading,
    Object?                       errorMessage = _sentinel,
  }) =>
      ProductProfitLossState(
        allItems:         allItems         ?? this.allItems,
        filtered:         filtered         ?? this.filtered,
        categories:       categories       ?? this.categories,
        selectedIds:      selectedIds      ?? this.selectedIds,
        fromDate:         fromDate         ?? this.fromDate,
        toDate:           toDate           ?? this.toDate,
        searchQuery:      searchQuery      ?? this.searchQuery,
        categoryFilter:   categoryFilter == _sentinel
            ? this.categoryFilter
            : categoryFilter as String?,
        onlyWithActivity: onlyWithActivity ?? this.onlyWithActivity,
        isLoading:        isLoading        ?? this.isLoading,
        errorMessage:     errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
      );
}

class ProductProfitLossNotifier extends StateNotifier<ProductProfitLossState> {
  final ProductProfitLossSource _ds;

  ProductProfitLossNotifier({required ProductProfitLossSource source})
      : _ds = source,
        super(_initial()) {
    load();
  }

  static ProductProfitLossState _initial() {
    final now = DateTime.now();
    return ProductProfitLossState(
      fromDate: DateTime(now.year, now.month, 1),
      toDate:   DateTime(now.year, now.month, now.day),
    );
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final categories = state.categories.isNotEmpty
          ? state.categories
          : await _ds.fetchCategories();
      final items = await _ds.fetchReport(
        fromDate: state.fromDate,
        toDate:   state.toDate,
        categoryNameById: {for (final c in categories) c.id: c.name},
      );
      final validIds = items.map((i) => i.productId).toSet();
      state = state.copyWith(
        allItems:    items,
        categories:  categories,
        selectedIds: state.selectedIds.intersection(validIds),
        filtered:    _apply(items,
            q: state.searchQuery,
            categoryId: state.categoryFilter,
            onlyActive: state.onlyWithActivity),
        isLoading:   false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(fromDate: from, toDate: to);
    load();
  }

  void search(String q) => _refilter(q: q);
  void setCategoryFilter(String? id) => _refilter(categoryId: id, clearCategory: id == null);
  void toggleOnlyWithActivity() => _refilter(onlyActive: !state.onlyWithActivity);

  void _refilter({
    String? q,
    String? categoryId,
    bool clearCategory = false,
    bool? onlyActive,
  }) {
    final query = q ?? state.searchQuery;
    final cat   = clearCategory ? null : (categoryId ?? state.categoryFilter);
    final act   = onlyActive ?? state.onlyWithActivity;
    state = state.copyWith(
      searchQuery:      query,
      categoryFilter:   cat,
      onlyWithActivity: act,
      filtered: _apply(state.allItems, q: query, categoryId: cat, onlyActive: act),
    );
  }

  // ── Selection ─────────────────────────────────────────
  void toggleSelect(String productId) {
    final next = {...state.selectedIds};
    if (!next.remove(productId)) next.add(productId);
    state = state.copyWith(selectedIds: next);
  }

  void toggleSelectAll() {
    final ids = state.filtered.map((i) => i.productId).toSet();
    state = state.copyWith(
      selectedIds: state.allFilteredSelected
          ? state.selectedIds.difference(ids)
          : state.selectedIds.union(ids),
    );
  }

  void clearSelection() => state = state.copyWith(selectedIds: {});
  void clearError()     => state = state.copyWith(errorMessage: null);

  List<ProductProfitLossModel> _apply(
    List<ProductProfitLossModel> all, {
    required String q,
    required String? categoryId,
    required bool onlyActive,
  }) {
    var list = all;
    if (q.isNotEmpty) {
      final lower = q.toLowerCase();
      list = list
          .where((i) =>
              i.productName.toLowerCase().contains(lower) ||
              i.sku.toLowerCase().contains(lower))
          .toList();
    }
    if (categoryId != null) {
      list = list.where((i) => i.categoryId == categoryId).toList();
    }
    if (onlyActive) {
      list = list.where((i) => i.soldQty != 0 || i.returnQty != 0).toList();
    }
    return list;
  }
}

final productProfitLossProvider = StateNotifierProvider.autoDispose
    .family<ProductProfitLossNotifier, ProductProfitLossState, String>(
  (ref, branchId) => ProductProfitLossNotifier(
    source: ProductProfitLossDatasource(branchId: branchId),
  ),
);
