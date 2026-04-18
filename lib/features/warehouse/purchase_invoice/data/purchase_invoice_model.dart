// =============================================================
// purchase_invoice_model.dart
// =============================================================

import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────

enum InvoiceStatus {
  completed,
  pending,
  draft;

  String get label {
    switch (this) {
      case InvoiceStatus.completed: return 'Completed';
      case InvoiceStatus.pending:   return 'Pending';
      case InvoiceStatus.draft:     return 'Draft';
    }
  }

  String get dbValue {
    switch (this) {
      case InvoiceStatus.completed: return 'received';
      case InvoiceStatus.pending:   return 'ordered';
      case InvoiceStatus.draft:     return 'draft';
    }
  }

  IconData get icon {
    switch (this) {
      case InvoiceStatus.completed: return Icons.check_circle_outline;
      case InvoiceStatus.pending:   return Icons.hourglass_empty_rounded;
      case InvoiceStatus.draft:     return Icons.edit_note_outlined;
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.completed: return const Color(0xFF22C55E);
      case InvoiceStatus.pending:   return const Color(0xFFF59E0B);
      case InvoiceStatus.draft:     return const Color(0xFF94A3B8);
    }
  }
}

enum PoType {
  purchase,
  purchaseReturn;

  String get label {
    switch (this) {
      case PoType.purchase:       return 'Purchase';
      case PoType.purchaseReturn: return 'Purchase Return';
    }
  }
}

// ── Supplier ──────────────────────────────────────────────────

class PoSupplier {
  final String id;
  final String name;
  final String company;
  final String phone;
  final int    paymentTerms;

  const PoSupplier({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.paymentTerms,
  });

  String get initials => name
      .split(' ')
      .take(2)
      .map((w) => w[0])
      .join()
      .toUpperCase();
}

// ── Purchase Product ──────────────────────────────────────────

class PoProduct {
  final String id;
  final String name;
  final String category;
  final String sku;
  final double purchasePrice;
  final double salePrice;
  final double stock;

  const PoProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.purchasePrice,
    required this.salePrice,
    required this.stock,
  });
}

// ── Purchase Cart Item ────────────────────────────────────────

class PoCartItem {
  final String    cartId;
  final PoProduct product;
  final double    quantity;
  final double    purchasePrice;
  final double    salePrice;
  final double    taxAmount;
  final double    discountAmount;

  const PoCartItem({
    required this.cartId,
    required this.product,
    required this.quantity,
    required this.purchasePrice,
    this.salePrice      = 0,
    this.taxAmount      = 0,
    this.discountAmount = 0,
  });

  // subTotal = (purchasePrice × qty) + tax - discount
  double get subTotal =>
      (purchasePrice * quantity) + taxAmount - discountAmount;

  double? get marginPercent =>
      salePrice > 0 && purchasePrice > 0
          ? ((salePrice - purchasePrice) / purchasePrice) * 100
          : null;

