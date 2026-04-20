// lib/features/sale_invoice/presentation/provider/sale_invoice_provider.dart
// ── MODIFIED: hold/resume support added ──────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/features/branch/dashboard/presentation/provider/dashboard_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../../cash_counter/presentation/provider/cash_counter_provider.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../../customer/presentation/provider/customer_provider.dart';
import '../../data/datasource/sale_invoice_datasource.dart';
import '../../data/model/held_invoice_model.dart';
import '../../data/model/sale_invoice_model.dart';
import 'held_invoice_provider.dart';

class SaleInvoiceNotifier extends StateNotifier<SaleInvoiceState> {
  final SaleInvoiceDatasource _ds;
  final Ref                   _ref;

  SaleInvoiceNotifier(this._ref)
      : _ds = SaleInvoiceDatasource(),
        super(SaleInvoiceState(
        invoiceNo: 'INV-...',
        date:      DateTime.now(),
        cartItems: [],
        payments:  [],
      )) {
    _initInvoiceNo();
  }

  String  get _storeId   => _ref.read(authProvider).storeId;
  String? get _counterId => _ref.read(authProvider).counterId;
  String  get _userId    => _ref.read(authProvider).userId;

  // ── Init invoice number ───────────────────────────────────────
  Future<void> _initInvoiceNo() async {
    try {
      final no = await _ds.generateInvoiceNo(_storeId);
      state = state.copyWith(invoiceNo: no);
    } catch (_) {
      final now = DateTime.now();
      state = state.copyWith(
        invoiceNo: 'INV-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}',
      );
    }
  }

  // ── Customer ──────────────────────────────────────────────────
  void selectCustomer(CustomerModel? customer) {
    state = state.copyWith(
      selectedCustomer: customer,
      clearCustomer:    customer == null,
    );
    if (customer == null) {
      final updatedPayments =
      state.payments.where((p) => p.method != 'credit').toList();
      state = state.copyWith(payments: updatedPayments);
    }
  }

  // ── Cart ──────────────────────────────────────────────────────

  /// Barcode/SKU exact match se product add karo (scanner ke liye)
  bool addToCartByBarcode(String query) {
    final allProducts =
        _ref.read(branchStockProvider).allProducts;

    // Exact barcode match first
    BranchStockModel? found;
    found = allProducts.cast<BranchStockModel?>().firstWhere(
          (p) =>
      p!.barcode != null &&
          p.barcode!.toLowerCase() == query.toLowerCase(),
      orElse: () => null,
    );

    // Exact SKU match fallback
    found ??= allProducts.cast<BranchStockModel?>().firstWhere(
          (p) => p!.sku.toLowerCase() == query.toLowerCase(),
      orElse: () => null,
    );

    if (found == null) return false;
    addToCart(found);
    return true;
  }

  void addToCart(BranchStockModel product) {
    final idx = state.cartItems
        .indexWhere((i) => i.product.productId == product.productId);

    if (idx != -1) {
      final items = [...state.cartItems];
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
      state = state.copyWith(cartItems: items);
    } else {
      state = state.copyWith(
        cartItems: [
          ...state.cartItems,
          CartItem(
            cartId:         const Uuid().v4(),
            product:        product,
            quantity:       1,
            salePrice:      product.sellingPrice,
            taxAmount:      0,
            discountAmount: 0,
          ),
        ],
      );
    }
    _resetPayments();
  }

  void removeFromCart(String cartId) {
    state = state.copyWith(
      cartItems: state.cartItems.where((i) => i.cartId != cartId).toList(),
    );
    _resetPayments();
  }

  void updateQuantity(String cartId, double qty) {
    if (qty <= 0) return;
    _update(cartId, (i) => i.copyWith(quantity: qty));
    _resetPayments();
  }

  void updateSalePrice(String cartId, double price) {
    if (price < 0) return;
    _update(cartId, (i) => i.copyWith(salePrice: price));
    _resetPayments();
  }

  void updateTax(String cartId, double tax) {
    if (tax < 0) return;
    _update(cartId, (i) => i.copyWith(taxAmount: tax));
    _resetPayments();
  }

  void updateDiscount(String cartId, double dis) {
    if (dis < 0) return;
    _update(cartId, (i) => i.copyWith(discountAmount: dis));
    _resetPayments();
  }

  void updateSubTotal(String cartId, double newSubTotal) {
    if (newSubTotal < 0) return;
    final item = state.cartItems.firstWhere((i) => i.cartId == cartId);
    if (item.salePrice <= 0) return;
    final newQty =
        (newSubTotal - item.taxAmount + item.discountAmount) / item.salePrice;
    if (newQty <= 0) return;
    _update(cartId, (i) => i.copyWith(quantity: newQty));
    _resetPayments();
  }

