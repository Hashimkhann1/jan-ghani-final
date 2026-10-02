// Updated on 2026-10-02 09:35 AM
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

// ═════════════════════════════════════════════════════════════
// DASHBOARD (Stitch design) — models
// ═════════════════════════════════════════════════════════════

/// Period (filter) ka [start, end) — local time, end exclusive.
class DashboardPeriod {
  final DateTime start;
  final DateTime end;
  const DashboardPeriod(this.start, this.end);

  static DashboardPeriod of(
      PurchaseDateFilter f, DateTime? from, DateTime? to) {
    final n     = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final tmrw  = today.add(const Duration(days: 1));
    switch (f) {
      case PurchaseDateFilter.today:
        return DashboardPeriod(today, tmrw);
      case PurchaseDateFilter.thisWeek:
        return DashboardPeriod(
            today.subtract(Duration(days: today.weekday - 1)), tmrw);
      case PurchaseDateFilter.thisMonth:
        return DashboardPeriod(DateTime(n.year, n.month, 1), tmrw);
      case PurchaseDateFilter.last3Months:
        return DashboardPeriod(DateTime(n.year, n.month - 3, n.day), tmrw);
      case PurchaseDateFilter.custom:
        if (from == null || to == null) return DashboardPeriod(today, tmrw);
        return DashboardPeriod(
          DateTime(from.year, from.month, from.day),
          DateTime(to.year, to.month, to.day).add(const Duration(days: 1)),
        );
    }
  }
}

extension PurchaseDateFilterLabel on PurchaseDateFilter {
  /// KPI label suffix — "Purchases (Today)"
  String get shortLabel {
    switch (this) {
      case PurchaseDateFilter.today:       return 'Today';
      case PurchaseDateFilter.thisWeek:    return 'This Week';
      case PurchaseDateFilter.thisMonth:   return 'This Month';
      case PurchaseDateFilter.last3Months: return '3 Months';
      case PurchaseDateFilter.custom:      return 'Custom';
    }
  }
}

/// KPI cards + "Needs attention" counts — ek query se.
class DashboardSummary {
  final double cashInHand;
  final double periodCashIn;
  final double periodCashOut;     // reversal minus
  final double purchaseAmount;    // received purchase POs (period)
  final int    purchaseCount;
  final double supplierOutstanding;
  final int    suppliersWithDues;
  final double expenseAmount;     // period (salary samet)
  final double salaryAmount;      // period, head = Salary
  final double inventoryValue;    // qty × purchase_price
  final int    activeProducts;
  final int    lowStockCount;
  final int    outOfStockCount;
  final int    pendingPOs;
  final int    pendingTransfers;
  final int    unsyncedRecords;

  const DashboardSummary({
    required this.cashInHand,
    required this.periodCashIn,
    required this.periodCashOut,
    required this.purchaseAmount,
    required this.purchaseCount,
    required this.supplierOutstanding,
    required this.suppliersWithDues,
    required this.expenseAmount,
    required this.salaryAmount,
    required this.inventoryValue,
    required this.activeProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.pendingPOs,
    required this.pendingTransfers,
    required this.unsyncedRecords,
  });
}

/// "Purchases vs Cash out" chart ka ek bucket (ghanta / din / hafta).
class DashboardTrendPoint {
  final String label;
  final double purchases;
  final double cashOut;
  const DashboardTrendPoint({
    required this.label,
    required this.purchases,
    required this.cashOut,
  });
}

/// "Low stock — reorder" table row (available = qty − reserved).
class DashboardLowStockRow {
  final String productName;
  final String sku;
  final String unit;
  final double available;
  final int    reorderPoint;

  const DashboardLowStockRow({
    required this.productName,
    required this.sku,
    required this.unit,
    required this.available,
    required this.reorderPoint,
  });

  /// Reorder point ke muqable kitna stock bacha (0..1)
  double get level => reorderPoint <= 0
      ? 0 : (available / reorderPoint).clamp(0.0, 1.0);
}

/// "Recent stock movements" row — quantity sign type se (in +, out −).
class DashboardMovement {
  final String   id;
  final String   productName;
  final String   movementType;  // purchase_in / transfer_out / return_in / return_out / adjustment / opening
  final String?  reference;     // PO / transfer number
  final double   signedQty;
  final DateTime createdAt;

  const DashboardMovement({
    required this.id,
    required this.productName,
    required this.movementType,
    this.reference,
    required this.signedQty,
    required this.createdAt,
  });
}

/// "Top supplier dues" row
class SupplierDue {
  final String supplierId;
  final String supplierName;
  final int    paymentTerms;      // credit days
  final double outstandingAmount;

  const SupplierDue({
    required this.supplierId,
    required this.supplierName,
    required this.paymentTerms,
    required this.outstandingAmount,
  });
}
