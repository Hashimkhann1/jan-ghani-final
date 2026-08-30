class PnlItem {
  final String  productName;
  final String? sku;
  final double  salePrice;
  final double  purchasePrice;  // costPrice → purchasePrice
  final double  discount;
  final double  quantity;

  const PnlItem({
    required this.productName,
    this.sku,
    required this.salePrice,
    required this.purchasePrice,
    required this.discount,
    required this.quantity,
  });

  // (salePrice - purchasePrice) × quantity - discount
  double get profit  => (salePrice - purchasePrice) * quantity - discount;
  double get revenue => salePrice  * quantity;
  double get cost    => purchasePrice * quantity;
}

/// One row of the paginated Invoices-tab list. Profit/revenue/cost are
/// pre-aggregated by `pnl_transactions_view` in Postgres — items are NOT
/// included here; they're fetched lazily (see [PnlReportDatasource.
/// getTransactionItems]) only when a row is expanded.
class PnlTransactionRow {
  final String   id;
  final String   type; // 'sale' | 'return'
  final String   docNo;
  final DateTime date;
  final String?  customerName;
  final double   totalRevenue;
  final double   totalCost;
  final double   totalProfit;
  final int      itemCount;

  const PnlTransactionRow({
    required this.id,
    required this.type,
    required this.docNo,
    required this.date,
    this.customerName,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.itemCount,
  });

  bool get isReturn => type == 'return';
}

/// One page of the Invoices tab, plus its exact total count (for the
/// current date range + All/Profit/Loss filter) from `count: CountOption.
/// exact` — not a client-side `.length`.
class PnlTransactionsPage {
  final List<PnlTransactionRow> rows;
  final int totalCount;

  const PnlTransactionsPage({
    required this.rows,
    required this.totalCount,
  });
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

/// Aggregate totals + daily breakdown — computed entirely in Postgres by
/// the `get_pnl_summary` RPC (SUM/COUNT/GROUP BY), never by summing a
/// fetched list of invoices in Dart.
class PnlSummary {
  final double              grossSaleProfit;
  final double              grossReturnProfit;
  final double              totalSaleRevenue;
  final double              totalCost;
  final int                 totalInvoices;
  final int                 totalReturns;
  final List<PnlDaySummary> daily;

  const PnlSummary({
    required this.grossSaleProfit,
    required this.grossReturnProfit,
    required this.totalSaleRevenue,
    required this.totalCost,
    required this.totalInvoices,
    required this.totalReturns,
    required this.daily,
  });

  double get netProfit    => grossSaleProfit - grossReturnProfit;
  double get profitMargin => totalSaleRevenue == 0
      ? 0
      : (netProfit / totalSaleRevenue) * 100;
}
