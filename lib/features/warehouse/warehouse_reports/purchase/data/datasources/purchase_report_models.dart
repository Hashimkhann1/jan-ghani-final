// =============================================================
// purchase_report_models.dart
//
// Purchase Report ke saare DATA MODELS (plain Dart classes).
//
// Ye pehle local datasource ke andar the — ab alag file mein isliye
// rakhe gaye hain taake DONO datasources (local postgres + remote
// Supabase RPC) aur interface (PurchaseReportSource) inhe share kar sakein
// bina kisi circular import ke. Local datasource inhe re-export karta hai,
// isliye provider/screen ke purane imports waise hi chalte rehte hain.
//
// Har model report ke ek hisse ko feed karta hai (neeche comment dekhein).
// =============================================================

// Top ke 4 summary cards: total POs, received value, pending count,
// is mahine ki received value.
class PurchaseSummaryData {
  final int    totalPos;
  final double totalReceivedValue;
  final int    pendingCount;
  final double thisMonthValue;

  const PurchaseSummaryData({
    required this.totalPos,
    required this.totalReceivedValue,
    required this.pendingCount,
    required this.thisMonthValue,
  });
}

// PO status pie chart: ek status (received/ordered/...) + uska count.
// `label` UI-friendly naam deta hai.
class PoStatusCount {
  final String status;
  final int    count;

  const PoStatusCount({required this.status, required this.count});

  String get label {
    switch (status) {
      case 'received':  return 'Received';
      case 'ordered':   return 'Ordered';
      case 'partial':   return 'Partial';
      case 'draft':     return 'Draft';
      case 'cancelled': return 'Cancelled';
      default:          return status;
    }
  }
}

// Top suppliers bar chart: ek supplier ka kul PO value.
class SupplierPoValue {
  final String supplierName;
  final double totalValue;

  const SupplierPoValue({required this.supplierName, required this.totalValue});
}

// Monthly trend line chart: ek mahina + us mahine ki received PO value.
class MonthlyPoData {
  final DateTime month;
  final double   total;

  const MonthlyPoData({required this.month, required this.total});
}

// Supplier completion progress bars: ek supplier ka ordered vs received
// (quantity + POs). `completionRate` 0..1 ratio deta hai.
class SupplierCompletionData {
  final String supplierName;
  final double totalOrdered;
  final double totalReceived;
  final int    totalPos;
  final int    receivedPos;

  const SupplierCompletionData({
    required this.supplierName,
    required this.totalOrdered,
    required this.totalReceived,
    required this.totalPos,
    required this.receivedPos,
  });

  double get completionRate =>
      totalOrdered == 0 ? 0 : (totalReceived / totalOrdered).clamp(0, 1);
}

// Recent POs aur Pending POs tables ki ek row. Dono jagah yehi model
// use hota hai (status filter datasource decide karta hai).
class RecentPoEntry {
  final String    poNumber;
  final String?   supplierName;
  final String    status;
  final DateTime  orderDate;
  final DateTime? expectedDate;
  final double    totalAmount;
  final double    paidAmount;

  const RecentPoEntry({
    required this.poNumber,
    this.supplierName,
    required this.status,
    required this.orderDate,
    this.expectedDate,
    required this.totalAmount,
    required this.paidAmount,
  });

  double get remainingAmount =>
      (totalAmount - paidAmount).clamp(0, double.infinity);

  bool get isFullyPaid => remainingAmount <= 0;

  String get statusLabel {
    switch (status) {
      case 'received':  return 'Received';
      case 'ordered':   return 'Ordered';
      case 'partial':   return 'Partial';
      case 'draft':     return 'Draft';
      case 'cancelled': return 'Cancelled';
      default:          return status;
    }
  }
}
