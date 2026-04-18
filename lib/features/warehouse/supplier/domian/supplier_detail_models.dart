// =============================================================
// supplier_detail_models.dart
// Supplier detail screen ke liye 3 models:
//   1. SupplierLedgerEntry   → supplier_ledger table
//   2. SupplierPurchaseOrder → purchase_orders table
//   3. SupplierFinancialSummary → v_supplier_balances view
// =============================================================

// ─────────────────────────────────────────────────────────────
// 1. LEDGER ENTRY  (supplier_ledger table)
// ─────────────────────────────────────────────────────────────

class SupplierLedgerEntry {
  final String   id;
  final String   supplierId;
  final String?  poId;            // linked PO (nullable)
  final String   entryType;       // 'purchase' | 'payment' | 'return' | 'adjustment'
  final double   amount;          // positive = hum detay hain | negative = payment
  final double   balanceBefore;   // entry se pehle ka balance
  final double   balanceAfter;    // us entry ke baad running balance
  final String?  notes;
  final String?  createdByName;   // user ka naam
  final DateTime createdAt;

  const SupplierLedgerEntry({
    required this.id,
    required this.supplierId,
    this.poId,
    required this.entryType,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.notes,
    this.createdByName,
    required this.createdAt,
  });

  // ── Helpers ───────────────────────────────────────────────

  String get entryTypeLabel {
    switch (entryType) {
      case 'purchase':   return 'Purchase';
      case 'payment':    return 'Payment';
      case 'return':     return 'Return';
      case 'adjustment': return 'Adjustment';
      default:           return entryType;
    }
  }

  bool get isCredit => amount < 0; // payment ya return
  bool get isDebit  => amount > 0; // purchase

  factory SupplierLedgerEntry.fromMap(Map<String, dynamic> map) {
    return SupplierLedgerEntry(
      id:            map['id']              as String,
      supplierId:    map['supplier_id']     as String,
      poId:          map['po_id']           as String?,
      entryType:     map['entry_type']      as String,
      amount:        (map['amount']         as num).toDouble(),
      balanceBefore: (map['balance_before'] as num).toDouble(),
      balanceAfter:  (map['balance_after']  as num).toDouble(),
      notes:         map['notes']           as String?,
      createdByName: map['created_by_name'] as String?,
      createdAt:     DateTime.parse(map['created_at'] as String),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. PURCHASE ORDER  (purchase_orders table)
// ─────────────────────────────────────────────────────────────

class SupplierPurchaseOrder {
  final String    id;
  final String    poNumber;       // 'PO-2026-000001'
  final DateTime  orderDate;
  final DateTime? expectedDate;
  final DateTime? receivedDate;
  final String    status;         // 'draft'|'ordered'|'partial'|'received'|'cancelled'
  final double    subtotal;
  final double    discountAmount;
  final double    taxAmount;
  final double    totalAmount;
  final double    paidAmount;
  final String?   notes;
  final DateTime  createdAt;
  // ── Items — purchase_order_items table se ─────────────────
  // Dialog open hone pe load hoga — default empty list
  final List<PurchaseOrderItem> items;

  const SupplierPurchaseOrder({
    required this.id,
    required this.poNumber,
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
    required this.createdAt,
    this.items = const [], // default empty — lazy load
  });

  // ── Helpers ───────────────────────────────────────────────

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

  factory SupplierPurchaseOrder.fromMap(Map<String, dynamic> map) {
    return SupplierPurchaseOrder(
      id:             map['id']               as String,
      poNumber:       map['po_number']        as String,
      orderDate:      DateTime.parse(map['order_date']     as String),
      expectedDate:   map['expected_date']  != null
          ? DateTime.parse(map['expected_date']  as String) : null,
      receivedDate:   map['received_date']  != null
          ? DateTime.parse(map['received_date']  as String) : null,
      status:         map['status']           as String,
      subtotal:       (map['subtotal']        as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      taxAmount:      (map['tax_amount']      as num).toDouble(),
      totalAmount:    (map['total_amount']    as num).toDouble(),
      paidAmount:     (map['paid_amount']     as num).toDouble(),
      notes:          map['notes']            as String?,
      createdAt:      DateTime.parse(map['created_at']     as String),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. PURCHASE ORDER ITEM  (purchase_order_items table)
// ─────────────────────────────────────────────────────────────

class PurchaseOrderItem {
  final String  id;
  final String  poId;
  final String? productId;       // nullable — product delete ho sakta hai
  final String  productName;     // snapshot — DB se liya gaya naam
  final String? sku;
  final double  quantityOrdered;
  final double  quantityReceived;
  final double  unitCost;
  final double  totalCost;

  const PurchaseOrderItem({
    required this.id,
    required this.poId,
    this.productId,
    required this.productName,
    this.sku,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitCost,
    required this.totalCost,
  });

  // ── Helpers ───────────────────────────────────────────────

  /// Kitna receive hua percentage mein (0.0 to 1.0)
  double get receivedPercent =>
      quantityOrdered == 0 ? 0 : (quantityReceived / quantityOrdered).clamp(0, 1);

  /// Abhi tak kitna baaki hai
  double get quantityPending => (quantityOrdered - quantityReceived).clamp(0, double.infinity);

  /// Fully receive hua?
  bool get isFullyReceived => quantityReceived >= quantityOrdered;

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id:                map['id']                as String,
      poId:              map['po_id']             as String,
      productId:         map['product_id']        as String?,
      productName:       map['product_name']      as String,
      sku:               map['sku']               as String?,
      quantityOrdered:   (map['quantity_ordered'] as num).toDouble(),
      quantityReceived:  (map['quantity_received'] as num).toDouble(),
      unitCost:          (map['unit_cost']        as num).toDouble(),
      totalCost:         (map['total_cost']       as num).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 4. FINANCIAL SUMMARY  (v_supplier_balances + aggregates)
// ─────────────────────────────────────────────────────────────

class SupplierFinancialSummary {
  final double outstandingBalance; // v_supplier_balances view se
  final double totalPurchased;     // sab POs ka total_amount sum
  final double totalPaid;          // sab POs ka paid_amount sum
  final int    totalOrders;        // PO count
  final int    pendingOrders;      // draft + ordered + partial count

  const SupplierFinancialSummary({
    required this.outstandingBalance,
    required this.totalPurchased,
    required this.totalPaid,
    required this.totalOrders,
    required this.pendingOrders,
  });

  double get totalRemaining => totalPurchased - totalPaid;
}