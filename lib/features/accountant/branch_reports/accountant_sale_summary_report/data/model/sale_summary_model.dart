class SaleSummary {
  final double totalSale;
  final double totalReturn;
  final double totalCollected;

  const SaleSummary({
    this.totalSale      = 0,
    this.totalReturn    = 0,
    this.totalCollected = 0,
  });

  double get netSale => totalSale - totalReturn;
}

class SummaryCustomer {
  final String  id;
  final String  name;
  final String? code;

  const SummaryCustomer({required this.id, required this.name, this.code});

  String get label => code != null ? '$name — $code' : name;
}

class SummaryInvoiceItem {
  final String productName;
  final double quantity;
  final double salePrice;
  final double totalAmount;

  const SummaryInvoiceItem({
    required this.productName,
    required this.quantity,
    required this.salePrice,
    required this.totalAmount,
  });
}

class SummaryInvoice {
  final String   id;
  final String   invoiceNo;
  final DateTime invoiceDate;
  final String?  customerName;
  final double   totalDiscount;
  final double   grandTotal;
  final double   previousAmount;
  final double   newAmount;
  final double   payAmount;
  final List<String> paymentMethods;
  final List<SummaryInvoiceItem> items;

  const SummaryInvoice({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    this.customerName,
    required this.totalDiscount,
    required this.grandTotal,
    required this.previousAmount,
    required this.newAmount,
    required this.payAmount,
    required this.paymentMethods,
    required this.items,
  });

  String get customerLabel => customerName ?? 'Walk In';

  String get paymentLabel => paymentMethods.isEmpty
      ? '—'
      : paymentMethods
          .where((p) => p.isNotEmpty)
          .map((p) => p[0].toUpperCase() + p.substring(1))
          .join(', ');
}

class PagedSummaryInvoices {
  final List<SummaryInvoice> invoices;
  final bool hasNextPage;
  const PagedSummaryInvoices({required this.invoices, required this.hasNextPage});
}
