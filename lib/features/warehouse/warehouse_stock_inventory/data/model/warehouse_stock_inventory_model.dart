class WarehouseStockInventory {
  final int id;
  final String productName;
  final String sku;
  final String barcode;
  final String name;
  final String description;
  final String category;
  final String unit;
  final double sellPrice;
  final double purchasePrice;
  final double wholePrice;
  final double tax;
  final double discount;
  final int minStock;
  final int maxStock;
  final String companyName;      // ✅ New
  final DateTime? expiryDate;    // ✅ New (nullable - kuch products expire nahi hote)
  final bool isActive;           // ✅ New
  final DateTime createdAt;
  final DateTime updatedAt;

  WarehouseStockInventory({
    required this.id,
    required this.productName,
    required this.sku,
    required this.barcode,
    required this.name,
    required this.description,
    required this.category,
    required this.unit,
    required this.sellPrice,
    required this.purchasePrice,
    required this.wholePrice,
    required this.tax,
    required this.discount,
    required this.minStock,
    required this.maxStock,
    required this.companyName,
    this.expiryDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WarehouseStockInventory.fromJson(Map<String, dynamic> json) {
    return WarehouseStockInventory(
      id: json['id'],
      productName: json['product_name'],
      sku: json['sku'],
      barcode: json['barcode'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      unit: json['unit'],
      sellPrice: (json['sell_price'] as num).toDouble(),
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      wholePrice: (json['whole_price'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      minStock: json['min_stock'],
      maxStock: json['max_stock'],
      companyName: json['company_name'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'description': description,
      'category': category,
      'unit': unit,
      'sell_price': sellPrice,
      'purchase_price': purchasePrice,
      'whole_price': wholePrice,
      'tax': tax,
      'discount': discount,
      'min_stock': minStock,
      'max_stock': maxStock,
      'company_name': companyName,
      'expiry_date': expiryDate?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}