import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/datasource/branch_stock_remote_datasource.dart';
import '../../data/model/branch_stock_model.dart';

// ── State ─────────────────────────────────────────────────────
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
      // Status filter
      if (filterStatus == 'in_stock'    && (p.isLowStock || p.isOutOfStock)) return false;
      if (filterStatus == 'low_stock'   && !p.isLowStock)   return false;
      if (filterStatus == 'out_of_stock' && !p.isOutOfStock) return false;

      // Search filter
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q)    ||
            p.sku.toLowerCase().contains(q)     ||
            (p.barcode?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────
  int get totalProducts  => allProducts.length;
  int get inStockCount   =>
      allProducts.where((p) => !p.isLowStock && !p.isOutOfStock).length;
  int get lowStockCount  =>
      allProducts.where((p) => p.isLowStock).length;
  int get outOfStockCount =>
      allProducts.where((p) => p.isOutOfStock).length;

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

// ── Notifier ──────────────────────────────────────────────────
class BranchStockNotifier extends StateNotifier<BranchStockState> {
  final BranchStockDataSource _ds;
  final Ref _ref;

  BranchStockNotifier(this._ref): _ds = BranchStockDataSource(), super(const BranchStockState()) {load();}

  String get _storeId => _ref.read(authProvider).storeId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final products = await _ds.getAll(_storeId);
      state = state.copyWith(allProducts: products, isLoading: false);
    } catch (e) {
      print('❌ BranchStock load error: $e');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load error: $e');
    }
  }

  void onSearchChanged(String q)       => state = state.copyWith(searchQuery: q);
  void onFilterStatusChanged(String f) => state = state.copyWith(filterStatus: f);
  void clearError() => state = state.copyWith(errorMessage: null);
}

// ── Provider ──────────────────────────────────────────────────
final branchStockProvider =
StateNotifierProvider<BranchStockNotifier, BranchStockState>(
      (ref) => BranchStockNotifier(ref),
);