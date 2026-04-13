// =============================================================
// product_model.dart
// Products table + inventory quantity combined
// =============================================================

class ProductModel {
  final String   id;
  final String   warehouseId;
  final String   sku;
  final String?  barcode;
  final String   name;
  final String?  description;
  final String?  categoryId;    // UUID — categories table
  final String?  categoryName;  // JOIN se aata hai (display only)
  final String   unitOfMeasure;
  final double   costPrice;
  final double   sellingPrice;
  final double?  wholesalePrice;
  final double   taxRate;
  final int      minStockLevel;
  final int?     maxStockLevel;
  final int      reorderPoint;
  final bool     isActive;
  final bool     isTrackStock;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Inventory fields (JOIN se)
  final double   quantity;        // current stock
  final double   reservedQty;     // reserved stock
  double get availableQty => quantity - reservedQty;

  const ProductModel({
    required this.id,
    required this.warehouseId,
    required this.sku,
    this.barcode,
    required this.name,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.unitOfMeasure,
    required this.costPrice,
    required this.sellingPrice,
    this.wholesalePrice,
    required this.taxRate,
    required this.minStockLevel,
    this.maxStockLevel,
    required this.reorderPoint,
    required this.isActive,
    required this.isTrackStock,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.quantity        = 0,
    this.reservedQty     = 0,
  });

  // ── fromMap ───────────────────────────────────────────────
  factory ProductModel.fromMap(Map<String, dynamic> m) {
    return ProductModel(
      id:             m['id']?.toString()              ?? '',
      warehouseId:    m['warehouse_id']?.toString()    ?? '',
      sku:            m['sku']?.toString()             ?? '',
      barcode:        m['barcode']?.toString(),
      name:           m['name']?.toString()            ?? '',
      description:    m['description']?.toString(),
      categoryId:     m['category_id']?.toString(),
      categoryName:   m['category_name']?.toString(),
      unitOfMeasure:  m['unit_of_measure']?.toString() ?? 'pcs',
      costPrice:      _toDouble(m['cost_price']),
      sellingPrice:   _toDouble(m['selling_price']),
      wholesalePrice: m['wholesale_price'] != null
          ? _toDouble(m['wholesale_price'])
          : null,
      taxRate:        _toDouble(m['tax_rate']),
      minStockLevel:  _toInt(m['min_stock_level']),
      maxStockLevel:  m['max_stock_level'] != null
          ? _toInt(m['max_stock_level'])
          : null,
      reorderPoint:   _toInt(m['reorder_point']),
      isActive:       m['is_active'] == true || m['is_active'] == 't',
      isTrackStock:   m['is_track_stock'] == true || m['is_track_stock'] == 't',
      createdAt:      _toDate(m['created_at']) ?? DateTime.now(),
      updatedAt:      _toDate(m['updated_at']) ?? DateTime.now(),
      deletedAt:      _toDate(m['deleted_at']),
      quantity:       _toDouble(m['quantity']),
      reservedQty:    _toDouble(m['reserved_quantity']),
    );
  }

  // ── copyWith ──────────────────────────────────────────────
  ProductModel copyWith({
    String?   sku,
    String?   barcode,
    String?   name,
    String?   description,
    String?   categoryId,
    String?   categoryName,
    String?   unitOfMeasure,
    double?   costPrice,
    double?   sellingPrice,
    double?   wholesalePrice,
    double?   taxRate,
    int?      minStockLevel,
    int?      maxStockLevel,
    int?      reorderPoint,
    bool?     isActive,
    bool?     isTrackStock,
    double?   quantity,
    double?   reservedQty,
    DateTime? deletedAt,
  }) {
    return ProductModel(
      id:             id,
      warehouseId:    warehouseId,
      sku:            sku            ?? this.sku,
      barcode:        barcode        ?? this.barcode,
      name:           name           ?? this.name,
      description:    description    ?? this.description,
      categoryId:     categoryId     ?? this.categoryId,
      categoryName:   categoryName   ?? this.categoryName,
      unitOfMeasure:  unitOfMeasure  ?? this.unitOfMeasure,
      costPrice:      costPrice      ?? this.costPrice,
      sellingPrice:   sellingPrice   ?? this.sellingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      taxRate:        taxRate        ?? this.taxRate,
      minStockLevel:  minStockLevel  ?? this.minStockLevel,
      maxStockLevel:  maxStockLevel  ?? this.maxStockLevel,
      reorderPoint:   reorderPoint   ?? this.reorderPoint,
      isActive:       isActive       ?? this.isActive,
      isTrackStock:   isTrackStock   ?? this.isTrackStock,
      createdAt:      createdAt,
      updatedAt:      DateTime.now(),
      deletedAt:      deletedAt      ?? this.deletedAt,
      quantity:       quantity       ?? this.quantity,
      reservedQty:    reservedQty    ?? this.reservedQty,
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  bool get isLowStock =>
      isTrackStock && quantity <= minStockLevel;
  bool get needsReorder =>
      isTrackStock && quantity <= reorderPoint;

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ProductModel(id: $id, sku: $sku, name: $name)';
}
