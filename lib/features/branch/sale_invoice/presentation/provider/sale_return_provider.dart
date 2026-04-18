// lib/features/branch/sale_invoice/presentation/provider/sale_return_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jan_ghani_final/features/branch/cash_counter/presentation/provider/cash_counter_provider.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/provider/customer_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../../dashboard/presentation/provider/dashboard_provider.dart';
import '../../data/datasource/sale_return_datasource.dart';
import '../../data/model/sale_invoice_model.dart'; // PaymentEntry
import '../../data/model/sale_return_model.dart';

class SaleReturnNotifier extends StateNotifier<SaleReturnState> {
  final SaleReturnDatasource _ds;
  final Ref                  _ref;

  SaleReturnNotifier(this._ref)
      : _ds = SaleReturnDatasource(),
        super(SaleReturnState(
        returnNo: 'RET-...',
        date:     DateTime.now(),
      )) {
    _initReturnNo();
  }

  String  get _storeId   => _ref.read(authProvider).storeId;
  String? get _counterId => _ref.read(authProvider).counterId;
  String  get _userId    => _ref.read(authProvider).userId;

  Future<void> _initReturnNo() async {
    try {
      final no = await _ds.generateReturnNo(_storeId);
      state = state.copyWith(returnNo: no);
    } catch (_) {}
  }

  // ── Customer ──────────────────────────────────────────────────
  void selectCustomer(CustomerModel? customer) {
    state = state.copyWith(
      selectedCustomer: customer,
      clearCustomer:    customer == null,
    );
    // Customer remove → credit payments bhi remove
    if (customer == null) {
      final updated = state.payments.where((p) => p.method != 'credit').toList();
      state = state.copyWith(payments: updated);
    }
  }

  // ── Cart ───────────────────────────────────────────────────────
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
          ReturnCartItem(
            cartId:      const Uuid().v4(),
            product:     product,
            quantity:    1,
            returnPrice: product.sellingPrice,
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
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) => i.cartId == cartId ? i.copyWith(quantity: qty) : i)
          .toList(),
    );
    _resetPayments();
  }

  void updateReturnPrice(String cartId, double price) {
    if (price < 0) return;
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) => i.cartId == cartId ? i.copyWith(returnPrice: price) : i)
          .toList(),
    );
    _resetPayments();
  }

  void updateDiscount(String cartId, double dis) {
    if (dis < 0) return;
    state = state.copyWith(
      cartItems: state.cartItems
          .map((i) => i.cartId == cartId ? i.copyWith(discountAmount: dis) : i)
          .toList(),
    );
    _resetPayments();
  }

  void updateSearch(String q) => state = state.copyWith(searchQuery: q);

  // ── Payments (same logic as SaleInvoiceNotifier) ───────────────
  void _resetPayments() => state = state.copyWith(payments: []);

  void updatePayment(String method, double amount) {
    if (method == 'credit' && state.selectedCustomer == null) {
      state = state.copyWith(
          errorMessage: 'Credit refund ke liye customer select karein');
      return;
    }
    final existing = state.payments.where((p) => p.method != method).toList();
    if (amount > 0) existing.add(PaymentEntry(method: method, amount: amount));
    state = state.copyWith(payments: existing);
  }

  // ── Save Return ────────────────────────────────────────────────
  Future<bool> saveReturn() async {
    if (state.cartItems.isEmpty) return false;

    if (state.hasCreditPayment && state.selectedCustomer == null) {
      state = state.copyWith(
          errorMessage: 'Credit refund ke liye customer select karein');
      return false;
    }
    if (state.payments.isEmpty) {
      state = state.copyWith(errorMessage: 'Payment method select karein');
      return false;
    }
    if (!state.isPaymentValid) {
      state = state.copyWith(
          errorMessage:
          'Payment total Rs ${state.totalPaid.toStringAsFixed(0)} grand total se match nahi karta');
      return false;
    }
    if (_counterId == null || _counterId!.isEmpty) {
      state = state.copyWith(errorMessage: 'Counter assign nahi — login karein');
      return false;
    }

    state = state.copyWith(isSaving: true);
    try {
      await _ds.saveReturn(
        storeId:       _storeId,
        counterId:     _counterId!,
        userId:        _userId,
        customerId:    state.selectedCustomer?.id,
        returnNo:      state.returnNo,
        refundType:    state.refundTypeForDb, // payments se auto-determine
        totalAmount:   state.totalBeforeTax,
        totalDiscount: state.totalDiscount,
        grandTotal:    state.grandTotal,
        items:         state.cartItems,
        payments:      state.payments,        // ← NEW
      );

      _ref.read(branchStockProvider.notifier).load();
      _ref.read(customerProvider.notifier).loadCustomers();
      _ref.read(cashCounterProvider.notifier).loadRecords();
      _ref.read(dashboardProvider.notifier).load();

      final no = await _ds.generateReturnNo(_storeId);
      state = SaleReturnState(returnNo: no, date: DateTime.now());
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Save error: $e');
      return false;
    }
  }

  void clearCart() {
    state = state.copyWith(
      cartItems:     [],
      searchQuery:   '',
      payments:      [],
      clearCustomer: true,
    );
    _initReturnNo();
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final saleReturnProvider =
StateNotifierProvider<SaleReturnNotifier, SaleReturnState>(
      (ref) => SaleReturnNotifier(ref),
);