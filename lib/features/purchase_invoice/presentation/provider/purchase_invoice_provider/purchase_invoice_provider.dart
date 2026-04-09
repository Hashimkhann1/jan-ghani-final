// =============================================================
// purchase_invoice_provider.dart
// =============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/features/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:uuid/uuid.dart';

final purchaseInvoiceProvider = StateNotifierProvider<
    PurchaseInvoiceNotifier, PurchaseInvoiceState>(
  (ref) => PurchaseInvoiceNotifier(),
);

class PurchaseInvoiceNotifier
    extends StateNotifier<PurchaseInvoiceState> {
  PurchaseInvoiceNotifier()
      : super(PurchaseInvoiceState(
          poNumber:         _generatePoNo(),
          orderDate:        DateTime.now(),
          deliveryDate:     null,
          selectedSupplier: null,
          poType:           PoType.purchase,
          cartItems:        [],
          suppliers:        dummyPoSuppliers,
          products:         dummyPoProducts,
        ));

  static String _generatePoNo() {
    final now = DateTime.now();
    return 'PO-${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  // ── Supplier & Type ─────────────────────────────────────────

  void selectSupplier(PoSupplier supplier) =>
      state = state.copyWith(selectedSupplier: supplier);

  void setPoType(PoType type) =>
      state = state.copyWith(poType: type);

  // ── Dates ────────────────────────────────────────────────────

  void setOrderDate(DateTime date) =>
      state = state.copyWith(orderDate: date);

  void setDeliveryDate(DateTime date) =>
      state = state.copyWith(deliveryDate: date);

  // ── Cart ─────────────────────────────────────────────────────

  void addToCart(PoProduct product) {
    final idx = state.cartItems
        .indexWhere((i) => i.product.id == product.id);
    if (idx != -1) {
      final items = [...state.cartItems];
      items[idx] =
          items[idx].copyWith(quantity: items[idx].quantity + 1);
      state = state.copyWith(cartItems: items);
    } else {
      state = state.copyWith(
        cartItems: [
          ...state.cartItems,
          PoCartItem(
            cartId:        const Uuid().v4(),
            product:       product,
            quantity:      1,
            purchasePrice: product.purchasePrice,
            salePrice:     0, // default 0
          ),
        ],
      );
    }
  }

  void removeFromCart(String cartId) =>
      state = state.copyWith(
        cartItems: state.cartItems
            .where((i) => i.cartId != cartId)
            .toList(),
      );

  void updateQuantity(String cartId, double qty) {
    if (qty <= 0) return;
    _update(cartId, (i) => i.copyWith(quantity: qty));
  }

  void updatePurchasePrice(String cartId, double price) {
    if (price < 0) return;
    _update(cartId, (i) => i.copyWith(purchasePrice: price));
  }

  void updateSalePrice(String cartId, double price) {
    if (price < 0) return;
    _update(cartId, (i) => i.copyWith(salePrice: price));
  }

  void updateTax(String cartId, double tax) {
    if (tax < 0) return;
    _update(cartId, (i) => i.copyWith(taxAmount: tax));
  }

  void updateDiscount(String cartId, double discount) {
    if (discount < 0) return;
    _update(cartId, (i) => i.copyWith(discountAmount: discount));
  }

  /// subTotal edit → qty auto-recalculate
  /// qty = (subTotal - tax + discount) / purchasePrice
  void updateSubTotal(String cartId, double newSubTotal) {
    if (newSubTotal < 0) return;
    final item =
        state.cartItems.firstWhere((i) => i.cartId == cartId);
    if (item.purchasePrice <= 0) return;
    final newQty =
        (newSubTotal - item.taxAmount + item.discountAmount) /
            item.purchasePrice;
    if (newQty <= 0) return;
    _update(cartId, (i) => i.copyWith(quantity: newQty));
  }

  void _update(
      String cartId, PoCartItem Function(PoCartItem) fn) {
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) => i.cartId == cartId ? fn(i) : i)
          .toList(),
    );
  }

  void updateSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void clearCart() => state = state.copyWith(
        cartItems:        [],
        poNumber:         _generatePoNo(),
        selectedSupplier: null,
        poType:           PoType.purchase,
        orderDate:        DateTime.now(),
        clearDeliveryDate: true,
      );

  bool saveInvoice() {
    if (state.cartItems.isEmpty) return false;
    // TODO: Drift se save karo
    clearCart();
    return true;
  }
}
