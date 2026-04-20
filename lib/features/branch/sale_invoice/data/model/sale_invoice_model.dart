// lib/features/sale_invoice/data/model/sale_invoice_model.dart
// ── MODIFIED: successMessage + CartItem toJson/fromJson added ──

import 'package:jan_ghani_final/features/branch/branch_stock_inventory/data/model/branch_stock_model.dart';
import 'package:jan_ghani_final/features/branch/customer/data/model/customer_model.dart';

enum SaleType {
  sale,
  saleReturn;
  String get label => this == SaleType.sale ? 'Sale' : 'Sale Return';
}

// ── Payment Entry ──────────────────────────────────────────────
class PaymentEntry {
  final String method; // 'cash' | 'card' | 'credit'
  final double amount;

  const PaymentEntry({required this.method, required this.amount});

  PaymentEntry copyWith({String? method, double? amount}) =>
      PaymentEntry(method: method ?? this.method, amount: amount ?? this.amount);

  Map<String, dynamic> toMap() => {'method': method, 'amount': amount};
}

// ── Cart Item ──────────────────────────────────────────────────
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
    this.taxAmount      = 0,
    this.discountAmount = 0,
  });

  double get subTotal =>
      (salePrice * quantity) + taxAmount - discountAmount;

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

  /// ── JSON serialization (for hold/resume) ──────────────────────
  Map<String, dynamic> toJson() => {
    'cartId':         cartId,
    'id':             product.id,
    'storeId':        product.storeId,
    'productId':      product.productId,
    'productName':    product.name,
    'sku':            product.sku,
    'barcode':        product.barcode ?? '',
    'unitOfMeasure':  product.unitOfMeasure,
    'sellingPrice':   product.sellingPrice,
    'costPrice':      product.costPrice,
    'taxRate':        product.taxRate,
    'discount':       product.discount,
    'minStockLevel':  product.minStockLevel,
    'maxStockLevel':  product.maxStockLevel,
    'reorderPoint':   product.reorderPoint,
    'isActive':       product.isActive,
    'isTrackStock':   product.isTrackStock,
    'stock':          product.quantity,
    'reservedQty':    product.reservedQuantity,
    'quantity':       quantity,
    'salePrice':      salePrice,
    'taxAmount':      taxAmount,
    'discountAmount': discountAmount,
  };

  factory CartItem.fromJson(Map<String, dynamic> j) {
    final product = BranchStockModel(
      id:               j['id']              as String? ?? j['productId'] as String,
      storeId:          j['storeId']         as String? ?? '',
      productId:        j['productId']       as String,
      sku:              j['sku']             as String,
      barcode:          j['barcode']         as String?,
      name:             j['productName']     as String,
      unitOfMeasure:    j['unitOfMeasure']   as String? ?? 'pcs',
      costPrice:        (j['costPrice']      as num).toDouble(),
      sellingPrice:     (j['sellingPrice']   as num).toDouble(),
      taxRate:          (j['taxRate']        as num?)?.toDouble() ?? 0.0,
      discount:         (j['discount']       as num?)?.toDouble() ?? 0.0,
      minStockLevel:    (j['minStockLevel']  as num?)?.toInt()    ?? 0,
      maxStockLevel:    (j['maxStockLevel']  as num?)?.toInt()    ?? 0,
      reorderPoint:     (j['reorderPoint']   as num?)?.toInt()    ?? 0,
      isActive:         j['isActive']        as bool?  ?? true,
      isTrackStock:     j['isTrackStock']    as bool?  ?? true,
      quantity:         (j['stock']          as num?)?.toDouble() ?? 0.0,
      reservedQuantity: (j['reservedQty']    as num?)?.toDouble() ?? 0.0,
      updatedAt:        DateTime.now(),
    );
    return CartItem(
      cartId:         j['cartId']         as String,
      product:        product,
      quantity:       (j['quantity']       as num).toDouble(),
      salePrice:      (j['salePrice']      as num).toDouble(),
      taxAmount:      (j['taxAmount']      as num?)?.toDouble() ?? 0,
      discountAmount: (j['discountAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── Sale Invoice State ──────────────────────────────────────────
class SaleInvoiceState {
  final String             invoiceNo;
  final DateTime           date;
  final CustomerModel?     selectedCustomer;
  final List<CartItem>     cartItems;
  final String             searchQuery;
  final bool               isSaving;
  final String?            errorMessage;
  final String?            successMessage;   // ← NEW
  final SaleType           saleType;
  final List<PaymentEntry> payments;

  const SaleInvoiceState({
    required this.invoiceNo,
    required this.date,
    this.selectedCustomer,
    required this.cartItems,
    this.searchQuery   = '',
    this.isSaving      = false,
    this.saleType      = SaleType.sale,
    this.errorMessage,
    this.successMessage,
    this.payments      = const [],
  });

  // ── Computed ──────────────────────────────────────────────────
  int    get totalItems     => cartItems.length;
  double get totalBeforeTax => cartItems.fold(0, (s, i) => s + (i.salePrice * i.quantity));
  double get totalTax       => cartItems.fold(0, (s, i) => s + i.taxAmount);
  double get totalDiscount  => cartItems.fold(0, (s, i) => s + i.discountAmount);
  double get grandTotal     => cartItems.fold(0, (s, i) => s + i.subTotal);

  double get cashAmount   => payments.where((p) => p.method == 'cash').fold(0, (s, p) => s + p.amount);
  double get cardAmount   => payments.where((p) => p.method == 'card').fold(0, (s, p) => s + p.amount);
  double get creditAmount => payments.where((p) => p.method == 'credit').fold(0, (s, p) => s + p.amount);
  double get totalPaid    => payments.fold(0, (s, p) => s + p.amount);
  double get remaining    => grandTotal - totalPaid;
  bool get hasCreditPayment => payments.any((p) => p.method == 'credit' && p.amount > 0);
  bool get isPaymentValid   => (remaining - 0.01) <= 0;

  SaleInvoiceState copyWith({
    String?              invoiceNo,
    DateTime?            date,
    CustomerModel?       selectedCustomer,
    bool                 clearCustomer  = false,
    List<CartItem>?      cartItems,
    String?              searchQuery,
    bool?                isSaving,
    String?              errorMessage,
    String?              successMessage,
    bool                 clearSuccess   = false,
    SaleType?            saleType,
    List<PaymentEntry>?  payments,
  }) =>
      SaleInvoiceState(
        invoiceNo:        invoiceNo        ?? this.invoiceNo,
        date:             date             ?? this.date,
        selectedCustomer: clearCustomer
            ? null
            : (selectedCustomer ?? this.selectedCustomer),
        cartItems:        cartItems        ?? this.cartItems,
        searchQuery:      searchQuery      ?? this.searchQuery,
        isSaving:         isSaving         ?? this.isSaving,
        errorMessage:     errorMessage,
        successMessage:   clearSuccess ? null : (successMessage ?? this.successMessage),
        saleType:         saleType         ?? this.saleType,
        payments:         payments         ?? this.payments,
      );
}