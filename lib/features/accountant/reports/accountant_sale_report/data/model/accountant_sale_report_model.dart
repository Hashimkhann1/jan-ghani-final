class SaleReportInvoice {
  final String   id;
  final String   invoiceNo;
  final DateTime invoiceDate;
  final String?  customerName;
  final String?  customerId;
  final double   totalAmount;
  final double   totalDiscount;
  final double   grandTotal;
  final String   status;
  final List<String> paymentMethods;
  final List<SaleReportItem> items;

  const SaleReportInvoice({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    this.customerName,
    this.customerId,
    required this.totalAmount,
    required this.totalDiscount,
    required this.grandTotal,
    required this.status,
    required this.paymentMethods,
    required this.items,
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
  final String  productName;
  final String? sku;
  final double  price;
  final double  quantity;
  final double  discount;
  final double  totalAmount;

  const SaleReportItem({
    required this.productName,
    this.sku,
    required this.price,
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