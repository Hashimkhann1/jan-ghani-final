// =============================================================
// warehouse_stock_inventory_model.dart
// FIXED: complete null safety — ProductModel ki tarah
// =============================================================

class WarehouseStockInventory {
  final String    id;           // ✅ UUID → String (int se fix)
  final String    productName;
  final String    sku;
  final String    barcode;
  final String    name;
  final String?   description;  // ✅ nullable — DB mein empty ho sakta hai
  final String?   category;     // ✅ nullable — category na ho
  final String    unit;
  final double    sellPrice;
  final double    purchasePrice;
  final double    wholePrice;
  final double    tax;
  final double    discount;
  final int       minStock;
  final int       maxStock;
  final String?   companyName;  // ✅ nullable
  final DateTime? expiryDate;
  final bool      isActive;
  final DateTime  createdAt;
  final DateTime  updatedAt;

  const WarehouseStockInventory({
    required this.id,
    required this.productName,
    required this.sku,
    required this.barcode,
    required this.name,
    this.description,
    this.category,
    required this.unit,
    required this.sellPrice,
    required this.purchasePrice,
    required this.wholePrice,
    required this.tax,
    required this.discount,
    required this.minStock,
    required this.maxStock,
    this.companyName,
    this.expiryDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WarehouseStockInventory.fromJson(Map<String, dynamic> json) {
    return WarehouseStockInventory(
      id:            json['id']?.toString()           ?? '',   // ✅ UUID String
      productName:   json['product_name']?.toString() ?? '',
      sku:           json['sku']?.toString()           ?? '',
      barcode:       json['barcode']?.toString()       ?? '',
      name:          json['name']?.toString()          ?? '',
      description:   json['description']?.toString(),          // ✅ nullable
      category:      json['category']?.toString(),             // ✅ nullable
      unit:          json['unit']?.toString()           ?? 'pcs',
      sellPrice:     _toDouble(json['sell_price']),            // ✅ safe
      purchasePrice: _toDouble(json['purchase_price']),        // ✅ safe
      wholePrice:    _toDouble(json['whole_price']),           // ✅ safe
      tax:           _toDouble(json['tax']),                   // ✅ safe
      discount:      _toDouble(json['discount']),              // ✅ safe
      minStock:      _toInt(json['min_stock']),                // ✅ safe
      maxStock:      _toInt(json['max_stock']),                // ✅ safe
      companyName:   json['company_name']?.toString(),         // ✅ nullable
      expiryDate:    json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : null,
      isActive:      json['is_active'] == true ||
          json['is_active'] == 't'  ||
          json['is_active'] == 1,                   // ✅ DB formats
      createdAt:     _toDate(json['created_at']) ?? DateTime.now(),
      updatedAt:     _toDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':             id,
      'product_name':   productName,
      'sku':            sku,
      'barcode':        barcode,
      'name':           name,
      'description':    description,
      'category':       category,
      'unit':           unit,
      'sell_price':     sellPrice,
      'purchase_price': purchasePrice,
      'whole_price':    wholePrice,
      'tax':            tax,
      'discount':       discount,
      'min_stock':      minStock,
      'max_stock':      maxStock,
      'company_name':   companyName,
      'expiry_date':    expiryDate?.toIso8601String(),
      'is_active':      isActive,
      'created_at':     createdAt.toIso8601String(),
      'updated_at':     updatedAt.toIso8601String(),
    };
  }

  // ── Helpers (ProductModel ki tarah) ──────────────────────
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int)  return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null)     return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}