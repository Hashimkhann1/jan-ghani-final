class PnlItem {
  final String  productName;
  final String? sku;
  final double  salePrice;
  final double  costPrice;
  final double  discount;
  final double  quantity;

  const PnlItem({
    required this.productName,
    this.sku,
    required this.salePrice,
    required this.costPrice,
    required this.discount,
    required this.quantity,
  });

  /// (price - cost_price - discount) × quantity
  double get profit  => (salePrice - costPrice - discount) * quantity;
  double get revenue => salePrice * quantity;
  double get cost    => costPrice * quantity;
}

class PnlInvoice {
  final String        invoiceNo;
  final DateTime      date;
  final String?       customerName;
  final List<PnlItem> items;
  final bool          isReturn;

  const PnlInvoice({
    required this.invoiceNo,
    required this.date,
    this.customerName,
    required this.items,
    required this.isReturn,
  });

  double get totalProfit  => items.fold(0, (s, i) => s + i.profit);
  double get totalRevenue => items.fold(0, (s, i) => s + i.revenue);
  double get totalCost    => items.fold(0, (s, i) => s + i.cost);
}

class PnlDaySummary {
  final DateTime date;
  final double   saleProfit;
  final double   returnProfit;

  const PnlDaySummary({
    required this.date,
    required this.saleProfit,
    required this.returnProfit,
  });

  double get netProfit => saleProfit - returnProfit;
}

class PnlSummary {
  final double              grossSaleProfit;
  final double              grossReturnProfit;
  final double              totalSaleRevenue;
  final double              totalCost;
  final int                 totalInvoices;
  final int                 totalReturns;
  final List<PnlInvoice>    invoices;
  final List<PnlDaySummary> daily;

  const PnlSummary({
    required this.grossSaleProfit,
    required this.grossReturnProfit,
    required this.totalSaleRevenue,
    required this.totalCost,
    required this.totalInvoices,
    required this.totalReturns,
    required this.invoices,
    required this.daily,
  });

  double get netProfit    => grossSaleProfit - grossReturnProfit;
  double get profitMargin => totalSaleRevenue == 0
      ? 0
      : (netProfit / totalSaleRevenue) * 100;
}