  PoCartItem copyWith({
    double? quantity,
    double? purchasePrice,
    double? salePrice,
    double? taxAmount,
    double? discountAmount,
  }) {
    return PoCartItem(
      cartId:         cartId,
      product:        product,
      quantity:       quantity       ?? this.quantity,
      purchasePrice:  purchasePrice  ?? this.purchasePrice,
      salePrice:      salePrice      ?? this.salePrice,
      taxAmount:      taxAmount      ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}

// ── State ─────────────────────────────────────────────────────

class PurchaseInvoiceState {
  final String           poNumber;
  final DateTime         orderDate;
  final DateTime?        deliveryDate;
  final PoSupplier?      selectedSupplier;
  final PoType           poType;
  final InvoiceStatus    invoiceStatus;
  final double           paidAmount;
  final String?          createdById;
  final String?          createdByName;
  final List<PoCartItem> cartItems;
  final List<PoSupplier> suppliers;
  final List<PoProduct>  products;
  final String           searchQuery;

  const PurchaseInvoiceState({
    required this.poNumber,
    required this.orderDate,
    this.deliveryDate,
    required this.selectedSupplier,
    required this.poType,
    this.invoiceStatus  = InvoiceStatus.completed,
    this.paidAmount     = 0,
    this.createdById,
    this.createdByName,
    required this.cartItems,
    required this.suppliers,
    required this.products,
    this.searchQuery = '',
  });

  List<PoProduct> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    final q = searchQuery.toLowerCase();
    return products
        .where((p) =>
    p.name.toLowerCase().contains(q) ||
        p.sku.toLowerCase().contains(q))
        .toList();
  }

  int    get totalItems     => cartItems.length;
  double get totalBeforeTax => cartItems.fold(
      0.0, (sum, i) => sum + (i.purchasePrice * i.quantity));
  double get totalTax =>
      cartItems.fold(0.0, (sum, i) => sum + i.taxAmount);
  double get totalDiscount =>
      cartItems.fold(0.0, (sum, i) => sum + i.discountAmount);
  double get grandTotal =>
      totalBeforeTax + totalTax - totalDiscount;
  double get totalProfit {
    double p = 0;
    for (final item in cartItems) {
      if (item.salePrice > 0) {
        p += (item.salePrice - item.purchasePrice) * item.quantity;
      }
    }
    return p;
  }

  bool get hasPriceError => cartItems.any(
        (i) => i.salePrice > 0 && i.purchasePrice > i.salePrice,
  );

  PurchaseInvoiceState copyWith({
    String?           poNumber,
    DateTime?         orderDate,
    DateTime?         deliveryDate,
    PoSupplier?       selectedSupplier,
    PoType?           poType,
    InvoiceStatus?    invoiceStatus,
    double?           paidAmount,
    String?           createdById,
    String?           createdByName,
    List<PoCartItem>? cartItems,
    List<PoSupplier>? suppliers,
    List<PoProduct>?  products,
    String?           searchQuery,
    bool              clearDeliveryDate   = false,
    bool              clearSelectedSupplier = false,
  }) {
    return PurchaseInvoiceState(
      poNumber:         poNumber         ?? this.poNumber,
      orderDate:        orderDate        ?? this.orderDate,
      deliveryDate:     clearDeliveryDate
          ? null : (deliveryDate ?? this.deliveryDate),
      selectedSupplier: clearSelectedSupplier
          ? null : (selectedSupplier ?? this.selectedSupplier),
      poType:           poType           ?? this.poType,
      invoiceStatus:    invoiceStatus    ?? this.invoiceStatus,
      paidAmount:       paidAmount       ?? this.paidAmount,
      createdById:      createdById      ?? this.createdById,
      createdByName:    createdByName    ?? this.createdByName,
      cartItems:        cartItems        ?? this.cartItems,
      suppliers:        suppliers        ?? this.suppliers,
      products:         products         ?? this.products,
      searchQuery:      searchQuery      ?? this.searchQuery,
    );
  }
}

// ── Dummy Products (suppliers ab DB se aate hain) ─────────────

final dummyPoProducts = [
  const PoProduct(
      id: 'P01', name: 'Sunflower Oil 1L',
      category: 'Cooking Oil', sku: 'SKU-001',
      purchasePrice: 480, salePrice: 650, stock: 18),
  const PoProduct(
      id: 'P02', name: 'Basmati Rice 5kg',
      category: 'Rice',        sku: 'SKU-012',
      purchasePrice: 650, salePrice: 850, stock: 12),
  const PoProduct(
      id: 'P03', name: 'Surf Excel 1kg',
      category: 'Detergent',   sku: 'SKU-034',
      purchasePrice: 320, salePrice: 420, stock: 32),
  const PoProduct(
      id: 'P04', name: 'Nestle Milk 1L',
      category: 'Dairy',       sku: 'SKU-056',
      purchasePrice: 145, salePrice: 190, stock: 40),
  const PoProduct(
      id: 'P05', name: 'Tapal Danedar 500g',
      category: 'Tea',         sku: 'SKU-078',
      purchasePrice: 350, salePrice: 480, stock: 25),
  const PoProduct(
      id: 'P06', name: 'Colgate 150g',
      category: 'Personal',    sku: 'SKU-103',
      purchasePrice: 185, salePrice: 240, stock: 60),
  const PoProduct(
      id: 'P07', name: 'Knorr Noodles 72g',
      category: 'Food',        sku: 'SKU-115',
      purchasePrice: 40,  salePrice: 55,  stock: 200),
  const PoProduct(
      id: 'P08', name: 'Dates Box 1kg',
      category: 'Dry Fruit',   sku: 'SKU-092',
      purchasePrice: 850, salePrice: 1100, stock: 5),
];