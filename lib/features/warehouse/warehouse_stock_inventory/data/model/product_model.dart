// =============================================================
// product_model.dart
// FIXED:
//   1. copyWith — deletedAt clear karna possible
//   2. needsReorder — reorderPoint=0 edge case fix
// =============================================================

class ProductModel {
  final String       id;
  final String       warehouseId;
  final String       sku;
  final List<String> barcodes;
  final String       name;
  final String?      description;
  final String?      categoryId;
  final String?      categoryName;
  final String       unitOfMeasure;
  final double       purchasePrice;
  final double       sellingPrice;
  final double?      wholesalePrice;
  final double       taxRate;
  final int          minStockLevel;
  final int?         maxStockLevel;
  final int          reorderPoint;
  final bool         isActive;
  final bool         isTrackStock;
  final DateTime     createdAt;
  final DateTime     updatedAt;
  final DateTime?    deletedAt;

  // Inventory fields (JOIN se)
  final double quantity;
  final double reservedQty;
  double get availableQty => quantity - reservedQty;

  // Convenience: pehla barcode (scanning ke liye)
  String? get primaryBarcode =>
      barcodes.isNotEmpty ? barcodes.first : null;

  const ProductModel({
    required this.id,
    required this.warehouseId,
    required this.sku,
    this.barcodes = const [],
    required this.name,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.unitOfMeasure,
    required this.purchasePrice,
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
    this.quantity    = 0,
    this.reservedQty = 0,
  });

  // ── fromMap ───────────────────────────────────────────────
  factory ProductModel.fromMap(Map<String, dynamic> m) {
    return ProductModel(
      id:            m['id']?.toString()              ?? '',
      warehouseId:   m['warehouse_id']?.toString()    ?? '',
      sku:           m['sku']?.toString()             ?? '',
      barcodes:      _toBarcodeList(m['barcode']),
      name:          m['name']?.toString()            ?? '',
      description:   m['description']?.toString(),
      categoryId:    m['category_id']?.toString(),
      categoryName:  m['category_name']?.toString(),
      unitOfMeasure: m['unit_of_measure']?.toString() ?? 'pcs',
      purchasePrice: _toDouble(m['purchase_price']),
      sellingPrice:  _toDouble(m['selling_price']),
      wholesalePrice: m['wholesale_price'] != null
          ? _toDouble(m['wholesale_price'])
          : null,
      taxRate:       _toDouble(m['tax_rate']),
      minStockLevel: _toInt(m['min_stock_level']),
      maxStockLevel: m['max_stock_level'] != null
          ? _toInt(m['max_stock_level'])
          : null,
      reorderPoint:  _toInt(m['reorder_point']),
      isActive:      m['is_active'] == true || m['is_active'] == 't',
      isTrackStock:  m['is_track_stock'] == true || m['is_track_stock'] == 't',
      createdAt:     _toDate(m['created_at']) ?? DateTime.now(),
      updatedAt:     _toDate(m['updated_at']) ?? DateTime.now(),
      deletedAt:     _toDate(m['deleted_at']),
      quantity:      _toDouble(m['quantity']),
      reservedQty:   _toDouble(m['reserved_quantity']),
    );
  }

  // ── copyWith ──────────────────────────────────────────────
  // ✅ FIX: clearDeletedAt flag — deletedAt ko null karna possible
  ProductModel copyWith({
    String?       sku,
    List<String>? barcodes,
    String?       name,
    String?       description,
    String?       categoryId,
    String?       categoryName,
    String?       unitOfMeasure,
    double?       purchasePrice,
    double?       sellingPrice,
    double?       wholesalePrice,
    double?       taxRate,
    int?          minStockLevel,
    int?          maxStockLevel,
    int?          reorderPoint,
    bool?         isActive,
    bool?         isTrackStock,
    double?       quantity,
    double?       reservedQty,
    DateTime?     deletedAt,
    bool          clearDeletedAt = false,  // ✅ NEW — deletedAt null karne ke liye
  }) {
    return ProductModel(
      id:            id,
      warehouseId:   warehouseId,
      sku:           sku            ?? this.sku,
      barcodes:      barcodes       ?? this.barcodes,
      name:          name           ?? this.name,
      description:   description    ?? this.description,
      categoryId:    categoryId     ?? this.categoryId,
      categoryName:  categoryName   ?? this.categoryName,
      unitOfMeasure: unitOfMeasure  ?? this.unitOfMeasure,
      purchasePrice: purchasePrice  ?? this.purchasePrice,
      sellingPrice:  sellingPrice   ?? this.sellingPrice,
      wholesalePrice:wholesalePrice ?? this.wholesalePrice,
      taxRate:       taxRate        ?? this.taxRate,
      minStockLevel: minStockLevel  ?? this.minStockLevel,
      maxStockLevel: maxStockLevel  ?? this.maxStockLevel,
      reorderPoint:  reorderPoint   ?? this.reorderPoint,
      isActive:      isActive       ?? this.isActive,
      isTrackStock:  isTrackStock   ?? this.isTrackStock,
      createdAt:     createdAt,
      updatedAt:     DateTime.now(),
      // ✅ clearDeletedAt=true ho toh null, warna deletedAt ya purana wala
      deletedAt:     clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      quantity:      quantity       ?? this.quantity,
      reservedQty:   reservedQty    ?? this.reservedQty,
    );
  }

  // ── Business Logic ────────────────────────────────────────
  bool get isLowStock => isTrackStock && quantity <= minStockLevel;

  // ✅ FIX: reorderPoint=0 ka matlab hai "no reorder needed"
  // Sirf tab reorder chahiye jab reorderPoint > 0 aur quantity us se kam ho
  bool get needsReorder =>
      isTrackStock && reorderPoint > 0 && quantity <= reorderPoint;

  // ── Postgres text[] → Dart List<String> ──────────────────
  static List<String> _toBarcodeList(dynamic v) {
    if (v == null) return [];

    // Case 1: Already a Dart List
    if (v is List) {
      return v
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .map((e) => e.toString().trim())
          .toList();
    }

    // Case 2: Postgres string '{val1,val2}'
    final str = v.toString().trim();
    if (str.isEmpty || str == '{}') return [];

    final inner = str.replaceAll(RegExp(r'^\{|\}$'), '');
    return inner
        .split(',')
        .map((e) => e.trim().replaceAll('"', ''))
        .where((e) => e.isNotEmpty)
        .toList();
  }

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
    if (v == null)        return null;
    if (v is DateTime)    return v;
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
      'ProductModel(id: $id, sku: $sku, name: $name, barcodes: $barcodes)';
}