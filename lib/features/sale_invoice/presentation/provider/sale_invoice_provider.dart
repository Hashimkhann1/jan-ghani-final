import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../data/model/sale_invoice_model.dart';

final saleInvoiceProvider = StateNotifierProvider<SaleInvoiceNotifier, SaleInvoiceState>((ref) => SaleInvoiceNotifier(),);

class SaleInvoiceNotifier extends StateNotifier<SaleInvoiceState> {
  SaleInvoiceNotifier() : super(SaleInvoiceState(
    invoiceNo: _generateInvoiceNo(),
    date: DateTime.now(),
    selectedCustomer: Customer.walkIn,
    paymentType: PaymentType.cash,
    saleType: SaleType.sale,
    grandTotalOverride: null,
    cartItems: [],
    customers: dummyCustomers,
    products: dummyProducts,
  ));

  static String _generateInvoiceNo() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  // ── Customer & Payment ───────────────────────────────────────────────────

  void selectCustomer(Customer customer) {
    final paymentType =
    customer.isWalkIn ? PaymentType.cash : PaymentType.credit;
    state = state.copyWith(
        selectedCustomer: customer, paymentType: paymentType);
  }

  void setPaymentType(PaymentType type) => state = state.copyWith(paymentType: type);

  void setSaleType(SaleType type) => state = state.copyWith(saleType: type, grandTotalOverride: null);

  void updateGrandTotal(double val) {
    if (val < 0) return;
    state = state.copyWith(grandTotalOverride: val);
  }


  void addToCart(Product product) {
    final idx =
    state.cartItems.indexWhere((i) => i.product.id == product.id);
    if (idx != -1) {
      final items = [...state.cartItems];
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
      state = state.copyWith(cartItems: items, grandTotalOverride: null);
    } else {
      state = state.copyWith(
        grandTotalOverride: null,
        cartItems: [
          ...state.cartItems,
          CartItem(
            cartId: const Uuid().v4(),
            product: product,
            quantity: 1,
            salePrice: product.price,
          ),
        ],
      );
    }
  }

  void removeFromCart(String cartId) => state = state.copyWith(
    grandTotalOverride: null,
    cartItems: state.cartItems
        .where((i) => i.cartId != cartId)
        .toList(),
  );

  void updateQuantity(String cartId, double qty) {
    if (qty <= 0) return;
    _update(cartId, (i) => i.copyWith(quantity: qty));
  }

  void updateSalePrice(String cartId, double price) {
    if (price < 0) return;
    _update(cartId, (i) => i.copyWith(salePrice: price));
  }

  void updateTax(String cartId, double taxAmount) {
    if (taxAmount < 0) return;
    _update(cartId, (i) => i.copyWith(taxAmount: taxAmount));
  }

  void updateDiscount(String cartId, double discountAmount) {
    if (discountAmount < 0) return;
    _update(cartId, (i) => i.copyWith(discountAmount: discountAmount));
  }

  /// SubTotal edit → Quantity auto-recalculate
  /// Formula: qty = (subTotal - tax + discount) / price
  void updateSubTotal(String cartId, double newSubTotal) {
    if (newSubTotal < 0) return;
    final item =
    state.cartItems.firstWhere((i) => i.cartId == cartId);
    if (item.salePrice <= 0) return;
    final newQty =
        (newSubTotal - item.taxAmount + item.discountAmount) /
            item.salePrice;
    if (newQty <= 0) return;
    _update(cartId, (i) => i.copyWith(quantity: newQty));
  }

  void _update(String cartId, CartItem Function(CartItem) fn) {
    state = state.copyWith(
      grandTotalOverride: null, /// cart change hone par override reset
      cartItems: state.cartItems.map((i) => i.cartId == cartId ? fn(i) : i).toList(),
    );
  }

  void updateSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void clearCart() => state = state.copyWith(
    cartItems: [],
    invoiceNo: _generateInvoiceNo(),
    selectedCustomer: Customer.walkIn,
    paymentType: PaymentType.cash,
    saleType: SaleType.sale,
    grandTotalOverride: null,
    date: DateTime.now(),
  );

  bool saveInvoice() {
    if (state.cartItems.isEmpty) return false;
    clearCart();
    return true;
  }
}