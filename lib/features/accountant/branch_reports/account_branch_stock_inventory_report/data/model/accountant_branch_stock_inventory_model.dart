class AccountantBranchInventoryModel {
  final String       id;
  final String       storeId;
  final String       productId;
  final String       productName;
  final String       sku;
  final List<String> barcodes;
  final double       purchasePrice;
  final double       salePrice;
  final double       wholesalePrice;
  final double       stock;
  final double       minStock;
  final double       maxStock;
  final String       unit;
  final DateTime     updatedAt;

  const AccountantBranchInventoryModel({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.barcodes,
    required this.purchasePrice,
    required this.salePrice,
    required this.wholesalePrice,
    required this.stock,
    required this.minStock,
    required this.maxStock,
    required this.unit,
    required this.updatedAt,
  });

  StockStatus get stockStatus {
    if (stock <= 0)        return StockStatus.outOfStock;
    if (stock <= minStock) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  factory AccountantBranchInventoryModel.fromMap(Map<String, dynamic> m) {
    List<String> barcodes = [];
    final raw = m['barcode'];
    if (raw is List) {
      barcodes = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      barcodes = [raw];
    }

    return AccountantBranchInventoryModel(
      id:             m['id']?.toString()           ?? '',
      storeId:        m['store_id']?.toString()     ?? '',
      productId:      m['product_id']?.toString()   ?? '',
      productName:    m['product_name']?.toString() ?? '',
      sku:            m['sku']?.toString()           ?? '',
      barcodes:       barcodes,
      purchasePrice:  _dbl(m['purchase_price'])     ?? 0,
      salePrice:      _dbl(m['sale_price'])         ?? 0,
      wholesalePrice: _dbl(m['wholesale_price'])    ?? 0,
      stock:          _dbl(m['stock'])              ?? 0,
      minStock:       _dbl(m['min_stock'])          ?? 0,
      maxStock:       _dbl(m['max_stock'])          ?? 0,
      unit:           m['unit']?.toString()          ?? '',
      updatedAt:      DateTime.tryParse(
          m['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}

enum StockStatus { inStock, lowStock, outOfStock }

// ── Summary ───────────────────────────────────────────────
class AccountantBranchInventorySummary {
  final int    totalProducts;
  final int    inStock;
  final int    lowStock;
  final int    outOfStock;
  final double totalStockValue;
  final double totalSaleValue;
  final double totalPurchaseValue;

  // InStock breakdown
  final double inStockQty;
  final double inStockSaleValue;
  final double inStockPurchaseValue;

  // LowStock breakdown
  final double lowStockQty;
  final double lowStockSaleValue;
  final double lowStockPurchaseValue;

  // OutOfStock breakdown
  final double outStockQty;
  final double outStockSaleValue;
  final double outStockPurchaseValue;

  const AccountantBranchInventorySummary({
    required this.totalProducts,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.totalStockValue,
    this.totalSaleValue        = 0,
    this.totalPurchaseValue    = 0,
    this.inStockQty            = 0,
    this.inStockSaleValue      = 0,
    this.inStockPurchaseValue  = 0,
    this.lowStockQty           = 0,
    this.lowStockSaleValue     = 0,
    this.lowStockPurchaseValue = 0,
    this.outStockQty           = 0,
    this.outStockSaleValue     = 0,
    this.outStockPurchaseValue = 0,
  });

  factory AccountantBranchInventorySummary.empty() =>
      const AccountantBranchInventorySummary(
        totalProducts: 0,
        inStock:       0,
        lowStock:      0,
        outOfStock:    0,
        totalStockValue: 0,
      );
}