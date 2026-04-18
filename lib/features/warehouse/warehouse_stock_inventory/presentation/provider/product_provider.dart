// =============================================================
// product_provider.dart
// UPDATED: barcode String? → barcodes List<String>
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/auth/local/auth_local_storage.dart';
import '../../data/datasource/product_remote_datasource.dart';
import '../../data/model/product_model.dart';

// ── State ─────────────────────────────────────────────────────
class ProductState {
  final List<ProductModel> allProducts;
  final String             searchQuery;
  final String             filterStatus;
  final String             filterCategory;
  final bool               isLoading;
  final String?            errorMessage;

  const ProductState({
    this.allProducts    = const [],
    this.searchQuery    = '',
    this.filterStatus   = 'all',
    this.filterCategory = 'all',
    this.isLoading      = false,
    this.errorMessage,
  });

  List<ProductModel> get filteredProducts {
    return allProducts.where((p) {
      if (p.deletedAt != null)                                        return false;
      if (filterStatus   == 'active'   && !p.isActive)               return false;
      if (filterStatus   == 'inactive' &&  p.isActive)               return false;
      if (filterCategory != 'all' && p.categoryId != filterCategory) return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q)              ||
            p.sku.toLowerCase().contains(q)                  ||
            // ← barcodes list mein se koi bhi match ho
            p.barcodes.any((b) => b.toLowerCase().contains(q)) ||
            (p.categoryName?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  int get totalCount    => allProducts.where((p) => p.deletedAt == null).length;
  int get activeCount   => allProducts.where((p) => p.isActive && p.deletedAt == null).length;
  int get lowStockCount => allProducts.where((p) => p.isLowStock && p.deletedAt == null).length;

  ProductState copyWith({
    List<ProductModel>? allProducts, String? searchQuery,
    String? filterStatus, String? filterCategory,
    bool? isLoading, String? errorMessage,
  }) => ProductState(
    allProducts:    allProducts    ?? this.allProducts,
    searchQuery:    searchQuery    ?? this.searchQuery,
    filterStatus:   filterStatus   ?? this.filterStatus,
    filterCategory: filterCategory ?? this.filterCategory,
    isLoading:      isLoading      ?? this.isLoading,
    errorMessage:   errorMessage,
  );
}

// ── Notifier ──────────────────────────────────────────────────
class ProductNotifier extends StateNotifier<ProductState> {
  final ProductRemoteDataSource _ds;
  String get _wid => AppConfig.warehouseId;

  ProductNotifier()
      : _ds = ProductRemoteDataSource(),
        super(const ProductState()) {
    loadProducts();
  }

  Future<({String? id, String? name})> _currentUser() async {
    final userMap = await AuthLocalStorage.loadUser();
    if (userMap == null) return (id: null, name: null);
    return (
    id:   userMap['id']?.toString(),
    name: userMap['full_name']?.toString() ?? userMap['username']?.toString(),
    );
  }

  // ── Load ──────────────────────────────────────────────────
  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final products = await _ds.getAll(_wid);
      state = state.copyWith(allProducts: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Load karne mein masla: $e');
    }
  }

  // ── Add ───────────────────────────────────────────────────
  Future<void> addProduct({
    required String       sku,
    required String       name,
    List<String>          barcodes = const [],   // ← was: String? barcode
    String?               description,
    String?               categoryId,
    required String       unitOfMeasure,
    required double       purchasePrice,
    required double       sellingPrice,
    double?               wholesalePrice,
    required double       taxRate,
    required int          minStockLevel,
    int?                  maxStockLevel,
    required int          reorderPoint,
    required bool         isActive,
    required bool         isTrackStock,
    required double       initialQty,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final exists = await _ds.skuExists(sku, _wid);
      if (exists) {
        state = state.copyWith(
            isLoading: false, errorMessage: 'SKU "$sku" already exists');
        return;
      }

      final user = await _currentUser();
      final product = ProductModel(
        id: '', warehouseId: _wid, sku: sku,
        barcodes: barcodes,                     // ← list
        name: name, description: description,
        categoryId: categoryId,
        unitOfMeasure: unitOfMeasure,
        purchasePrice: purchasePrice, sellingPrice: sellingPrice,
        wholesalePrice: wholesalePrice,
        taxRate: taxRate, minStockLevel: minStockLevel,
        maxStockLevel: maxStockLevel, reorderPoint: reorderPoint,
        isActive: isActive, isTrackStock: isTrackStock,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );

      final saved = await _ds.add(
        product: product, initialQty: initialQty,
        userId: user.id, userName: user.name,
      );
      state = state.copyWith(
          allProducts: [...state.allProducts, saved], isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Add karne mein masla: $e');
    }
  }

  // ── Update ────────────────────────────────────────────────
  Future<void> updateProduct(ProductModel updated, {double? newQty}) async {
    state = state.copyWith(isLoading: true);
    try {
      final exists = await _ds.skuExists(updated.sku, _wid,
          excludeId: updated.id);
      if (exists) {
        state = state.copyWith(
            isLoading: false,
            errorMessage: 'SKU "${updated.sku}" already exists');
        return;
      }

      final oldProduct =
      state.allProducts.firstWhere((p) => p.id == updated.id);
      final user = await _currentUser();

      final fresh = await _ds.update(
        oldProduct: oldProduct, newProduct: updated,
        newQty: newQty ?? updated.quantity,
        userId: user.id, userName: user.name,
      );
      final list = state.allProducts
          .map((p) => p.id == fresh.id ? fresh : p)
          .toList();
      state = state.copyWith(allProducts: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Update karne mein masla: $e');
    }
  }

  // ── Delete ────────────────────────────────────────────────
  Future<void> deleteProduct(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final product = state.allProducts.firstWhere((p) => p.id == id);
      final user    = await _currentUser();

      await _ds.delete(
        id: id, product: product,
        userId: user.id, userName: user.name,
      );
      final updated = state.allProducts
          .map((p) => p.id == id
          ? p.copyWith(deletedAt: DateTime.now()) : p)
          .toList();
      state = state.copyWith(allProducts: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Delete karne mein masla: $e');
    }
  }

  // ── Filters ───────────────────────────────────────────────
  void onSearchChanged(String q)        => state = state.copyWith(searchQuery: q);
  void onFilterStatusChanged(String f)  => state = state.copyWith(filterStatus: f);
  void onFilterCategoryChanged(String c)=> state = state.copyWith(filterCategory: c);
  void clearError()                     => state = state.copyWith(errorMessage: null);
}

// ── Provider ──────────────────────────────────────────────────
final productProvider =
StateNotifierProvider<ProductNotifier, ProductState>(
        (ref) => ProductNotifier());



// // =============================================================
// // product_provider.dart
// // =============================================================
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
// import 'package:jan_ghani_final/core/config/app_config.dart';
// import 'package:jan_ghani_final/features/auth/local/auth_local_storage.dart';
// import '../../data/datasource/product_remote_datasource.dart';
// import '../../data/model/product_model.dart';
//
// // ── State ─────────────────────────────────────────────────────
// class ProductState {
//   final List<ProductModel> allProducts;
//   final String             searchQuery;
//   final String             filterStatus;
//   final String             filterCategory;
//   final bool               isLoading;
//   final String?            errorMessage;
//
//   const ProductState({
//     this.allProducts    = const [],
//     this.searchQuery    = '',
//     this.filterStatus   = 'all',
//     this.filterCategory = 'all',
//     this.isLoading      = false,
//     this.errorMessage,
//   });
//
//   List<ProductModel> get filteredProducts {
//     return allProducts.where((p) {
//       if (p.deletedAt != null)                                        return false;
//       if (filterStatus   == 'active'   && !p.isActive)               return false;
//       if (filterStatus   == 'inactive' &&  p.isActive)               return false;
//       if (filterCategory != 'all' && p.categoryId != filterCategory) return false;
//       if (searchQuery.isNotEmpty) {
//         final q = searchQuery.toLowerCase();
//         return p.name.toLowerCase().contains(q)              ||
//             p.sku.toLowerCase().contains(q)               ||
//             (p.barcode?.toLowerCase().contains(q) ?? false)||
//             (p.categoryName?.toLowerCase().contains(q) ?? false);
//       }
//       return true;
//     }).toList();
//   }
//
//   int get totalCount    => allProducts.where((p) => p.deletedAt == null).length;
//   int get activeCount   => allProducts.where((p) => p.isActive && p.deletedAt == null).length;
//   int get lowStockCount => allProducts.where((p) => p.isLowStock && p.deletedAt == null).length;
//
//   ProductState copyWith({
//     List<ProductModel>? allProducts, String? searchQuery,
//     String? filterStatus, String? filterCategory,
//     bool? isLoading, String? errorMessage,
//   }) => ProductState(
//     allProducts:    allProducts    ?? this.allProducts,
//     searchQuery:    searchQuery    ?? this.searchQuery,
//     filterStatus:   filterStatus   ?? this.filterStatus,
//     filterCategory: filterCategory ?? this.filterCategory,
//     isLoading:      isLoading      ?? this.isLoading,
//     errorMessage:   errorMessage,
//   );
// }
//
// // ── Notifier ──────────────────────────────────────────────────
// class ProductNotifier extends StateNotifier<ProductState> {
//   final ProductRemoteDataSource _ds;
//   String get _wid => AppConfig.warehouseId;
//
//   ProductNotifier()
//       : _ds = ProductRemoteDataSource(),
//         super(const ProductState()) {
//     loadProducts();
//   }
//
//   // Current user SharedPreferences se
//   Future<({String? id, String? name})> _currentUser() async {
//     final userMap = await AuthLocalStorage.loadUser();
//     if (userMap == null) return (id: null, name: null);
//     return (
//     id:   userMap['id']?.toString(),
//     name: userMap['full_name']?.toString() ?? userMap['username']?.toString(),
//     );
//   }
//
//   // ── Load ──────────────────────────────────────────────────
//   Future<void> loadProducts() async {
//     state = state.copyWith(isLoading: true);
//     try {
//       final products = await _ds.getAll(_wid);
//       state = state.copyWith(allProducts: products, isLoading: false);
//     } catch (e) {
//       state = state.copyWith(isLoading: false, errorMessage: 'Load karne mein masla: $e');
//     }
//   }
//
//   // ── Add ───────────────────────────────────────────────────
//   Future<void> addProduct({
//     required String  sku,    required String  name,
//     String?          barcode, String?          description,
//     String?          categoryId,
//     required String  unitOfMeasure,
//     required double  costPrice,   required double  sellingPrice,
//     double?          wholesalePrice, required double  taxRate,
//     required int     minStockLevel,  int?             maxStockLevel,
//     required int     reorderPoint,
//     required bool    isActive,    required bool    isTrackStock,
//     required double  initialQty,
//   }) async {
//     state = state.copyWith(isLoading: true);
//     try {
//       final exists = await _ds.skuExists(sku, _wid);
//       if (exists) {
//         state = state.copyWith(isLoading: false, errorMessage: 'SKU "$sku" already exists');
//         return;
//       }
//
//       final user = await _currentUser();
//       final product = ProductModel(
//         id: '', warehouseId: _wid, sku: sku, barcode: barcode,
//         name: name, description: description, categoryId: categoryId,
//         unitOfMeasure: unitOfMeasure, costPrice: costPrice,
//         sellingPrice: sellingPrice, wholesalePrice: wholesalePrice,
//         taxRate: taxRate, minStockLevel: minStockLevel,
//         maxStockLevel: maxStockLevel, reorderPoint: reorderPoint,
//         isActive: isActive, isTrackStock: isTrackStock,
//         createdAt: DateTime.now(), updatedAt: DateTime.now(),
//       );
//
//       final saved = await _ds.add(
//         product: product, initialQty: initialQty,
//         userId: user.id, userName: user.name,
//       );
//       state = state.copyWith(allProducts: [...state.allProducts, saved], isLoading: false);
//     } catch (e) {
//       state = state.copyWith(isLoading: false, errorMessage: 'Add karne mein masla: $e');
//     }
//   }
//
//   // ── Update ────────────────────────────────────────────────
//   Future<void> updateProduct(ProductModel updated, {double? newQty}) async {
//     state = state.copyWith(isLoading: true);
//     try {
//       final exists = await _ds.skuExists(updated.sku, _wid, excludeId: updated.id);
//       if (exists) {
//         state = state.copyWith(isLoading: false, errorMessage: 'SKU "${updated.sku}" already exists');
//         return;
//       }
//
//       // Old product dhundo
//       final oldProduct = state.allProducts.firstWhere((p) => p.id == updated.id);
//       final user = await _currentUser();
//
//       final fresh = await _ds.update(
//         oldProduct: oldProduct, newProduct: updated,
//         newQty: newQty ?? updated.quantity,
//         userId: user.id, userName: user.name,
//       );
//       final list = state.allProducts.map((p) => p.id == fresh.id ? fresh : p).toList();
//       state = state.copyWith(allProducts: list, isLoading: false);
//     } catch (e) {
//       state = state.copyWith(isLoading: false, errorMessage: 'Update karne mein masla: $e');
//     }
//   }
//
//   // ── Delete ────────────────────────────────────────────────
//   Future<void> deleteProduct(String id) async {
//     state = state.copyWith(isLoading: true);
//     try {
//       final product  = state.allProducts.firstWhere((p) => p.id == id);
//       final user     = await _currentUser();
//
//       await _ds.delete(
//         id: id, product: product,
//         userId: user.id, userName: user.name,
//       );
//       final updated = state.allProducts
//           .map((p) => p.id == id ? p.copyWith(deletedAt: DateTime.now()) : p)
//           .toList();
//       state = state.copyWith(allProducts: updated, isLoading: false);
//     } catch (e) {
//       state = state.copyWith(isLoading: false, errorMessage: 'Delete karne mein masla: $e');
//     }
//   }
//
//   // ── Filters ───────────────────────────────────────────────
//   void onSearchChanged(String q)       => state = state.copyWith(searchQuery: q);
//   void onFilterStatusChanged(String f) => state = state.copyWith(filterStatus: f);
//   void onFilterCategoryChanged(String c)=> state = state.copyWith(filterCategory: c);
//   void clearError()                    => state = state.copyWith(errorMessage: null);
// }
//
// // ── Provider ──────────────────────────────────────────────────
// final productProvider =
// StateNotifierProvider<ProductNotifier, ProductState>(
//         (ref) => ProductNotifier());