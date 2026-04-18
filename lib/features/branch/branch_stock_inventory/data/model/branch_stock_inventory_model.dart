class BranchStockInventory {
  final String? id;
  final String storeId;
  final String productId;
  final List<String> barcode;
  final String sku;
  final String productName;
  final double purchasePrice;
  final double salePrice;
  final double wholesalePrice;
  final double stock;
  final double minStock;   // ← added
  final double maxStock;   // ← added
  final String unit;

  BranchStockInventory({
    this.id,
    required this.storeId,
    required this.productId,
    required this.barcode,
    required this.sku,
    required this.productName,
    required this.purchasePrice,
    required this.salePrice,
    required this.wholesalePrice,
    required this.stock,
    this.minStock = 0,
    this.maxStock = 0,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
    'store_id': storeId,
    'product_id': productId,
    'barcode': barcode,
    'sku': sku,
    'product_name': productName,
    'purchase_price': purchasePrice,
    'sale_price': salePrice,
    'wholesale_price': wholesalePrice,
    'stock': stock,
    'min_stock': minStock,   // ← added
    'max_stock': maxStock,   // ← added
    'unit': unit,
    'updated_at': DateTime.now().toIso8601String(),
  };
}