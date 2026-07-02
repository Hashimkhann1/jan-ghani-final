// ── Ek invoice mein jis product per discount laga, uski detail ─────────
class DiscountReportDetail {
  final String   invoiceId;
  final String   invoiceNo;
  final DateTime invoiceDate;
  final String?  customerName;
  final double   quantity;
  final double   salePrice;
  final double   discount;       // per-item discount amount
  final double   totalAmount;

  const DiscountReportDetail({
    required this.invoiceId,
    required this.invoiceNo,
    required this.invoiceDate,
    this.customerName,
    required this.quantity,
    required this.salePrice,
    required this.discount,
    required this.totalAmount,
  });

  String get customerLabel => customerName ?? 'Walk In';

  // Gross amount discount se pehle (qty * price)
  double get grossAmount => quantity * salePrice;

  double get discountPercent =>
      grossAmount == 0 ? 0 : (discount / grossAmount) * 100;
}

// ── Product wise grouped discount summary ───────────────────────────────
class DiscountReportProduct {
  final String  productName;
  final String? sku;
  final List<DiscountReportDetail> details;

  const DiscountReportProduct({
    required this.productName,
    this.sku,
    required this.details,
  });

  double get totalQuantity =>
      details.fold(0, (s, d) => s + d.quantity);

  double get totalDiscount =>
      details.fold(0, (s, d) => s + d.discount);

  double get totalSaleAmount =>
      details.fold(0, (s, d) => s + d.totalAmount);

  int get invoiceCount =>
      details.map((d) => d.invoiceId).toSet().length;

  double get avgDiscountPercent {
    final gross = details.fold(0.0, (s, d) => s + d.grossAmount);
    return gross == 0 ? 0 : (totalDiscount / gross) * 100;
  }
}

// ── Overall summary (top cards) ─────────────────────────────────────────
class DiscountReportSummary {
  final int    totalProducts;
  final int    totalInvoices;
  final double totalQuantity;
  final double totalDiscountAmount;

  const DiscountReportSummary({
    required this.totalProducts,
    required this.totalInvoices,
    required this.totalQuantity,
    required this.totalDiscountAmount,
  });
}

// ── Customer dropdown option (is feature ke liye alag) ──────────────────
class DiscountReportCustomerOption {
  final String  id;
  final String  name;
  final String? code;

  const DiscountReportCustomerOption({
    required this.id,
    required this.name,
    this.code,
  });

  String get label => code != null ? '$name — $code' : name;
}