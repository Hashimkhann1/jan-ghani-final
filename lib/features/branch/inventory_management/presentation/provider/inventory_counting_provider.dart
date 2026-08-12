// presentation/provider/inventory_counting_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/inventory_counting_datasource.dart';
import '../../data/model/inventory_countting_model.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class InventoryCountingState {
  final List<InventoryProductModel> products;
  final int countedCount; // aaj kitne count huay (counted today)
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
      // Aaj ka daily batch (fixed 100) — batch minus aaj-counted. Reopen par
      // naye products add nahi hote (strictly 100 per day).
      final products = await _datasource.fetchDailyBatchProducts(storeId);
      // Aaj tak (aaj ke din) kitne count huay — counter/serial ke liye
      final countedToday = await _datasource.fetchCountedTodayCount(storeId);

      state = state.copyWith(
        products: products,
        countedCount: countedToday,
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

  Future<bool> submitCounting({
    required InventoryProductModel product,
    required double countingStock,
  }) async {
    try {
      // Submit ke waqt ka FRESH stock (load-time nahi) — requirement.
      final currentStock =
          await _datasource.fetchCurrentStock(storeId, product.productId);

      final model = InventoryCountingModel(
        productId: product.productId,
        productStock: currentStock,      // submit-time system stock
        countingStock: countingStock,    // user ne jo physical gina
        updatedAt: DateTime.now(),       // count ka waqt (record time)
        countedDate: _todayDate,
        storeId: storeId,
      );

      await _datasource.saveInventoryCounting(model);

      _removeProduct(product, incrementCount: true);
      return true;
    } on PostgrestException catch (e) {
      // Duplicate — ye product aaj pehle hi count ho chuka (unique constraint,
      // shayad doosre device se). Graceful: list se hata do, error nahi.
      if (e.code == '23505') {
        _removeProduct(product, incrementCount: false);
        return true;
      }
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  void _removeProduct(InventoryProductModel product,
      {required bool incrementCount}) {
    final updatedProducts = state.products
        .where((p) => p.productId != product.productId)
        .toList();

    state = state.copyWith(
      products: updatedProducts,
      countedCount:
          incrementCount ? state.countedCount + 1 : state.countedCount,
      allCounted: updatedProducts.isEmpty,
    );
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
