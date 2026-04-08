// =============================================================
// warehouse_dashboard_models.dart
// Warehouse Dashboard ke liye saare domain models
// Schema tables: products, inventory, suppliers, purchase_orders,
//                stock_transfers, stock_movements, supplier_ledger
//                Views: v_reorder_needed, v_pending_transfers,
//                       v_supplier_balances, v_unsynced
// =============================================================

// ─────────────────────────────────────────────────────────────
// 1. DASHBOARD STATS — top 4 summary cards
// ─────────────────────────────────────────────────────────────

class DashboardStats {
  final int    totalProducts;        // products table
  final int    lowStockCount;        // v_reorder_needed
  final int    activeSuppliers;      // suppliers table
  final double totalOutstanding;     // v_supplier_balances SUM
  final int    pendingPOs;           // purchase_orders — draft+ordered+partial
  final int    unsyncedRecords;      // v_unsynced COUNT

  const DashboardStats({
    required this.totalProducts,
    required this.lowStockCount,
    required this.activeSuppliers,
    required this.totalOutstanding,
    required this.pendingPOs,
    required this.unsyncedRecords,
  });
}

// ─────────────────────────────────────────────────────────────
// 2. RECENT PURCHASE ORDER — purchase_orders + suppliers
// ─────────────────────────────────────────────────────────────

class RecentPurchaseOrder {
  final String   id;
  final String   poNumber;       // 'PO-2026-000021'
  final String   supplierName;
  final String   status;         // draft|ordered|partial|received|cancelled
  final double   totalAmount;
  final DateTime orderDate;

  const RecentPurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplierName,
    required this.status,
    required this.totalAmount,
    required this.orderDate,
  });

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
}

// ─────────────────────────────────────────────────────────────
// 3. PENDING TRANSFER — v_pending_transfers view
// ─────────────────────────────────────────────────────────────

class PendingTransfer {
  final String   id;
  final String   transferNumber;   // 'TRF-2026-000012'
  final String   fromLocation;     // 'WH-MAIN'
  final String   toLocation;       // 'STORE-01'
  final String   status;           // requested|approved
  final int      totalItems;
  final double   totalCost;
  final DateTime requestedAt;

  const PendingTransfer({
    required this.id,
    required this.transferNumber,
    required this.fromLocation,
    required this.toLocation,
    required this.status,
    required this.totalItems,
    required this.totalCost,
    required this.requestedAt,
  });

  String get statusLabel => status == 'approved' ? 'Approved' : 'Requested';
}

// ─────────────────────────────────────────────────────────────
// 4. LOW STOCK ITEM — v_reorder_needed view
// ─────────────────────────────────────────────────────────────

class LowStockItem {
  final String productId;
  final String productName;
  final String sku;
  final double currentStock;
  final int    reorderPoint;
  final int?   maxStockLevel;
  final double quantityToOrder;   // max_stock - current

  const LowStockItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.currentStock,
    required this.reorderPoint,
    this.maxStockLevel,
    required this.quantityToOrder,
  });

  // 0.0 to 1.0 — progress bar ke liye
  double get stockPercent {
    final max = maxStockLevel?.toDouble() ?? 100;
    return (currentStock / max).clamp(0.0, 1.0);
  }

  // Critical = 20% se neeche, Low = 40% se neeche
  bool get isCritical => stockPercent < 0.20;
}

// ─────────────────────────────────────────────────────────────
// 5. SUPPLIER DUE — v_supplier_balances view
// ─────────────────────────────────────────────────────────────

class SupplierDue {
  final String supplierId;
  final String supplierName;
  final String companyName;
  final int    paymentTerms;       // credit days
  final double outstandingAmount;

  const SupplierDue({
    required this.supplierId,
    required this.supplierName,
    required this.companyName,
    required this.paymentTerms,
    required this.outstandingAmount,
  });

  // Avatar initials
  String get initials {
    final parts = supplierName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return supplierName.substring(0, 2).toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────
// 6. STOCK MOVEMENT — stock_movements table
// ─────────────────────────────────────────────────────────────

class StockMovementEntry {
  final String   id;
  final String   productName;
  final String   movementType;   // purchase_in|transfer_out|return_in|adjustment
  final String?  referenceType;  // 'purchase' | 'transfer' | 'adjustment'
  final String?  referenceNumber;// PO number ya TRF number
  final double   quantity;       // positive = in, negative = out
  final DateTime createdAt;

  const StockMovementEntry({
    required this.id,
    required this.productName,
    required this.movementType,
    this.referenceType,
    this.referenceNumber,
    required this.quantity,
    required this.createdAt,
  });

  bool get isInward  => quantity > 0;  // purchase_in, return_in
  bool get isOutward => quantity < 0;  // transfer_out

  String get movementLabel {
    switch (movementType) {
      case 'purchase_in':  return 'purchase_in';
      case 'transfer_out': return 'transfer_out';
      case 'return_in':    return 'return_in';
      case 'adjustment':   return 'adjustment';
      default:             return movementType;
    }
  }

  String get timeLabel {
    final h  = createdAt.hour;
    final m  = createdAt.minute.toString().padLeft(2, '0');
    final am = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $am';
  }
}