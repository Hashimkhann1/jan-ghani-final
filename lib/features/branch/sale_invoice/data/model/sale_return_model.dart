// lib/features/branch/sale_invoice/data/model/sale_return_model.dart

import 'package:jan_ghani_final/features/branch/branch_stock_inventory/data/model/branch_stock_model.dart';
import 'package:jan_ghani_final/features/branch/customer/data/model/customer_model.dart';
import 'sale_invoice_model.dart'; // PaymentEntry reuse

// RefundType enum — ab sirf datasource ke liye internally use hoga
// UI mein nahi dikhega
enum RefundType {
  cash,
  exchange,
  credit;

  String get label => switch (this) {
    RefundType.cash     => 'Cash Refund',
    RefundType.exchange => 'Exchange',
    RefundType.credit   => 'Credit',
  };
}

class ReturnCartItem {
  final String           cartId;
  final BranchStockModel product;
  final double           quantity;
  final double           returnPrice;
  final double           discountAmount;

  const ReturnCartItem({
    required this.cartId,
    required this.product,
    required this.quantity,
    required this.returnPrice,
    this.discountAmount = 0,
  });

  double get subTotal => returnPrice * quantity - discountAmount;

  ReturnCartItem copyWith({
    double? quantity,
    double? returnPrice,
    double? discountAmount,
  }) =>
      ReturnCartItem(
        cartId:         cartId,
        product:        product,
        quantity:       quantity       ?? this.quantity,
        returnPrice:    returnPrice    ?? this.returnPrice,
        discountAmount: discountAmount ?? this.discountAmount,
      );
}

class SaleReturnState {
  final String               returnNo;
  final DateTime             date;
  final CustomerModel?       selectedCustomer;
  final List<ReturnCartItem> cartItems;
  final String               searchQuery;
  final bool                 isSaving;
  final String?              errorMessage;

  // ── Payment entries — same as SaleInvoiceState ──────────────
  final List<PaymentEntry>   payments;

  const SaleReturnState({
    required this.returnNo,
    required this.date,
    this.selectedCustomer,
    this.cartItems    = const [],
    this.searchQuery  = '',
    this.isSaving     = false,
    this.errorMessage,
    this.payments     = const [],
  });

  // ── Computed ──────────────────────────────────────────────────
  int    get totalItems     => cartItems.length;
  double get totalBeforeTax => cartItems.fold(0, (s, i) => s + (i.returnPrice * i.quantity));
  double get totalDiscount  => cartItems.fold(0, (s, i) => s + i.discountAmount);
  double get grandTotal     => cartItems.fold(0, (s, i) => s + i.subTotal);

  // Payment totals — same as invoice
  double get cashAmount   => payments.where((p) => p.method == 'cash').fold(0, (s, p) => s + p.amount);
  double get cardAmount   => payments.where((p) => p.method == 'card').fold(0, (s, p) => s + p.amount);
  double get creditAmount => payments.where((p) => p.method == 'credit').fold(0, (s, p) => s + p.amount);
  double get totalPaid    => payments.fold(0, (s, p) => s + p.amount);
  double get remaining    => grandTotal - totalPaid;

  bool get hasCreditPayment => payments.any((p) => p.method == 'credit' && p.amount > 0);
  bool get isPaymentValid   => remaining.abs() < 0.01;

  /// Payments se refund_type determine karta hai (DB ke liye)
  String get refundTypeForDb {
    final methods = payments.where((p) => p.amount > 0).map((p) => p.method).toSet();
    if (methods.length > 1)     return 'mixed';
    if (methods.contains('cash'))   return 'cash';
    if (methods.contains('card'))   return 'card';
    if (methods.contains('credit')) return 'credit';
    return 'cash'; // fallback
  }

  SaleReturnState copyWith({
    String?               returnNo,
    DateTime?             date,
    CustomerModel?        selectedCustomer,
    bool                  clearCustomer = false,
    List<ReturnCartItem>? cartItems,
    String?               searchQuery,
    bool?                 isSaving,
    String?               errorMessage,
    List<PaymentEntry>?   payments,
  }) =>
      SaleReturnState(
        returnNo:         returnNo         ?? this.returnNo,
        date:             date             ?? this.date,
        selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
        cartItems:        cartItems        ?? this.cartItems,
        searchQuery:      searchQuery      ?? this.searchQuery,
        isSaving:         isSaving         ?? this.isSaving,
        errorMessage:     errorMessage,
        payments:         payments         ?? this.payments,
      );
}