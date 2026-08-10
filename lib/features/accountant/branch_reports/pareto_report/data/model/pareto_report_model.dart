// ── Product Pareto ────────────────────────────────────────
class ParetoProductModel {
  final String productId;
  final String productName;
  final String sku;
  final double totalRevenue;   // sum of total_amount (sale - returns)
  final double totalProfit;    // (sale_price - purchase_price) * qty
  final double totalQty;
  final double revenueShare;   // 0.0 – 1.0  (cumulative)
  final double profitShare;    // 0.0 – 1.0  (cumulative)

  const ParetoProductModel({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalQty,
    required this.revenueShare,
    required this.profitShare,
  });
}

// ── Customer Sales Pareto ─────────────────────────────────
class ParetoCustomerSalesModel {
  final String customerId;
  final String customerName;
  final String phone;
  final double totalSales;     // sum of grand_total from sale_invoices
  final double salesShare;     // cumulative 0.0 – 1.0

  const ParetoCustomerSalesModel({
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.totalSales,
    required this.salesShare,
  });
}

// ── Customer Pending Balance Pareto ───────────────────────
class ParetoCustomerBalanceModel {
  final String customerId;
  final String customerName;
  final String phone;
  final String customerType;
  final double balance;        // outstanding amount
  final double creditLimit;
  final double balanceShare;   // cumulative 0.0 – 1.0

  const ParetoCustomerBalanceModel({
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.customerType,
    required this.balance,
    required this.creditLimit,
    required this.balanceShare,
  });

  bool get isCreditLimitExceeded => creditLimit > 0 && balance > creditLimit;
}

// ── Summary ───────────────────────────────────────────────
class ParetoReportSummary {
  // Products
  final int    totalProducts;
  final int    paretoProductCount;   // top 20%
  final double paretoRevenue;
  final double paretoProfit;
  final double totalRevenue;
  final double totalProfit;

  // Customer Sales
  final int    totalSalesCustomers;
  final int    paretoSalesCustomerCount;
  final double paretoSalesAmount;
  final double totalSalesAmount;

  // Customer Balance
  final int    totalBalanceCustomers;
  final int    paretoBalanceCustomerCount;
  final double paretoBalanceAmount;
  final double totalBalanceAmount;

  const ParetoReportSummary({
    required this.totalProducts,
    required this.paretoProductCount,
    required this.paretoRevenue,
    required this.paretoProfit,
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalSalesCustomers,
    required this.paretoSalesCustomerCount,
    required this.paretoSalesAmount,
    required this.totalSalesAmount,
    required this.totalBalanceCustomers,
    required this.paretoBalanceCustomerCount,
    required this.paretoBalanceAmount,
    required this.totalBalanceAmount,
  });

  factory ParetoReportSummary.empty() => const ParetoReportSummary(
        totalProducts:              0,
        paretoProductCount:         0,
        paretoRevenue:              0,
        paretoProfit:               0,
        totalRevenue:               0,
        totalProfit:                0,
        totalSalesCustomers:        0,
        paretoSalesCustomerCount:   0,
        paretoSalesAmount:          0,
        totalSalesAmount:           0,
        totalBalanceCustomers:      0,
        paretoBalanceCustomerCount: 0,
        paretoBalanceAmount:        0,
        totalBalanceAmount:         0,
      );
}

// ── Full State Data ───────────────────────────────────────
class ParetoReportData {
  final List<ParetoProductModel>         products;
  final List<ParetoCustomerSalesModel>   salesCustomers;
  final List<ParetoCustomerBalanceModel> balanceCustomers;
  final ParetoReportSummary              summary;

  const ParetoReportData({
    required this.products,
    required this.salesCustomers,
    required this.balanceCustomers,
    required this.summary,
  });

  factory ParetoReportData.empty() => ParetoReportData(
        products:        const [],
        salesCustomers:  const [],
        balanceCustomers: const [],
        summary:         ParetoReportSummary.empty(),
      );
}
