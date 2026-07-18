class AccountantBranchStockDamageModel {
  final String   id;
  final String   storeId;
  final String   productId;
  final String   productName;
  final double   salePrice;
  final double   purchasePrice;
  final double   stockDamage;
  final DateTime createdAt;

  const AccountantBranchStockDamageModel({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.salePrice,
    required this.purchasePrice,
    required this.stockDamage,
    required this.createdAt,
  });

  double get purchaseLoss => stockDamage * purchasePrice;
  double get saleLoss     => stockDamage * salePrice;

  factory AccountantBranchStockDamageModel.fromMap(Map<String, dynamic> m) {
    return AccountantBranchStockDamageModel(
      id:            m['id']?.toString()           ?? '',
      storeId:       m['store_id']?.toString()     ?? '',
      productId:     m['product_id']?.toString()   ?? '',
      productName:   m['product_name']?.toString() ?? '',
      salePrice:     _dbl(m['sale_price'])          ?? 0,
      purchasePrice: _dbl(m['purchase_price'])      ?? 0,
      stockDamage:   _dbl(m['stock_damage'])        ?? 0,
      createdAt:     DateTime.tryParse(
          m['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}

// ── Summary ───────────────────────────────────────────────
class AccountantBranchStockDamageSummary {
  final int    totalRecords;
  final double totalDamageQty;
  final double totalPurchaseLoss;
  final double totalSaleLoss;

  const AccountantBranchStockDamageSummary({
    required this.totalRecords,
    required this.totalDamageQty,
    required this.totalPurchaseLoss,
    required this.totalSaleLoss,
  });

  factory AccountantBranchStockDamageSummary.empty() =>
      const AccountantBranchStockDamageSummary(
        totalRecords:      0,
        totalDamageQty:    0,
        totalPurchaseLoss: 0,
        totalSaleLoss:     0,
      );
}
