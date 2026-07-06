// data/model/inventory_countting_model.dart

class InventoryProductModel {
  final String id;
  final String productId;
  final String productName;
  final double currentStock;
  final DateTime updatedAt;
  bool isCounted;

  InventoryProductModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.updatedAt,
    this.isCounted = false,
  });

  factory InventoryProductModel.fromMap(Map<String, dynamic> map) {
    return InventoryProductModel(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      currentStock: double.tryParse(map['stock'].toString()) ?? 0.0,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class InventoryCountingModel {
  final String productId;
  final double productStock;
  final double countingStock;
  final DateTime updatedAt;
  final String countedDate;
  final String storeId;

  InventoryCountingModel({
    required this.productId,
    required this.productStock,
    required this.countingStock,
    required this.updatedAt,
    required this.countedDate,
    required this.storeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_stock': productStock,
      'counting_stock': countingStock,
      'updated_at': updatedAt.toIso8601String(),
      'counted_date': countedDate,
      'store_id': storeId,
    };
  }
}