class BranchStockModel {
  final String   id;
  final String   storeId;
  final String   productId;
  final String   sku;
  final String?  barcode;
  final String   name;
  final String?  description;
  final String   unitOfMeasure;
  final double   costPrice;
  final double   sellingPrice;
  final double?  wholesalePrice;
  final double   taxRate;
  final double   discount;       // ← new
  final int      minStockLevel;
  final int      maxStockLevel;
  final int      reorderPoint;
  final bool     isActive;
  final bool     isTrackStock;
  final double   quantity;
  final double   reservedQuantity;
  final DateTime? lastCountedAt;
  final DateTime? lastMovementAt;
  final DateTime  updatedAt;

  const BranchStockModel({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.sku,
    this.barcode,
    required this.name,
    this.description,
    required this.unitOfMeasure,
    required this.costPrice,
    required this.sellingPrice,
    this.wholesalePrice,
    required this.taxRate,
    required this.discount,      // ← new
    required this.minStockLevel,
    required this.maxStockLevel,
    required this.reorderPoint,
    required this.isActive,
    required this.isTrackStock,
    required this.quantity,
    required this.reservedQuantity,
    this.lastCountedAt,
    this.lastMovementAt,
    required this.updatedAt,
  });

  // ── Getters ───────────────────────────────────────────────
  double get availableQuantity => quantity - reservedQuantity;

  bool get isLowStock  =>
      isTrackStock && quantity <= reorderPoint && quantity > 0;
  bool get isOutOfStock => isTrackStock && quantity <= 0;

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock)   return 'Low Stock';
    return 'In Stock';
  }

  String get costPriceLabel      => 'Rs ${costPrice.toStringAsFixed(0)}';
  String get sellingPriceLabel   => 'Rs ${sellingPrice.toStringAsFixed(0)}';
  String get wholesalePriceLabel =>
      wholesalePrice != null ? 'Rs ${wholesalePrice!.toStringAsFixed(0)}' : '—';
  String get taxRateLabel        => '${taxRate.toStringAsFixed(1)}%';
  String get discountLabel       => '${discount.toStringAsFixed(1)}%';
  String get quantityLabel       => '${quantity.toStringAsFixed(0)}';
  String get availableLabel      =>
      '${availableQuantity.toStringAsFixed(0)} $unitOfMeasure';

  factory BranchStockModel.fromMap(Map<String, dynamic> map) {
    return BranchStockModel(
      id:               _str(map['inv_id'])          ?? '',
      storeId:          _str(map['store_id'])         ?? '',
      productId:        _str(map['product_id'])       ?? '',
      sku:              _str(map['sku'])              ?? '',
      barcode:          _str(map['barcode']),
      name:             _str(map['name'])             ?? '',
      description:      _str(map['description']),
      unitOfMeasure:    _str(map['unit_of_measure'])  ?? 'pcs',
      costPrice:        _dbl(map['cost_price'])       ?? 0.0,
      sellingPrice:     _dbl(map['selling_price'])    ?? 0.0,
      wholesalePrice:   _dbl(map['wholesale_price']),
      taxRate:          _dbl(map['tax_rate'])         ?? 0.0,
      discount:         _dbl(map['discount'])         ?? 0.0,  // ← new
      minStockLevel:    _int(map['min_stock_level'])  ?? 0,
      maxStockLevel:    _int(map['max_stock_level'])  ?? 0,
      reorderPoint:     _int(map['reorder_point'])    ?? 0,
      isActive:         map['is_active']     as bool? ?? true,
      isTrackStock:     map['is_track_stock'] as bool? ?? true,
      quantity:         _dbl(map['quantity'])          ?? 0.0,
      reservedQuantity: _dbl(map['reserved_quantity']) ?? 0.0,
      lastCountedAt:    _date(map['last_counted_at']),
      lastMovementAt:   _date(map['last_movement_at']),
      updatedAt:        _date(map['updated_at'])       ?? DateTime.now(),
    );
  }

  static String?   _str(dynamic v) => v?.toString();
  static double?   _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
  static int?      _int(dynamic v) {
    if (v == null) return null;
    if (v is int)  return v;
    return int.tryParse(v.toString());
  }
  static DateTime? _date(dynamic v) {
    if (v == null)     return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BranchStockModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}