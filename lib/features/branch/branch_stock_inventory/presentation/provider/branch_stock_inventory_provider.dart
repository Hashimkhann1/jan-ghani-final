// lib/features/branch/branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/branch_stock_remote_datasource.dart';
import '../../data/model/branch_stock_model.dart';

// ─────────────────────────────────────────────────────────────────
// POS Provider — saare products ek baar (barcode scan ke liye zarori)
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
  void clearError()                    => state = state.copyWith(errorMessage: null);
}

final branchStockProvider =
StateNotifierProvider<BranchStockNotifier, BranchStockState>(
      (ref) => BranchStockNotifier(ref),
);

// ─────────────────────────────────────────────────────────────────
// Inventory Screen Provider — DB-level pagination + edit + delete
// ─────────────────────────────────────────────────────────────────
const int kInventoryPageSize = 100;

class InventoryPageState {
  final List<BranchStockModel> rows;
  final int     currentPage;
  final int     totalCount;
  final int     pageSize;
  final bool    isLoading;
  final bool    isMutating;   // edit / delete ke time true
  final String  searchQuery;
  final String  filterStatus;
  final String? errorMessage;
  final String? successMessage;

  const InventoryPageState({
    this.rows           = const [],
    this.currentPage    = 0,
    this.totalCount     = 0,
    this.pageSize       = kInventoryPageSize,
    this.isLoading      = false,
    this.isMutating     = false,
    this.searchQuery    = '',
    this.filterStatus   = 'all',
    this.errorMessage,
    this.successMessage,
  });

  int  get totalPages  => (totalCount / pageSize).ceil();
  int  get displayPage => currentPage + 1;
  bool get hasPrev     => currentPage > 0;
  bool get hasNext     => currentPage < totalPages - 1;
  int  get fromRow     => totalCount == 0 ? 0 : currentPage * pageSize + 1;
  int  get toRow       => (fromRow + rows.length - 1).clamp(0, totalCount);

  InventoryPageState copyWith({
    List<BranchStockModel>? rows,
    int?    currentPage,
    int?    totalCount,
    int?    pageSize,
    bool?   isLoading,
    bool?   isMutating,
    String? searchQuery,
    String? filterStatus,
    String? errorMessage,
    String? successMessage,
  }) => InventoryPageState(
    rows:           rows           ?? this.rows,
    currentPage:    currentPage    ?? this.currentPage,
    totalCount:     totalCount     ?? this.totalCount,
    pageSize:       pageSize       ?? this.pageSize,
    isLoading:      isLoading      ?? this.isLoading,
    isMutating:     isMutating     ?? this.isMutating,
    searchQuery:    searchQuery    ?? this.searchQuery,
    filterStatus:   filterStatus   ?? this.filterStatus,
    errorMessage:   errorMessage,
    successMessage: successMessage,
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

  // ── Load / Refresh ───────────────────────────────────────
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
        rows:       result.rows,
        totalCount: result.totalCount,
        isLoading:  false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void refresh() => _load();

  // ── Edit Product ─────────────────────────────────────────
  Future<bool> updateProduct(BranchStockInventory updated) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      await _ds.updateProduct(updated);

      // POS provider bhi refresh karo
      _ref.read(branchStockProvider.notifier).load();

      // Local list mein bhi update karo (instant UI response)
      final updatedRows = state.rows.map((r) {
        if (r.id != updated.id) return r;
        return BranchStockModel.fromMap({
          'inv_id':          r.id,
          'store_id':        r.storeId,
          'product_id':      r.productId,
          'sku':             updated.sku,
          'barcode':         updated.barcode.isNotEmpty
              ? updated.barcode.first
              : null,
          'name':            updated.productName,
          'description':     r.description,
          'unit_of_measure': updated.unit,
          'cost_price':      updated.purchasePrice,
          'selling_price':   updated.salePrice,
          'wholesale_price': updated.wholesalePrice,
          'tax_rate':        r.taxRate,
          'discount':        r.discount,
          'min_stock_level': updated.minStock.toInt(),
          'max_stock_level': updated.maxStock.toInt(),
          'reorder_point':   r.reorderPoint,
          'is_active':       r.isActive,
          'is_track_stock':  r.isTrackStock,
          'quantity':        updated.stock,
          'reserved_quantity': r.reservedQuantity,
          'last_counted_at': null,
          'last_movement_at': null,
          'updated_at':      DateTime.now().toIso8601String(),
        });
      }).toList();

      state = state.copyWith(
        rows:           updatedRows,
        isMutating:     false,
        successMessage: '${updated.productName} updated successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          isMutating: false, errorMessage: 'Update failed: $e');
      return false;
    }
  }

  // ── Delete Product ───────────────────────────────────────
  Future<bool> deleteProduct(BranchStockModel product) async {
    state = state.copyWith(isMutating: true, errorMessage: null);
    try {
      await _ds.deleteProduct(product.id);

      // POS provider bhi refresh karo
      _ref.read(branchStockProvider.notifier).load();

      // Local list se bhi hata do
      final updatedRows = state.rows.where((r) => r.id != product.id).toList();
      state = state.copyWith(
        rows:           updatedRows,
        totalCount:     state.totalCount - 1,
        isMutating:     false,
        successMessage: '${product.name} deleted successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          isMutating: false, errorMessage: 'Delete failed: $e');
      return false;
    }
  }

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

  void clearError()   => state = state.copyWith(errorMessage: null);
  void clearSuccess() => state = state.copyWith(successMessage: null);

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