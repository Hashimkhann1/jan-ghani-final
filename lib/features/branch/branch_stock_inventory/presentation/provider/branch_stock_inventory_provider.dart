// lib/features/branch/branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/branch_stock_remote_datasource.dart';
import '../../data/model/branch_stock_model.dart';

// ─────────────────────────────────────────────────────────────────
// POS Provider — saare products ek baar (barcode scan ke liye zarori)
// Yeh purana provider hai — POS screen is pe depend hai
// ─────────────────────────────────────────────────────────────────
class BranchStockState {
  final List<BranchStockModel> allProducts;
  final String  searchQuery;
  final String  filterStatus;
  final bool    isLoading;
  final String? errorMessage;

  const BranchStockState({
    this.allProducts  = const [],
    this.searchQuery  = '',
    this.filterStatus = 'all',
    this.isLoading    = false,
    this.errorMessage,
  });

  List<BranchStockModel> get filteredProducts {
    return allProducts.where((p) {
      if (filterStatus == 'in_stock'     && (p.isLowStock || p.isOutOfStock)) return false;
      if (filterStatus == 'low_stock'    && !p.isLowStock)                    return false;
      if (filterStatus == 'out_of_stock' && !p.isOutOfStock)                  return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q)     ||
            (p.barcode?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  int get totalProducts   => allProducts.length;
  int get inStockCount    => allProducts.where((p) => !p.isLowStock && !p.isOutOfStock).length;
  int get lowStockCount   => allProducts.where((p) => p.isLowStock).length;
  int get outOfStockCount => allProducts.where((p) => p.isOutOfStock).length;

  BranchStockState copyWith({
    List<BranchStockModel>? allProducts,
    String?                 searchQuery,
    String?                 filterStatus,
    bool?                   isLoading,
    String?                 errorMessage,
  }) => BranchStockState(
    allProducts:  allProducts  ?? this.allProducts,
    searchQuery:  searchQuery  ?? this.searchQuery,
    filterStatus: filterStatus ?? this.filterStatus,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

class BranchStockNotifier extends StateNotifier<BranchStockState> {
  final BranchStockDataSource _ds;
  final Ref _ref;

  BranchStockNotifier(this._ref)
      : _ds = BranchStockDataSource(),
        super(const BranchStockState()) {
    load();
  }

  String get _storeId => _ref.read(authProvider).storeId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final products = await _ds.getAll(_storeId);
      state = state.copyWith(allProducts: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void onSearchChanged(String q)       => state = state.copyWith(searchQuery: q);
  void onFilterStatusChanged(String f) => state = state.copyWith(filterStatus: f);
  void clearError() => state = state.copyWith(errorMessage: null);
}

final branchStockProvider =
StateNotifierProvider<BranchStockNotifier, BranchStockState>(
      (ref) => BranchStockNotifier(ref),
);

// ─────────────────────────────────────────────────────────────────
// Inventory Screen Provider — DB-level pagination
// POS se alag — sirf inventory table screen ke liye
// ─────────────────────────────────────────────────────────────────
const int kInventoryPageSize = 100; // ek page mein kitni rows

class InventoryPageState {
  final List<BranchStockModel> rows;
  final int    currentPage;   // 0-based
  final int    totalCount;
  final int    pageSize;
  final bool   isLoading;
  final String searchQuery;
  final String filterStatus;
  final String? errorMessage;

  const InventoryPageState({
    this.rows         = const [],
    this.currentPage  = 0,
    this.totalCount   = 0,
    this.pageSize     = kInventoryPageSize,
    this.isLoading    = false,
    this.searchQuery  = '',
    this.filterStatus = 'all',
    this.errorMessage,
  });

  int get totalPages  => (totalCount / pageSize).ceil();
  int get displayPage => currentPage + 1;           // 1-based (UI ke liye)
  bool get hasPrev    => currentPage > 0;
  bool get hasNext    => currentPage < totalPages - 1;

  int get fromRow => totalCount == 0 ? 0 : currentPage * pageSize + 1;
  int get toRow   => (fromRow + rows.length - 1).clamp(0, totalCount);

  InventoryPageState copyWith({
    List<BranchStockModel>? rows,
    int?    currentPage,
    int?    totalCount,
    int?    pageSize,
    bool?   isLoading,
    String? searchQuery,
    String? filterStatus,
    String? errorMessage,
  }) => InventoryPageState(
    rows:         rows         ?? this.rows,
    currentPage:  currentPage  ?? this.currentPage,
    totalCount:   totalCount   ?? this.totalCount,
    pageSize:     pageSize     ?? this.pageSize,
    isLoading:    isLoading    ?? this.isLoading,
    searchQuery:  searchQuery  ?? this.searchQuery,
    filterStatus: filterStatus ?? this.filterStatus,
    errorMessage: errorMessage,
  );
}

class InventoryPageNotifier extends StateNotifier<InventoryPageState> {
  final BranchStockDataSource _ds;
  final Ref _ref;
  Timer? _debounce;

  InventoryPageNotifier(this._ref)
      : _ds = BranchStockDataSource(),
        super(const InventoryPageState()) {
    _load();
  }

  String get _storeId => _ref.read(authProvider).storeId;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _ds.getPaginated(
        storeId:      _storeId,
        page:         state.currentPage,
        pageSize:     state.pageSize,
        search:       state.searchQuery,
        filterStatus: state.filterStatus,
      );
      state = state.copyWith(
        rows:        result.rows,
        totalCount:  result.totalCount,
        isLoading:   false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void refresh() => _load();

  // ── Navigation ───────────────────────────────────────────
  void nextPage() {
    if (!state.hasNext) return;
    state = state.copyWith(currentPage: state.currentPage + 1);
    _load();
  }

  void prevPage() {
    if (!state.hasPrev) return;
    state = state.copyWith(currentPage: state.currentPage - 1);
    _load();
  }

  void goToPage(int page) {
    if (page < 0 || page >= state.totalPages) return;
    state = state.copyWith(currentPage: page);
    _load();
  }

  // ── Search — debounce 400ms ──────────────────────────────
  void onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(searchQuery: q, currentPage: 0);
      _load();
    });
  }

  // ── Filter ───────────────────────────────────────────────
  void onFilterStatusChanged(String f) {
    state = state.copyWith(filterStatus: f, currentPage: 0);
    _load();
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final inventoryPageProvider =
StateNotifierProvider.autoDispose<InventoryPageNotifier, InventoryPageState>(
      (ref) => InventoryPageNotifier(ref),
);