class BranchStockDamageModel {
  final String   id;
  final String   storeId;
  final String   productId;
  final String   productName;
  final double   salePrice;
  final double   purchasePrice;
  final double      stockDamage;
  final DateTime createdAt;

  const BranchStockDamageModel({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.salePrice,
    required this.purchasePrice,
    required this.stockDamage,
    required this.createdAt,
  });

  double get totalLoss => purchasePrice * stockDamage;

  String get salePriceLabel    => 'Rs ${salePrice.toStringAsFixed(0)}';
  String get purchasePriceLabel => 'Rs ${purchasePrice.toStringAsFixed(0)}';
  String get totalLossLabel    => 'Rs ${totalLoss.toStringAsFixed(0)}';

  factory BranchStockDamageModel.fromMap(Map<String, dynamic> m) {
    return BranchStockDamageModel(
      id:           m['id']?.toString()           ?? '',
      storeId:      m['store_id']?.toString()     ?? '',
      productId:    m['product_id']?.toString()   ?? '',
      productName:  m['product_name']?.toString() ?? '',
      salePrice:    _dbl(m['sale_price'])         ?? 0.0,
      purchasePrice: _dbl(m['purchase_price'])    ?? 0.0,
      stockDamage:  _dbl(m['stock_damage'])       ?? 0.0,
      createdAt:    _date(m['created_at'])        ?? DateTime.now(),
    );
  }

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
      identical(this, other) ||
          other is BranchStockDamageModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}