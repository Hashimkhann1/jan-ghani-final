// =============================================================
// purchase_order_model.dart
// UPDATED: discountAmount field added to PurchaseOrderItem
// Schema tables:
//   purchase_orders        — PO head
//   purchase_order_items   — line items (sale_price, discount_amount added)
//   suppliers              — supplier info
//   locations              — destination
// =============================================================

// ─────────────────────────────────────────────────────────────
// PURCHASE ORDER ITEM  (purchase_order_items table)
// ─────────────────────────────────────────────────────────────

class PurchaseOrderItem {
  final String  id;
  final String  poId;
  final String  tenantId;
  final String? productId;        // nullable — product delete ho sakta hai
  final String  productName;      // snapshot
  final String? sku;
  final double  quantityOrdered;
  final double  quantityReceived;
  final double  unitCost;
  final double  totalCost;        // qty × unitCost (discount ke baad)
  final double? salePrice;        // user manually enter karta hai
  final double  discountAmount;   // NAYA — per-item discount (Rs mein)
  final double discountPercent;

  const PurchaseOrderItem({
    required this.id,
    required this.poId,
    required this.tenantId,
    this.productId,
    required this.productName,
    this.sku,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitCost,
    required this.totalCost,
    this.salePrice,
    this.discountAmount = 0,  // default 0
    this.discountPercent = 0,

  });

  // ── Helpers ───────────────────────────────────────────────

  /// Kitna receive hua 0.0 to 1.0
  double get receivedPercent =>
      quantityOrdered == 0
          ? 0
          : (quantityReceived / quantityOrdered).clamp(0, 1);

  /// Abhi tak kitna baaki hai
  double get quantityPending =>
      (quantityOrdered - quantityReceived).clamp(0, double.infinity);

  bool get isFullyReceived => quantityReceived >= quantityOrdered;

  /// Profit per unit — sirf tab jab salePrice set ho
  double? get profitPerUnit =>
      salePrice != null ? salePrice! - unitCost : null;

  /// Margin percentage
  double? get marginPercent =>
      salePrice != null && unitCost > 0
          ? ((salePrice! - unitCost) / unitCost) * 100
          : null;

