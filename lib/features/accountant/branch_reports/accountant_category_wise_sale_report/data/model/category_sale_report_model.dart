class CategorySaleReport {
  final String categoryId;
  final String categoryName;
  final double totalQuantity;
  final double totalSales;
  final double totalProfit;
  final int    invoiceCount;

  const CategorySaleReport({
    required this.categoryId,
    required this.categoryName,
    required this.totalQuantity,
    required this.totalSales,
    required this.totalProfit,
    required this.invoiceCount,
  });

  factory CategorySaleReport.fromJson(Map<String, dynamic> json) {
    return CategorySaleReport(
      categoryId:    json['category_id']?.toString()  ?? '',
      categoryName:  json['category_name']?.toString() ?? '',
      totalQuantity: _dbl(json['total_quantity'])      ?? 0,
      totalSales:    _dbl(json['total_sales'])         ?? 0,
      totalProfit:   _dbl(json['total_profit'])        ?? 0,
      invoiceCount:  int.tryParse(
          json['invoice_count'].toString())            ?? 0,
    );
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class CategorySaleReportSummary {
  final int    totalCategories;
  final double totalSales;
  final double totalProfit;
  final double totalQuantity;

  const CategorySaleReportSummary({
    required this.totalCategories,
    required this.totalSales,
    required this.totalProfit,
    required this.totalQuantity,
  });
}

class CategoryOption {
  final String id;
  final String name;

  const CategoryOption({required this.id, required this.name});
}

class CategoryProductSale {
  final String productId;
  final String productName;
  final String sku;
  final double totalQuantity;
  final double totalSales;
  final double totalProfit;

  const CategoryProductSale({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.totalQuantity,
    required this.totalSales,
    required this.totalProfit,
  });

  factory CategoryProductSale.fromJson(Map<String, dynamic> json) {
    return CategoryProductSale(
      productId:     json['product_id']?.toString()   ?? '',
      productName:   json['product_name']?.toString() ?? '',
      sku:           json['sku']?.toString()          ?? '',
      totalQuantity: _dbl(json['total_quantity'])     ?? 0,
      totalSales:    _dbl(json['total_sales'])        ?? 0,
      totalProfit:   _dbl(json['total_profit'])       ?? 0,
    );
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}