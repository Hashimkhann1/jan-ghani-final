// =============================================================
// linked_store_product_model.dart
// Linked store ke ek product ka model (read-only, view se aata hai)
// =============================================================

class LinkedStoreProduct {
  final String    id;
  final String    storeId;
  final String?   productId;
  final String    productName;
  final String?   sku;
  final String?   barcode;
  final String?   unit;
  final double    stock;
  final double    minStock;
  final double?   maxStock;
  final double    purchasePrice;
  final double    salePrice;
  final double?   wholesalePrice;
  final DateTime? updatedAt;
  final String    stockStatus; // 'out' | 'low' | 'ok'

  const LinkedStoreProduct({
    required this.id,
    required this.storeId,
    this.productId,
    required this.productName,
    this.sku,
    this.barcode,
    this.unit,
    required this.stock,
    required this.minStock,
    this.maxStock,
    required this.purchasePrice,
    required this.salePrice,
    this.wholesalePrice,
    this.updatedAt,
    required this.stockStatus,
  });

  bool get isOut => stockStatus == 'out';
  bool get isLow => stockStatus == 'low';
  bool get isOk  => stockStatus == 'ok';

  factory LinkedStoreProduct.fromMap(Map<String, dynamic> m) {
    return LinkedStoreProduct(
      id:             m['id']?.toString() ?? '',
      storeId:        m['store_id']?.toString() ?? '',
      productId:      m['product_id']?.toString(),
      productName:    m['product_name']?.toString() ?? '',
      sku:            m['sku']?.toString(),
      barcode:        m['barcode']?.toString(),
      unit:           m['unit']?.toString(),
      stock:          _toDouble(m['stock']),
      minStock:       _toDouble(m['min_stock']),
      maxStock:       m['max_stock'] == null ? null : _toDouble(m['max_stock']),
      purchasePrice:  _toDouble(m['purchase_price']),
      salePrice:      _toDouble(m['sale_price']),
      wholesalePrice: m['wholesale_price'] == null ? null : _toDouble(m['wholesale_price']),
      updatedAt:      m['updated_at'] == null ? null : DateTime.tryParse(m['updated_at'].toString()),
      stockStatus:    (m['stock_status']?.toString() ?? 'ok'),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null)   return 0.0;
    if (v is double) return v;
    if (v is num)    return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
