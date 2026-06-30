import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/inventory_counting_datasource.dart';
import '../../data/model/inventory_countting_model.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class InventoryCountingState {
  final List<InventoryProductModel> products;
  final int countedCount;
  final bool isLoading;
  final bool allCounted;
  final String? errorMessage;

  const InventoryCountingState({
    this.products = const [],
    this.countedCount = 0,
    this.isLoading = false,
    this.allCounted = false,
    this.errorMessage,
  });

  InventoryCountingState copyWith({
    List<InventoryProductModel>? products,
    int? countedCount,
    bool? isLoading,
    bool? allCounted,
    String? errorMessage,
  }) {
    return InventoryCountingState(
      products: products ?? this.products,
      countedCount: countedCount ?? this.countedCount,
      isLoading: isLoading ?? this.isLoading,
      allCounted: allCounted ?? this.allCounted,
      errorMessage: errorMessage,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class InventoryCountingNotifier extends StateNotifier<InventoryCountingState> {
  final InventoryCountingRemoteDatasource _datasource;
  final String storeId;

  InventoryCountingNotifier({
    required InventoryCountingRemoteDatasource datasource,
    required this.storeId,
  })  : _datasource = datasource,
        super(const InventoryCountingState()) {
    loadPage();
  }

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadPage() async {
    state = state.copyWith(
      isLoading: true,
      allCounted: false,
      errorMessage: null,
    );

    try {
      // DB se aaj ke counted IDs aur actual count dono lo
      final countedIds = await _datasource.fetchCountedProductIds();
      final todayCount = await _datasource.fetchTodayCountedCount();

      final products = await _datasource.fetchProducts(
        storeId: storeId,
        excludeProductIds: countedIds,
      );

      state = state.copyWith(
        products: products,
        countedCount: todayCount, // ← memory nahi, DB se actual count
        isLoading: false,
        allCounted: products.isEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Returns true if save successful, false if error
  Future<bool> submitCounting({
    required InventoryProductModel product,
    required double countingStock,
  }) async {
    try {
      final model = InventoryCountingModel(
        productId: product.productId,
        productStock: product.currentStock,
        countingStock: countingStock,
        updatedAt: product.updatedAt,
        countedDate: _todayDate, // ← aaj ki date
      );

      await _datasource.saveInventoryCounting(model);

      final updatedProducts = state.products
          .where((p) => p.productId != product.productId)
          .toList();

      final newCountedCount = state.countedCount + 1;
      final allCounted = updatedProducts.isEmpty;

      state = state.copyWith(
        products: updatedProducts,
        countedCount: newCountedCount,
        allCounted: allCounted,
      );

      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final inventoryCountingProvider = StateNotifierProvider.autoDispose
    .family<InventoryCountingNotifier, InventoryCountingState, String>(
      (ref, storeId) => InventoryCountingNotifier(
    datasource: InventoryCountingRemoteDatasource(),
    storeId: storeId,
  ),
);