// =============================================================
// accountant_supplier_detail_models.dart
// Supplier detail screen ke models (read-only):
//   1. AccSupplierLedgerEntry   → supplier_ledger (Transactions tab)
//   2. AccSupplierOrder         → purchase_orders  (Orders tab)
//   3. AccSupplierOrderItem     → purchase_order_items
// =============================================================

// ── Helpers ──────────────────────────────────────────────────
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
// 1. LEDGER ENTRY  (supplier_ledger)  →  Transactions tab
// ─────────────────────────────────────────────────────────────
class AccSupplierLedgerEntry {
  final String   id;
  final String?  poId;
  final String   entryType;     // opening | purchase | payment | return | adjustment
  final double   amount;        // + = dena barha | - = payment/return
  final double   balanceAfter;
  final String?  notes;
  final DateTime createdAt;

  const AccSupplierLedgerEntry({
    required this.id,
    this.poId,
    required this.entryType,
    required this.amount,
    required this.balanceAfter,
    this.notes,
    required this.createdAt,
  });

  bool get isCredit => amount < 0; // payment ya return (paisa kam hua)
  bool get isDebit  => amount > 0; // purchase / opening (dena barha)

  String get entryTypeLabel {
    switch (entryType) {
      case 'opening':    return 'Opening Balance';
      case 'purchase':   return 'Purchase';
      case 'payment':    return 'Payment';
      case 'return':     return 'Return';
      case 'adjustment': return 'Adjustment';
      default:           return entryType;
    }
  }

  factory AccSupplierLedgerEntry.fromMap(Map<String, dynamic> map) {
    return AccSupplierLedgerEntry(
      id:           map['id']?.toString() ?? '',
      poId:         map['po_id']?.toString(),
      entryType:    map['entry_type']?.toString() ?? 'adjustment',
      amount:       _toDouble(map['amount']),
      balanceAfter: _toDouble(map['balance_after']),
      notes:        map['notes']?.toString(),
      createdAt:    _toDate(map['created_at']),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. PURCHASE ORDER  (purchase_orders)  →  Orders tab
// ─────────────────────────────────────────────────────────────
class AccSupplierOrder {
  final String    id;
  final String    poNumber;
  final DateTime  orderDate;
  final DateTime? receivedDate;
  final String    status;
  final double    subtotal;
  final double    discountAmount;
  final double    taxAmount;
  final double    totalAmount;
  final double    paidAmount;
  final String?   notes;

  const AccSupplierOrder({
    required this.id,
    required this.poNumber,
    required this.orderDate,
    this.receivedDate,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    this.notes,
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

  factory AccSupplierOrder.fromMap(Map<String, dynamic> map) {
    return AccSupplierOrder(
      id:             map['id']?.toString() ?? '',
      poNumber:       map['po_number']?.toString() ?? '',
      orderDate:      _toDate(map['order_date']),
      receivedDate:   _toDateN(map['received_date']),
      status:         map['status']?.toString() ?? '',
      subtotal:       _toDouble(map['subtotal']),
      discountAmount: _toDouble(map['discount_amount']),
      taxAmount:      _toDouble(map['tax_amount']),
      totalAmount:    _toDouble(map['total_amount']),
      paidAmount:     _toDouble(map['paid_amount']),
      notes:          map['notes']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. PURCHASE ORDER ITEM  (purchase_order_items)
// ─────────────────────────────────────────────────────────────
class AccSupplierOrderItem {
  final String  id;
  final String  productName;
  final String? sku;
  final double  quantityOrdered;
  final double  quantityReceived;
  final double  unitCost;
  final double  totalCost;

  const AccSupplierOrderItem({
    required this.id,
    required this.productName,
    this.sku,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitCost,
    required this.totalCost,
  });

  factory AccSupplierOrderItem.fromMap(Map<String, dynamic> map) {
    return AccSupplierOrderItem(
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

// ─────────────────────────────────────────────────────────────
// 4. FINANCIAL SUMMARY (aggregate — orders se calculate hota hai)
// ─────────────────────────────────────────────────────────────
class AccSupplierSummary {
  final double outstandingBalance;
  final double totalPurchased;
  final double totalPaid;
  final int    totalOrders;
  final int    pendingOrders;

  const AccSupplierSummary({
    required this.outstandingBalance,
    required this.totalPurchased,
    required this.totalPaid,
    required this.totalOrders,
    required this.pendingOrders,
  });
}
