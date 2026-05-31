// =============================================================
// accountant_order_model.dart
// Accountant ke All Orders feature ke models (read-only)
//   • AccOrderModel      → purchase_orders (+ supplier name)
//   • AccOrderItemModel  → purchase_order_items
// =============================================================

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

DateTime _toDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? DateTime.now();
}

DateTime? _toDateN(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

// ─────────────────────────────────────────────────────────────
// ORDER  (purchase_orders)
// ─────────────────────────────────────────────────────────────
class AccOrderModel {
  final String    id;
  final String    poNumber;
  final String    supplierName;
  final String?   supplierCompany;
  final DateTime  orderDate;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final String    status;
  final double    subtotal;
  final double    discountAmount;
  final double    taxAmount;
  final double    totalAmount;
  final double    paidAmount;
  final String?   notes;
  final String?   createdByName;
  final DateTime  createdAt;

  const AccOrderModel({
    required this.id,
    required this.poNumber,
    required this.supplierName,
    this.supplierCompany,
    required this.orderDate,
    this.expectedDate,
    this.receivedDate,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    this.notes,
    this.createdByName,
    required this.createdAt,
  });

  double get remainingAmount => totalAmount - paidAmount;
  bool   get isFullyPaid     => remainingAmount <= 0;

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

  factory AccOrderModel.fromMap(Map<String, dynamic> map) {
    // Embedded supplier relation
    String supName = 'Unknown';
    String? supCompany;
    final sup = map['suppliers'];
    if (sup is Map) {
      supName = sup['name']?.toString() ?? 'Unknown';
      supCompany = sup['company_name']?.toString();
    } else if (sup is List && sup.isNotEmpty && sup.first is Map) {
      supName = (sup.first as Map)['name']?.toString() ?? 'Unknown';
      supCompany = (sup.first as Map)['company_name']?.toString();
    }

    return AccOrderModel(
      id:              map['id']?.toString() ?? '',
      poNumber:        map['po_number']?.toString() ?? '',
      supplierName:    supName,
      supplierCompany: supCompany,
      orderDate:       _toDate(map['order_date']),
      expectedDate:    _toDateN(map['expected_date']),
      receivedDate:    _toDateN(map['received_date']),
      status:          map['status']?.toString() ?? '',
      subtotal:        _toDouble(map['subtotal']),
      discountAmount:  _toDouble(map['discount_amount']),
      taxAmount:       _toDouble(map['tax_amount']),
      totalAmount:     _toDouble(map['total_amount']),
      paidAmount:      _toDouble(map['paid_amount']),
      notes:           map['notes']?.toString(),
      createdByName:   map['created_by_name']?.toString(),
      createdAt:       _toDate(map['created_at']),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ORDER ITEM  (purchase_order_items)
// ─────────────────────────────────────────────────────────────
class AccOrderItemModel {
  final String  id;
  final String  productName;
  final String? sku;
  final double  quantityOrdered;
  final double  quantityReceived;
  final double  unitCost;
  final double  totalCost;

  const AccOrderItemModel({
    required this.id,
    required this.productName,
    this.sku,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitCost,
    required this.totalCost,
  });

  factory AccOrderItemModel.fromMap(Map<String, dynamic> map) {
    return AccOrderItemModel(
      id:               map['id']?.toString() ?? '',
      productName:      map['product_name']?.toString() ?? 'Unknown',
      sku:              map['sku']?.toString(),
      quantityOrdered:  _toDouble(map['quantity_ordered']),
      quantityReceived: _toDouble(map['quantity_received']),
      unitCost:         _toDouble(map['unit_cost']),
      totalCost:        _toDouble(map['total_cost']),
    );
  }
}
