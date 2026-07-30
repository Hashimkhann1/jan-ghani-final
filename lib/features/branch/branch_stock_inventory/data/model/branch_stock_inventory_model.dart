class BranchStockInventory {
  final String? id;
  final String storeId;
  final String productId;
  final String? categoryId; // ✅ NEW
  final List<String> barcode;
  final String sku;
  final String productName;
  final double purchasePrice;
  final double salePrice;
  final double wholesalePrice;
  final double stock;
  final double minStock;
  final double maxStock;
  final String unit;

  BranchStockInventory({
    this.id,
    required this.storeId,
    required this.productId,
    this.categoryId,          // ✅ NEW (nullable — safe)
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
    'category_id': categoryId,  // ✅ NEW
    'barcode': barcode,
    'sku': sku,
    'product_name': productName,
    'purchase_price': purchasePrice,
    'sale_price': salePrice,
    'wholesale_price': wholesalePrice,
    'stock': stock,
    'min_stock': minStock,
    'max_stock': maxStock,
    'unit': unit,
    'updated_at': DateTime.now().toIso8601String(),
  };

  factory BranchStockInventory.fromJson(Map<String, dynamic> json) {
    return BranchStockInventory(
      id: json['id'],
      storeId: json['store_id'],
      productId: json['product_id'],
      categoryId: json['category_id'],  // ✅ NEW
      barcode: List<String>.from(json['barcode'] ?? []),
      sku: json['sku'] ?? '',
      productName: json['product_name'] ?? '',
      purchasePrice: double.tryParse(json['purchase_price'].toString()) ?? 0.0,
      salePrice: double.tryParse(json['sale_price'].toString()) ?? 0.0,
      wholesalePrice: double.tryParse(json['wholesale_price'].toString()) ?? 0.0,
      stock: double.tryParse(json['stock'].toString()) ?? 0.0,
      minStock: double.tryParse(json['min_stock'].toString()) ?? 0.0,
      maxStock: double.tryParse(json['max_stock'].toString()) ?? 0.0,
      unit: json['unit'] ?? 'pcs',
    );
  }
}