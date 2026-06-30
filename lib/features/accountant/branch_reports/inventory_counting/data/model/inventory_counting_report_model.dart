class InventoryCountingRecord {
  final String id;
  final String productId;
  final String productName;
  final double purchasePrice;
  final double salePrice;
  final double productStock;
  final double countingStock;
  final DateTime updatedAt;
  final DateTime createdAt;
  final DateTime countedDate;

  InventoryCountingRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.purchasePrice,
    required this.salePrice,
    required this.productStock,
    required this.countingStock,
    required this.updatedAt,
    required this.createdAt,
    required this.countedDate,
  });

  double get difference => countingStock - productStock;

  /// Difference in rupees: difference × purchase_price
  double get differenceValue => difference * purchasePrice;

  /// Do alag maps se banao — counting table + inventory table
  factory InventoryCountingRecord.fromMerged({
    required Map<String, dynamic> counting,
    required Map<String, dynamic> inventory,
  }) {
    return InventoryCountingRecord(
      id: counting['id'] as String,
      productId: counting['product_id'] as String,
      productName: inventory['product_name'] as String? ?? counting['product_id'] as String,
      purchasePrice: double.tryParse(inventory['purchase_price']?.toString() ?? '0') ?? 0.0,
      salePrice: double.tryParse(inventory['sale_price']?.toString() ?? '0') ?? 0.0,
      productStock: double.tryParse(counting['product_stock'].toString()) ?? 0.0,
      countingStock: double.tryParse(counting['counting_stock'].toString()) ?? 0.0,
      updatedAt: DateTime.parse(counting['updated_at'] as String),
      createdAt: DateTime.parse(counting['created_at'] as String),
      countedDate: DateTime.parse(counting['counted_date'] as String),
    );
  }
}