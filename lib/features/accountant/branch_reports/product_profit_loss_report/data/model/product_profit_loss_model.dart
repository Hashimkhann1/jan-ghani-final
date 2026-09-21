class ProductProfitLossModel {
  final String  productId;
  final String  productName;
  final String  sku;
  final String? categoryId;
  final String  categoryName;
  final String  unit;
  final double  salePrice;
  final double  purchasePrice;

  /// Current branch inventory stock (live, not date-filtered).
  final double  inventoryStock;

  /// Quantity sold / returned inside the selected date range.
  final double  soldQty;
  final double  returnQty;

  /// (sale_price - purchase_price) * qty - discount, same formula the
  /// Profit & Loss report uses, summed per product.
  final double  saleProfit;
  final double  returnProfit;

  const ProductProfitLossModel({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.categoryId,
    required this.categoryName,
    required this.unit,
    required this.salePrice,
    required this.purchasePrice,
    required this.inventoryStock,
    required this.soldQty,
    required this.returnQty,
    required this.saleProfit,
    required this.returnProfit,
  });

  double get netSoldQty => soldQty - returnQty;
  double get netProfit  => saleProfit - returnProfit;
  bool   get isProfit   => netProfit >= 0;
}

class ProductProfitLossSummary {
  final int    products;
  final double inventoryStock;
  final double soldQty;
  final double returnQty;
  final double netProfit;
  final double profitTotal; // sum of products with profit
  final double lossTotal;   // sum of products with loss (positive number)

  const ProductProfitLossSummary({
    this.products       = 0,
    this.inventoryStock = 0,
    this.soldQty        = 0,
    this.returnQty      = 0,
    this.netProfit      = 0,
    this.profitTotal    = 0,
    this.lossTotal      = 0,
  });

  factory ProductProfitLossSummary.from(List<ProductProfitLossModel> items) {
    double stock = 0, sold = 0, ret = 0, net = 0, profit = 0, loss = 0;
    for (final i in items) {
      stock += i.inventoryStock;
      sold  += i.soldQty;
      ret   += i.returnQty;
      net   += i.netProfit;
      if (i.netProfit >= 0) {
        profit += i.netProfit;
      } else {
        loss += -i.netProfit;
      }
    }
    return ProductProfitLossSummary(
      products:       items.length,
      inventoryStock: stock,
      soldQty:        sold,
      returnQty:      ret,
      netProfit:      net,
      profitTotal:    profit,
      lossTotal:      loss,
    );
  }
}

class ProductPnlCategory {
  final String id;
  final String name;
  const ProductPnlCategory({required this.id, required this.name});
}

/// Where the report's rows come from. The accountant app reads Supabase
/// (cloud), the branch app reads its local Postgres — same screen, same
/// provider, different source.
abstract class ProductProfitLossSource {
  Future<List<ProductPnlCategory>> fetchCategories();

  Future<List<ProductProfitLossModel>> fetchReport({
    required DateTime fromDate,
    required DateTime toDate,
    required Map<String, String> categoryNameById,
  });
}
