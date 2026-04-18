// lib/features/sale_invoice/data/model/sale_invoice_model.dart

import 'package:jan_ghani_final/features/branch/branch_stock_inventory/data/model/branch_stock_model.dart';
import 'package:jan_ghani_final/features/branch/customer/data/model/customer_model.dart';

enum SaleType {
  sale,
  saleReturn;
  String get label => this == SaleType.sale ? 'Sale' : 'Sale Return';
}

// ── Payment Entry (mixed payment support) ─────────────────────
class PaymentEntry {
  final String method; // 'cash' | 'card' | 'credit'
  final double amount;

  const PaymentEntry({required this.method, required this.amount});

  PaymentEntry copyWith({String? method, double? amount}) =>
      PaymentEntry(method: method ?? this.method, amount: amount ?? this.amount);

  Map<String, dynamic> toMap() => {'method': method, 'amount': amount};
}

// ── Cart Item ─────────────────────────────────────────────────
class CartItem {
  final String           cartId;
  final BranchStockModel product;
  final double           quantity;
  final double           salePrice;
  final double           taxAmount;
  final double           discountAmount;

  const CartItem({
    required this.cartId,
    required this.product,
    required this.quantity,
    required this.salePrice,
    this.taxAmount     = 0,
    this.discountAmount = 0,
  });

  double get subTotal => (salePrice * quantity) + taxAmount - discountAmount;

  CartItem copyWith({
    double? quantity,
    double? salePrice,
    double? taxAmount,
    double? discountAmount,
  }) =>
      CartItem(
        cartId:         cartId,
        product:        product,
        quantity:       quantity        ?? this.quantity,
        salePrice:      salePrice       ?? this.salePrice,
        taxAmount:      taxAmount       ?? this.taxAmount,
        discountAmount: discountAmount  ?? this.discountAmount,
      );
}

// ── Sale Invoice State ────────────────────────────────────────
class SaleInvoiceState {
  final String          invoiceNo;
  final DateTime        date;
  final CustomerModel?  selectedCustomer;
  final List<CartItem>  cartItems;
  final String          searchQuery;
  final bool            isSaving;
  final String?         errorMessage;
  final SaleType        saleType;

  // Mixed payments
  final List<PaymentEntry> payments;

  const SaleInvoiceState({
    required this.invoiceNo,
    required this.date,
    this.selectedCustomer,
    required this.cartItems,
    this.searchQuery  = '',
    this.isSaving     = false,
    this.saleType     = SaleType.sale,
    this.errorMessage,
    this.payments     = const [],
  });

  // ── Computed ──────────────────────────────────────────────
  int    get totalItems     => cartItems.length;
  double get totalBeforeTax => cartItems.fold(0, (s, i) => s + (i.salePrice * i.quantity));
  double get totalTax       => cartItems.fold(0, (s, i) => s + i.taxAmount);
  double get totalDiscount  => cartItems.fold(0, (s, i) => s + i.discountAmount);
  double get grandTotal     => cartItems.fold(0, (s, i) => s + i.subTotal);

  // Payment totals
  double get cashAmount   => payments.where((p) => p.method == 'cash').fold(0, (s, p) => s + p.amount);
  double get cardAmount   => payments.where((p) => p.method == 'card').fold(0, (s, p) => s + p.amount);
  double get creditAmount => payments.where((p) => p.method == 'credit').fold(0, (s, p) => s + p.amount);
  double get totalPaid    => payments.fold(0, (s, p) => s + p.amount);
  double get remaining    => grandTotal - totalPaid;

  bool get hasCreditPayment => payments.any((p) => p.method == 'credit' && p.amount > 0);
  bool get isPaymentValid   => (remaining - 0.01) <= 0; // tolerance

  SaleInvoiceState copyWith({
    String?              invoiceNo,
    DateTime?            date,
    CustomerModel?       selectedCustomer,
    bool                 clearCustomer = false,
    List<CartItem>?      cartItems,
    String?              searchQuery,
    bool?                isSaving,
    String?              errorMessage,
    SaleType?            saleType,
    List<PaymentEntry>?  payments,
  }) =>
      SaleInvoiceState(
        invoiceNo:        invoiceNo       ?? this.invoiceNo,
        date:             date            ?? this.date,
        selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
        cartItems:        cartItems       ?? this.cartItems,
        searchQuery:      searchQuery     ?? this.searchQuery,
        isSaving:         isSaving        ?? this.isSaving,
        errorMessage:     errorMessage,
        saleType:         saleType        ?? this.saleType,
        payments:         payments        ?? this.payments,
      );
}