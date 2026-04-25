// =============================================================
// warehouse_dashboard_models.dart
// =============================================================

enum PurchaseDateFilter {
  today,
  thisWeek,
  thisMonth,
  last3Months,
  custom,
}

class DashboardStats {
  final int    totalProducts;
  final int    lowStockCount;
  final int    activeSuppliers;
  final double totalOutstanding;
  final int    pendingPOs;
  final int    unsyncedRecords;
  final double totalPurchaseAmount;
  final int    totalOrdersCount;

  const DashboardStats({
    required this.totalProducts,
    required this.lowStockCount,
    required this.activeSuppliers,
    required this.totalOutstanding,
    required this.pendingPOs,
    required this.unsyncedRecords,
    required this.totalPurchaseAmount,
    required this.totalOrdersCount,
  });
}

// ── Purchase Trend Chart — ek point (label + amount) ─────────
class PurchaseTrendPoint {
  final String label;   // "Mon", "10 Apr", "9 AM" etc
  final double amount;

  const PurchaseTrendPoint({
    required this.label,
    required this.amount,
  });
}

// ── Supplier Outstanding Chart — ek supplier bar ─────────────
class SupplierOutstandingBar {
  final String supplierId;
  final String supplierName;
  final double outstandingAmount;

  const SupplierOutstandingBar({
    required this.supplierId,
    required this.supplierName,
    required this.outstandingAmount,
  });
}

class RecentPurchaseOrder {
  final String   id;
  final String   poNumber;
  final String   supplierName;
  final String   status;
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

class PendingTransfer {
  final String   id;
  final String   transferNumber;
  final String   fromLocation;
  final String   toLocation;
  final String   status;
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
}

class LowStockItem {
  final String productId;
  final String productName;
  final String sku;
  final double currentStock;
  final int    reorderPoint;
  final int?   maxStockLevel;
  final double quantityToOrder;

  const LowStockItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.currentStock,
    required this.reorderPoint,
    this.maxStockLevel,
    required this.quantityToOrder,
  });

  double get stockPercent {
    final max = maxStockLevel?.toDouble() ?? 100;
    return (currentStock / max).clamp(0.0, 1.0);
  }

  bool get isCritical => stockPercent < 0.20;
}

class SupplierDue {
  final String supplierId;
  final String supplierName;
  final String companyName;
  final int    paymentTerms;
  final double outstandingAmount;

  const SupplierDue({
    required this.supplierId,
    required this.supplierName,
    required this.companyName,
    required this.paymentTerms,
    required this.outstandingAmount,
  });

  String get initials {
    final parts = supplierName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return supplierName.substring(0, 2).toUpperCase();
  }
}

class StockMovementEntry {
  final String   id;
  final String   productName;
  final String   movementType;
  final String?  referenceType;
  final String?  referenceNumber;
  final double   quantity;
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

  bool get isInward  => quantity > 0;
  bool get isOutward => quantity < 0;

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
    final h   = createdAt.hour;
    final m   = createdAt.minute.toString().padLeft(2, '0');
    final am  = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $am';
  }
}