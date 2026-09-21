class SaleReportInvoice {
  final String   id;
  final String   invoiceNo;
  final DateTime invoiceDate;
  final String?  customerName;
  final String?  customerId;
  final String?  cashierName;
  final double   totalAmount;
  final double   totalDiscount;
  final double   grandTotal;
  final String   status;
  final List<String> paymentMethods;
  final List<SaleReportItem> items;

  // New fields
  final double previousAmount;
  final double newAmount;
  final double payAmount;
  final double paidAmount;

  const SaleReportInvoice({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    this.customerName,
    this.customerId,
    this.cashierName,
    required this.totalAmount,
    required this.totalDiscount,
    required this.grandTotal,
    required this.status,
    required this.paymentMethods,
    required this.items,
    this.previousAmount = 0,
    this.newAmount      = 0,
    this.payAmount      = 0,
    this.paidAmount     = 0,
  });

  double get totalQuantity =>
      items.fold(0, (s, i) => s + i.quantity);

  String get customerLabel => customerName ?? 'Walk In';

  String get paymentLabel {
    if (paymentMethods.isEmpty) return '—';
    return paymentMethods
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(', ');
  }
}

class SaleReportItem {
  final String? productId;
  final String  productName;
  final String? sku;
  final double  salePrice;
  final double  purchasePrice;
  final double  quantity;
  final double  discount;
  final double  totalAmount;

  const SaleReportItem({
    this.productId,
    required this.productName,
    this.sku,
    required this.salePrice,
    required this.purchasePrice,
    required this.quantity,
    required this.discount,
    required this.totalAmount,
  });
}

class SaleReportSummary {
  final int    totalInvoices;
  final double totalSale;
  final double totalQuantity;
  final double totalDiscount;

  const SaleReportSummary({
    required this.totalInvoices,
    required this.totalSale,
    required this.totalQuantity,
    required this.totalDiscount,
  });
}

/// Everything the Excel export needs: the full filtered invoice list plus the
/// lookups that turn ids into the branch / category names shown in the sheet.
class SaleReportExportData {
  final List<SaleReportInvoice> invoices;
  final String                  branchName;
  final Map<String, String>     categoryNameByProductId;

  const SaleReportExportData({
    required this.invoices,
    required this.branchName,
    required this.categoryNameByProductId,
  });
}

/// One page of invoices plus whether another page exists after it.
class PagedSaleReport {
  final List<SaleReportInvoice> invoices;
  final bool hasNextPage;

  const PagedSaleReport({
    required this.invoices,
    required this.hasNextPage,
  });
}

class CustomerOption {
  final String  id;
  final String  name;
  final String? code;

  const CustomerOption({
    required this.id,
    required this.name,
    this.code,
  });

  String get label =>
      code != null ? '$name — $code' : name;
}