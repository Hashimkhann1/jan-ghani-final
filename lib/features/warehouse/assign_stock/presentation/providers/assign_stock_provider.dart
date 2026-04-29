import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/assign_stock_local_datasource.dart';
import '../../data/datasources/assign_stock_remote_datasource.dart';
import '../../data/models/assign_stock_item_model.dart';
import '../../data/models/assign_stock_model.dart';
import '../../data/repositories/assign_stock_repository.dart';

final assignStockRepositoryProvider =
Provider<AssignStockRepository>((ref) {
  return AssignStockRepository(
    local: AssignStockLocalDatasource(db: DatabaseService.connection),
    remote: AssignStockRemoteDatasource(
        supabase: Supabase.instance.client),
  );
});

class AssignStockNotifier extends StateNotifier<AssignStockState> {
  final AssignStockRepository _repo;
  final String _warehouseId;

  AssignStockNotifier(this._repo, this._warehouseId)
      : super(AssignStockState(
    transferNumber: '',
    assignedAt: DateTime.now(),
    cartItems: const [],
    linkedStores: const [],
  )) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final stores = await _repo.getLinkedStores(_warehouseId);
      final number =
      await _repo.generateTransferNumber(_warehouseId);
      state = state.copyWith(
        linkedStores: stores,
        transferNumber: number,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString());
    }
  }

  void selectStore(String storeId, String storeName) {
    state = state.copyWith(
      selectedStoreId: storeId,
      selectedStoreName: storeName,
    );
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  // Product add karo — stock check ke saath
  Future<void> addToCart(ProductModel product) async {
    // Already cart mein hai?
    final exists =
    state.cartItems.any((i) => i.productId == product.id);
    if (exists) return;

    // Stock check
    final enough = await _repo.checkStock(
        product.id, _warehouseId, 1);
    if (!enough) {
      state = state.copyWith(
          errorMessage:
          '${product.name} ka stock available nahi hai!');
      return;
    }

    final item = AssignStockCartItem.fromProduct(product);
    state = state.copyWith(
      cartItems: [...state.cartItems, item],
      clearError: true,
    );
  }

  // Quantity update — ALWAYS save qty to state.
  // Stock check sirf warning ke liye, qty reject nahi hoti.
  // Agar qty > availableStock ho tu Assign button disable hoga.
  Future<void> updateQuantity(String cartId, double qty) async {
    final item =
    state.cartItems.firstWhere((i) => i.cartId == cartId);

    // Pehle qty update karo state mein (taake UI reset na ho)
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) =>
      i.cartId == cartId ? i.copyWith(quantity: qty) : i)
          .toList(),
      clearError: true,
    );

    // Phir stock check karo — sirf warning dikhao
    final enough = await _repo.checkStock(
        item.productId, _warehouseId, qty);
    if (!enough) {
      state = state.copyWith(
          errorMessage:
          '${item.productName} ka sirf ${item.availableStock} ${item.unitOfMeasure} available hai!');
    }
  }

  void updateSalePrice(String cartId, double price) {
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) => i.cartId == cartId
          ? i.copyWith(salePrice: price)
          : i)
          .toList(),
    );
  }

  void updatePurchasePrice(String cartId, double price) {
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) => i.cartId == cartId
          ? i.copyWith(purchasePrice: price)
          : i)
          .toList(),
    );
  }

  void updateTax(String cartId, double tax) {
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) =>
      i.cartId == cartId ? i.copyWith(taxAmount: tax) : i)
          .toList(),
    );
  }

  void updateDiscount(String cartId, double discount) {
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) => i.cartId == cartId
          ? i.copyWith(discountAmount: discount)
          : i)
          .toList(),
    );
  }

  void removeFromCart(String cartId) {
    state = state.copyWith(
      cartItems:
      state.cartItems.where((i) => i.cartId != cartId).toList(),
    );
  }

  void clearCart() {
    state = state.copyWith(
      cartItems: [],
      clearStore: true,
      clearError: true,
    );
  }

  Future<bool> assignStock({
    required String assignedById,
    required String assignedByName,
  }) async {
    if (!state.canSave) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.assignStock(
        warehouseId: _warehouseId,
        transferNumber: state.transferNumber,
        toStoreId: state.selectedStoreId!,
        toStoreName: state.selectedStoreName!,
        assignedById: assignedById,
        assignedByName: assignedByName,
        notes: state.notes,
        items: state.cartItems,
      );

      // Cart clear karo aur new number generate karo
      final newNumber =
      await _repo.generateTransferNumber(_warehouseId);
      state = state.copyWith(
        cartItems: [],
        transferNumber: newNumber,
        clearStore: true,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final assignStockProvider =
StateNotifierProvider<AssignStockNotifier, AssignStockState>(
      (ref) {
    final repo = ref.watch(assignStockRepositoryProvider);
    return AssignStockNotifier(repo, AppConfig.warehouseId);
  },
);



// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:jan_ghani_final/core/config/app_config.dart';
// import 'package:jan_ghani_final/core/service/database_service/database_service.dart';
// import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../data/datasources/assign_stock_local_datasource.dart';
// import '../../data/datasources/assign_stock_remote_datasource.dart';
// import '../../data/models/assign_stock_item_model.dart';
// import '../../data/models/assign_stock_model.dart';
// import '../../data/repositories/assign_stock_repository.dart';
//
// final assignStockRepositoryProvider =
// Provider<AssignStockRepository>((ref) {
//   return AssignStockRepository(
//     local: AssignStockLocalDatasource(db: DatabaseService.connection),
//     remote: AssignStockRemoteDatasource(
//         supabase: Supabase.instance.client),
//   );
// });
//
// class AssignStockNotifier extends StateNotifier<AssignStockState> {
//   final AssignStockRepository _repo;
//   final String _warehouseId;
//
//   AssignStockNotifier(this._repo, this._warehouseId)
//       : super(AssignStockState(
//     transferNumber: '',
//     assignedAt: DateTime.now(),
//     cartItems: const [],
//     linkedStores: const [],
//   )) {
//     _init();
//   }
//
//   Future<void> _init() async {
//     state = state.copyWith(isLoading: true);
//     try {
//       final stores = await _repo.getLinkedStores(_warehouseId);
//       final number =
//       await _repo.generateTransferNumber(_warehouseId);
//       state = state.copyWith(
//         linkedStores: stores,
//         transferNumber: number,
//         isLoading: false,
//       );
//     } catch (e) {
//       state = state.copyWith(
//           isLoading: false, errorMessage: e.toString());
//     }
//   }
//
//   void selectStore(String storeId, String storeName) {
//     state = state.copyWith(
//       selectedStoreId: storeId,
//       selectedStoreName: storeName,
//     );
//   }
//
//   void updateSearch(String query) {
//     state = state.copyWith(searchQuery: query);
//   }
//
//   void updateNotes(String notes) {
//     state = state.copyWith(notes: notes);
//   }
//
//   // Product add karo — stock check ke saath
//   Future<void> addToCart(ProductModel product) async {
//     // Already cart mein hai?
//     final exists =
//     state.cartItems.any((i) => i.productId == product.id);
//     if (exists) return;
//
//     // Stock check
//     final enough = await _repo.checkStock(
//         product.id, _warehouseId, 1);
//     if (!enough) {
//       state = state.copyWith(
//           errorMessage:
//           '${product.name} ka stock available nahi hai!');
//       return;
//     }
//
//     final item = AssignStockCartItem.fromProduct(product);
//     state = state.copyWith(
//       cartItems: [...state.cartItems, item],
//       clearError: true,
//     );
//   }
//
//   // Quantity update — stock check ke saath
//   Future<void> updateQuantity(String cartId, double qty) async {
//     final item =
//     state.cartItems.firstWhere((i) => i.cartId == cartId);
//
//     final enough = await _repo.checkStock(
//         item.productId, _warehouseId, qty);
//     if (!enough) {
//       state = state.copyWith(
//           errorMessage:
//           '${item.productName} ka sirf ${item.availableStock} ${item.unitOfMeasure} available hai!');
//       return;
//     }
//
//     state = state.copyWith(
//       cartItems: state.cartItems
//           .map((i) =>
//       i.cartId == cartId ? i.copyWith(quantity: qty) : i)
//           .toList(),
//       clearError: true,
//     );
//   }
//
//   void updateSalePrice(String cartId, double price) {
//     state = state.copyWith(
//       cartItems: state.cartItems
//           .map((i) => i.cartId == cartId
//           ? i.copyWith(salePrice: price)
//           : i)
//           .toList(),
//     );
//   }
//
//   void updatePurchasePrice(String cartId, double price) {
//     state = state.copyWith(
//       cartItems: state.cartItems
//           .map((i) => i.cartId == cartId
//           ? i.copyWith(purchasePrice: price)
//           : i)
//           .toList(),
//     );
//   }
//
//   void updateTax(String cartId, double tax) {
//     state = state.copyWith(
//       cartItems: state.cartItems
//           .map((i) =>
//       i.cartId == cartId ? i.copyWith(taxAmount: tax) : i)
//           .toList(),
//     );
//   }
//
//   void updateDiscount(String cartId, double discount) {
//     state = state.copyWith(
//       cartItems: state.cartItems
//           .map((i) => i.cartId == cartId
//           ? i.copyWith(discountAmount: discount)
//           : i)
//           .toList(),
//     );
//   }
//
//   void removeFromCart(String cartId) {
//     state = state.copyWith(
//       cartItems:
//       state.cartItems.where((i) => i.cartId != cartId).toList(),
//     );
//   }
//
//   void clearCart() {
//     state = state.copyWith(
//       cartItems: [],
//       clearStore: true,
//       clearError: true,
//     );
//   }
//
//   Future<bool> assignStock({
//     required String assignedById,
//     required String assignedByName,
//   }) async {
//     if (!state.canSave) return false;
//
//     state = state.copyWith(isSaving: true, clearError: true);
//     try {
//       await _repo.assignStock(
//         warehouseId: _warehouseId,
//         transferNumber: state.transferNumber,
//         toStoreId: state.selectedStoreId!,
//         toStoreName: state.selectedStoreName!,
//         assignedById: assignedById,
//         assignedByName: assignedByName,
//         notes: state.notes,
//         items: state.cartItems,
//       );
//
//       // Cart clear karo aur new number generate karo
//       final newNumber =
//       await _repo.generateTransferNumber(_warehouseId);
//       state = state.copyWith(
//         cartItems: [],
//         transferNumber: newNumber,
//         clearStore: true,
//         isSaving: false,
//       );
//       return true;
//     } catch (e) {
//       state = state.copyWith(
//           isSaving: false, errorMessage: e.toString());
//       return false;
//     }
//   }
//
//   void clearError() => state = state.copyWith(clearError: true);
// }
//
// final assignStockProvider =
// StateNotifierProvider<AssignStockNotifier, AssignStockState>(
//       (ref) {
//     final repo = ref.watch(assignStockRepositoryProvider);
//     return AssignStockNotifier(repo, AppConfig.warehouseId);
//   },
// );