  void _update(String cartId, CartItem Function(CartItem) fn) {
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) => i.cartId == cartId ? fn(i) : i)
          .toList(),
    );
  }

  void updateSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  // ── Payments ──────────────────────────────────────────────────
  void _resetPayments() => state = state.copyWith(payments: []);

  updatePayment(String method, double amount) {
    if (method == 'credit' && state.selectedCustomer == null) {
      state = state.copyWith(
          errorMessage: 'Credit payment ke liye customer select karein');
      return;
    }
    final existing =
    state.payments.where((p) => p.method != method).toList();
    if (amount > 0) existing.add(PaymentEntry(method: method, amount: amount));
    state = state.copyWith(payments: existing);
  }

  void setQuickPayment(String method) {
    if (method == 'credit' && state.selectedCustomer == null) {
      state = state.copyWith(
          errorMessage: 'Credit payment ke liye customer select karein');
      return;
    }
    state = state.copyWith(
      payments: [PaymentEntry(method: method, amount: state.grandTotal)],
    );
  }

  // ── Hold Invoice ──────────────────────────────────────────────
  /// Current invoice ko hold mein dalo aur naya start karo
  Future<void> holdCurrentInvoice({String? label}) async {
    if (state.cartItems.isEmpty) return;

    await _ref.read(heldInvoicesProvider.notifier).holdInvoice(
      invoiceNo:  state.invoiceNo,
      customer:   state.selectedCustomer,
      items:      state.cartItems,
      grandTotal: state.grandTotal,
      label:      label,
    );

    // Naya clean invoice start karo
    await _clearAndReset();
    state = state.copyWith(successMessage: 'Invoice hold kar diya gaya');
  }

  /// Held invoice resume karo
  Future<void> resumeHeldInvoice(HeldInvoice held) async {
    // Agar current cart mein kuch hai to pehle usse bhi hold karo
    if (state.cartItems.isNotEmpty) {
      await holdCurrentInvoice(label: 'Auto-held');
    }

    // Held invoice restore karo
    state = SaleInvoiceState(
      invoiceNo:        held.invoiceNo,
      date:             held.heldAt,
      selectedCustomer: held.customer,
      cartItems:        List.from(held.cartItems),
      payments:         [],
    );

    // Hold release karo (DB + memory)
    await _ref
        .read(heldInvoicesProvider.notifier)
        .releaseHold(held.id, discard: false);
  }

  // ── Save Invoice ──────────────────────────────────────────────
  Future<bool> saveInvoice() async {
    if (state.cartItems.isEmpty) return false;

    if (state.hasCreditPayment && state.selectedCustomer == null) {
      state = state.copyWith(
          errorMessage: 'Credit payment ke liye customer select karein');
      return false;
    }
    if (state.payments.isEmpty) {
      state = state.copyWith(errorMessage: 'Payment method select karein');
      return false;
    }
    if (!state.isPaymentValid) {
      state = state.copyWith(
          errorMessage:
          'Payment total Rs ${state.totalPaid.toStringAsFixed(0)} grand total '
              'Rs ${state.grandTotal.toStringAsFixed(0)} se match nahi karta');
      return false;
    }
    if (_counterId == null || _counterId!.isEmpty) {
      state =
          state.copyWith(errorMessage: 'Counter assign nahi — login karein');
      return false;
    }

    state = state.copyWith(isSaving: true);
    try {
      await _ds.saveInvoice(
        storeId:       _storeId,
        counterId:     _counterId!,
        userId:        _userId,
        customerId:    state.selectedCustomer?.id,
        invoiceNo:     state.invoiceNo,
        totalAmount:   state.totalBeforeTax,
        totalDiscount: state.totalDiscount,
        grandTotal:    state.grandTotal,
        items:         state.cartItems,
        payments:      state.payments,
      );

      _ref.read(branchStockProvider.notifier).load();
      _ref.read(customerProvider.notifier).loadCustomers();
      _ref.read(cashCounterProvider.notifier).loadRecords();
      _ref.read(dashboardProvider.notifier).load();

      await _clearAndReset();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Save error: $e');
      return false;
    }
  }

  Future<void> _clearAndReset() async {
    final no = await _ds.generateInvoiceNo(_storeId);
    state = SaleInvoiceState(
      invoiceNo: no,
      date:      DateTime.now(),
      cartItems: [],
      payments:  [],
    );
  }

  void clearCart() {
    state = state.copyWith(
      cartItems:     [],
      clearCustomer: true,
      searchQuery:   '',
      payments:      [],
    );
    _initInvoiceNo();
  }

  void setSaleType(SaleType type) =>
      state = state.copyWith(saleType: type);

  void clearError() =>
      state = state.copyWith(errorMessage: null, clearSuccess: true);

  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}

final saleInvoiceProvider =
StateNotifierProvider<SaleInvoiceNotifier, SaleInvoiceState>(
      (ref) => SaleInvoiceNotifier(ref),
);