// =============================================================
// supplier_report_models.dart
//
// Supplier Report ke saare DATA MODELS + BalanceStatusFilter enum.
//
// Alag file mein isliye taake DONO datasources (local postgres +
// remote Supabase) aur interface (SupplierReportSource) inhe share kar
// sakein. Local datasource inhe re-export karta hai, isliye provider/
// screen ke purane imports waise hi chalte rehte hain.
// =============================================================

// Top summary cards: active suppliers, total outstanding, clear vs
// has-balance counts, aur (date-filtered) total purchased.
class SupplierSummaryData {
  final int totalActive;
  final double totalOutstanding;
  final int clearCount;
  final int hasBalanceCount;
  final double totalPurchased;

  const SupplierSummaryData({
    required this.totalActive,
    required this.totalOutstanding,
    required this.clearCount,
    required this.hasBalanceCount,
    required this.totalPurchased,
  });
}

// Supplier balance table ki ek row (+ outstanding pie). PO aggregation
// (orders/purchased) date filter follow karti hai.
class SupplierBalanceItem {
  final String name;
  final String? phone;
  final String? code;
  final double outstandingBalance;
  final int totalOrders;
  final double totalPurchased;

  const SupplierBalanceItem({
    required this.name,
    this.phone,
    this.code,
    required this.outstandingBalance,
    required this.totalOrders,
    required this.totalPurchased,
  });
}

// Top suppliers by purchase volume — bar chart.
class SupplierPurchaseItem {
  final String name;
  final double totalPurchased;

  const SupplierPurchaseItem({
    required this.name,
    required this.totalPurchased,
  });
}

// Monthly purchase trend — line chart (ek mahina + total received value).
class MonthlyPurchaseData {
  final DateTime month;
  final double total;

  const MonthlyPurchaseData({required this.month, required this.total});
}

// Recent ledger entries — ek supplier-ledger transaction.
class RecentLedgerEntry {
  final String id;
  final String supplierName;
  final String entryType;
  final double amount;
  final double balanceAfter;
  final String? notes;
  final DateTime createdAt;

  const RecentLedgerEntry({
    required this.id,
    required this.supplierName,
    required this.entryType,
    required this.amount,
    required this.balanceAfter,
    this.notes,
    required this.createdAt,
  });

  bool get isCredit => amount < 0;
  bool get isDebit  => amount > 0;

  String get entryTypeLabel {
    switch (entryType) {
      case 'purchase':   return 'Purchase';
      case 'payment':    return 'Payment';
      case 'return':     return 'Return';
      case 'opening':    return 'Opening';
      case 'adjustment': return 'Adjustment';
      default:           return entryType;
    }
  }
}

// Supplier balance table ka filter: sab / sirf jin pe baqaya hai / clear.
enum BalanceStatusFilter { all, outstanding, clear }