  /// Total expected revenue
  double? get totalRevenue =>
      salePrice != null ? salePrice! * quantityOrdered : null;

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id:                map['id']                 as String,
      poId:              map['po_id']              as String,
      tenantId:          map['tenant_id']          as String,
      productId:         map['product_id']         as String?,
      productName:       map['product_name']       as String,
      sku:               map['sku']                as String?,
      quantityOrdered:   (map['quantity_ordered']  as num).toDouble(),
      quantityReceived:  (map['quantity_received'] as num).toDouble(),
      unitCost:          (map['unit_cost']         as num).toDouble(),
      totalCost:         (map['total_cost']        as num).toDouble(),
      salePrice:         map['sale_price'] != null
          ? (map['sale_price'] as num).toDouble()
          : null,
      discountAmount: map['discount_amount'] != null
          ? (map['discount_amount'] as num).toDouble()
          : 0,
      discountPercent: map['discount_percent'] != null
          ? (map['discount_percent'] as num).toDouble()
          : 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':                id,
    'po_id':             poId,
    'tenant_id':         tenantId,
    'product_id':        productId,
    'product_name':      productName,
    'sku':               sku,
    'quantity_ordered':  quantityOrdered,
    'quantity_received': quantityReceived,
    'unit_cost':         unitCost,
    'total_cost':        totalCost,
    'sale_price':        salePrice,
    'discount_amount':   discountAmount,
    'discount_percent': discountPercent,

  };

  PurchaseOrderItem copyWith({
    double? quantityOrdered,
    double? quantityReceived,
    double? unitCost,
    double? totalCost,
    double? salePrice,
    double? discountAmount,
    double? discountPercent,
  }) {
    return PurchaseOrderItem(
      id:               id,
      poId:             poId,
      tenantId:         tenantId,
      productId:        productId,
      productName:      productName,
      sku:              sku,
      quantityOrdered:  quantityOrdered  ?? this.quantityOrdered,
      quantityReceived: quantityReceived ?? this.quantityReceived,
      unitCost:         unitCost         ?? this.unitCost,
      totalCost:        totalCost        ?? this.totalCost,
      salePrice:        salePrice        ?? this.salePrice,
      discountAmount:   discountAmount   ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PURCHASE ORDER  (purchase_orders table)
// ─────────────────────────────────────────────────────────────

class PurchaseOrderModel {
  final String    id;
  final String    tenantId;
  final String    poNumber;              // 'PO-2026-000001'
  final String?   supplierId;
  final String?   supplierName;          // joined from suppliers
  final String?   supplierCompany;       // joined from suppliers
  final String?   supplierPhone;         // joined from suppliers
  final String?   supplierAddress;       // joined from suppliers
  final String?   supplierTaxId;         // joined from suppliers
  final int?      supplierPaymentTerms;  // joined from suppliers
  final String    destinationLocationId;
  final String?   destinationName;       // joined from locations
  final String    status;
  final DateTime  orderDate;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final double    subtotal;
  final double    discountAmount;
  final double    taxAmount;
  final double    totalAmount;
  final double    paidAmount;
  final String?   notes;
  final String?   createdByName;         // joined from users
  final DateTime  createdAt;
  final DateTime  updatedAt;
  final List<PurchaseOrderItem> items;

  const PurchaseOrderModel({
    required this.id,
    required this.tenantId,
    required this.poNumber,
    this.supplierId,
    this.supplierName,
    this.supplierCompany,
    this.supplierPhone,
    this.supplierAddress,
    this.supplierTaxId,
    this.supplierPaymentTerms,
    required this.destinationLocationId,
    this.destinationName,
    required this.status,
    required this.orderDate,
    this.expectedDate,
    this.receivedDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    this.notes,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  // ── Helpers ───────────────────────────────────────────────

  double get remainingAmount =>
      (totalAmount - paidAmount).clamp(0, double.infinity);

  bool get isFullyPaid => remainingAmount <= 0;

  /// Paid percentage 0.0 to 1.0 — progress bar ke liye
  double get paidPercent =>
      totalAmount == 0 ? 0 : (paidAmount / totalAmount).clamp(0, 1);

  String get statusLabel {
    switch (status) {
      case 'draft':     return 'Draft';
      case 'ordered':   return 'Ordered';
      case 'partial':   return 'Partial';
      case 'received':  return 'Received';
      case 'cancelled': return 'Cancelled';
      default:          return status;
    }
  }

  /// Supplier ke initials — avatar ke liye
  String get supplierInitials {
    final name = supplierName ?? '??';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  /// Total profit — sirf un items ka jo salePrice set hai
  double get totalProfit {
    double profit = 0;
    for (final item in items) {
      if (item.profitPerUnit != null) {
        profit += item.profitPerUnit! * item.quantityOrdered;
      }
    }
    return profit;
  }

  /// Average margin
  double? get avgMarginPercent {
    final withPrice = items.where((i) => i.salePrice != null).toList();
    if (withPrice.isEmpty) return null;
    final totalMargin = withPrice.fold(
        0.0, (sum, i) => sum + (i.marginPercent ?? 0));
    return totalMargin / withPrice.length;
  }

  /// Kya edit ho sakta hai — status ke hisaab se
  bool get canEdit =>
      status == 'draft' || status == 'ordered' || status == 'partial' || status == 'received';

  bool get canCancel =>
      status == 'draft' || status == 'ordered';

  factory PurchaseOrderModel.fromMap(Map<String, dynamic> map,
      {List<PurchaseOrderItem> items = const []}) {
    return PurchaseOrderModel(
      id:                     map['id']                       as String,
      tenantId:               map['tenant_id']                as String,
      poNumber:               map['po_number']                as String,
      supplierId:             map['supplier_id']              as String?,
      supplierName:           map['supplier_name']            as String?,
      supplierCompany:        map['supplier_company']         as String?,
      supplierPhone:          map['supplier_phone']           as String?,
      supplierAddress:        map['supplier_address']         as String?,
      supplierTaxId:          map['supplier_tax_id']          as String?,
      supplierPaymentTerms:   map['supplier_payment_terms']   as int?,
      destinationLocationId:  map['destination_location_id']  as String,
      destinationName:        map['destination_name']         as String?,
      status:                 map['status']                   as String,
      orderDate:    DateTime.parse(map['order_date']          as String),
      expectedDate: map['expected_date'] != null
          ? DateTime.parse(map['expected_date'] as String) : null,
      receivedDate: map['received_date'] != null
          ? DateTime.parse(map['received_date'] as String) : null,
      subtotal:        (map['subtotal']         as num).toDouble(),
      discountAmount:  (map['discount_amount']  as num).toDouble(),
      taxAmount:       (map['tax_amount']       as num).toDouble(),
      totalAmount:     (map['total_amount']     as num).toDouble(),
      paidAmount:      (map['paid_amount']      as num).toDouble(),
      notes:           map['notes']             as String?,
      createdByName:   map['created_by_name']   as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items:    items,
    );
  }
}