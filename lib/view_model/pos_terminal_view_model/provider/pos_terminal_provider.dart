import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/model/product_model/product_model.dart';
import 'package:jan_ghani_final/utils/constant/enum_constant/enum_constant.dart';
import 'package:riverpod/legacy.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POS PRODUCTS  (value = unit selling price in PKR)
// ─────────────────────────────────────────────────────────────────────────────

const List<ProductModel> posProducts = [
  ProductModel(
    name: 'Coke',
    sku: 'ctp',
    category: 'Beverages',
    stock: 0,
    minStock: 10,
    value: 150,
    status: StockStatus.outOfStock,
    variants: 2,
    initials: 'C',
    image: 'https://images.unsplash.com/photo-1648569883125-d01072540b4c?q=80&w=1336&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  ),
  ProductModel(
    name: 'DBR Growth Boosting Oil',
    sku: 'DBR-9W18RL',
    category: 'DBR',
    stock: 18,
    minStock: 10,
    value: 3000,
    status: StockStatus.inStock,
    initials: 'D',
    image: 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc',
  ),
  ProductModel(
    name: 'DBR Herbal Soap',
    sku: 'DBR-NFPU7C',
    category: 'DBR',
    stock: 14229,
    minStock: 10,
    value: 1500,
    status: StockStatus.overstock,
    initials: 'D',
    image: 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc',
  ),
  ProductModel(
    name: 'DBR Whitening Cream',
    sku: 'DBR-DQLZD8',
    category: 'DBR',
    stock: 345,
    minStock: 10,
    value: 3000,
    status: StockStatus.overstock,
    initials: 'D',
    image: 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc',
  ),
  ProductModel(
    name: 'DBR Zuni Seerum',
    sku: 'DBR-TWGMKH',
    category: 'DBR',
    stock: 30757,
    minStock: 10,
    value: 1500,
    status: StockStatus.overstock,
    initials: 'D',
    image: 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc',
  ),
  ProductModel(
    name: 'safeguard',
    sku: 'SAF-VSLFB0',
    category: 'unileveer',
    stock: 1004,
    minStock: 10,
    value: 120,
    status: StockStatus.overstock,
    initials: 'S',
    image: 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc',
  ),
  ProductModel(
    name: 'Shampoo',
    sku: 'SHA-MWVDFF',
    category: 'unileveer',
    stock: 3595,
    minStock: 10,
    value: 300,
    status: StockStatus.overstock,
    initials: 'S',
    image: 'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc',
  ),
  ProductModel(
    name: 'Sprite 240ml Regular',
    sku: '086',
    category: 'Beverages',
    stock: 28,
    minStock: 10,
    value: 50,
    status: StockStatus.inStock,
    initials: 'S',
    image: 'https://www.coca-cola.com/content/dam/onexp/pk/en/product/sprite-500ml-400x600-new.png',
  ),
  ProductModel(
    name: 'Wifi',
    sku: 'WF-001',
    category: 'HF',
    stock: 872,
    minStock: 0,
    value: 1500,
    status: StockStatus.inStock,
    initials: 'W',
    image: 'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=400&q=80',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// CART ITEM
// ─────────────────────────────────────────────────────────────────────────────

class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  /// unit selling price = product.value
  double get unitPrice => product.value;
  double get total => unitPrice * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}

// ─────────────────────────────────────────────────────────────────────────────
// CART STATE
// ─────────────────────────────────────────────────────────────────────────────

class CartState {
  final List<CartItem> items;
  final String customerName;
  final double discountPercent;
  final double taxRate;
  final String orderNotes;

  const CartState({
    this.items = const [],
    this.customerName = 'Walk-in Customer',
    this.discountPercent = 0,
    this.taxRate = 0.0,
    this.orderNotes = '',
  });

  double get subtotal => items.fold(0, (s, i) => s + i.total);
  double get discountValue => subtotal * discountPercent / 100;
  double get taxAmount => (subtotal - discountValue) * taxRate / 100;
  double get total => subtotal - discountValue + taxAmount;
  int get totalItemCount => items.fold(0, (s, i) => s + i.quantity);

  CartState copyWith({
    List<CartItem>? items,
    String? customerName,
    double? discountPercent,
    double? taxRate,
    String? orderNotes,
  }) =>
      CartState(
        items: items ?? this.items,
        customerName: customerName ?? this.customerName,
        discountPercent: discountPercent ?? this.discountPercent,
        taxRate: taxRate ?? this.taxRate,
        orderNotes: orderNotes ?? this.orderNotes,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CART NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addProduct(ProductModel product) {
    final items = [...state.items];
    final idx = items.indexWhere((i) => i.product.sku == product.sku);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
    } else {
      items.add(CartItem(product: product, quantity: 1));
    }
    state = state.copyWith(items: items);
  }

  void removeProduct(String sku) {
    state = state.copyWith(
        items: state.items.where((i) => i.product.sku != sku).toList());
  }

  void increment(String sku) {
    final items = [...state.items];
    final idx = items.indexWhere((i) => i.product.sku == sku);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
      state = state.copyWith(items: items);
    }
  }

  void decrement(String sku) {
    final items = [...state.items];
    final idx = items.indexWhere((i) => i.product.sku == sku);
    if (idx >= 0) {
      if (items[idx].quantity <= 1) {
        items.removeAt(idx);
      } else {
        items[idx] = items[idx].copyWith(quantity: items[idx].quantity - 1);
      }
      state = state.copyWith(items: items);
    }
  }

  void clearCart() => state = const CartState();

  void setCustomer(String name) => state = state.copyWith(customerName: name);

  void setDiscount(double percent) =>
      state = state.copyWith(discountPercent: percent);

  void setOrderNotes(String notes) =>
      state = state.copyWith(orderNotes: notes);

  void setTaxRate(double rate) => state = state.copyWith(taxRate: rate);
}

// ─────────────────────────────────────────────────────────────────────────────
// POS UI STATE
// ─────────────────────────────────────────────────────────────────────────────

class PosUiState {
  final String searchQuery;
  final String selectedCategory;
  final bool isGridView;

  const PosUiState({
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.isGridView = true,
  });

  PosUiState copyWith({
    String? searchQuery,
    String? selectedCategory,
    bool? isGridView,
  }) =>
      PosUiState(
        searchQuery: searchQuery ?? this.searchQuery,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        isGridView: isGridView ?? this.isGridView,
      );
}

class PosUiNotifier extends StateNotifier<PosUiState> {
  PosUiNotifier() : super(const PosUiState());

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setCategory(String cat) =>
      state = state.copyWith(selectedCategory: cat);
  void setGridView(bool v) => state = state.copyWith(isGridView: v);
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final cartProvider =
StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());

final posUiProvider =
StateNotifierProvider<PosUiNotifier, PosUiState>((ref) => PosUiNotifier());

final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
  final ui = ref.watch(posUiProvider);
  return posProducts.where((p) {
    final matchCat =
        ui.selectedCategory == 'All' || p.category == ui.selectedCategory;
    final q = ui.searchQuery.toLowerCase();
    final matchSearch = q.isEmpty ||
        p.name.toLowerCase().contains(q) ||
        p.sku.toLowerCase().contains(q);
    return matchCat && matchSearch;
  }).toList();
});

final categoriesProvider = Provider<List<String>>((ref) {
  final cats = <String>['All'];
  final seen = <String>{};
  for (final p in posProducts) {
    if (!seen.contains(p.category)) {
      seen.add(p.category);
      cats.add(p.category);
    }
  }
  return cats;
});

final categoryCountProvider = Provider<Map<String, int>>((ref) {
  final map = <String, int>{'All': posProducts.length};
  for (final p in posProducts) {
    map[p.category] = (map[p.category] ?? 0) + 1;
  }
  return map;
});