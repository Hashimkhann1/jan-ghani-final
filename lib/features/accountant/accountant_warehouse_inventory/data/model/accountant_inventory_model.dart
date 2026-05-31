// =============================================================
// accountant_inventory_model.dart
// Accountant ke warehouse inventory item ka model (read-only)
// Source: warehouse_products + warehouse_inventory (quantity)
// =============================================================

class AccountantInventoryModel {
  final String  id;
  final String  name;
  final String? sku;
  final String  unitOfMeasure;
  final double  quantity;       // warehouse_inventory.quantity
  final double  purchasePrice;
  final double  sellingPrice;
  final int     minStockLevel;
  final int     maxStockLevel;

  const AccountantInventoryModel({
    required this.id,
    required this.name,
    this.sku,
    required this.unitOfMeasure,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.minStockLevel,
    required this.maxStockLevel,
  });

  // Stock value (qty × purchase price)
  double get stockValue => quantity * purchasePrice;

  bool get isLowStock => quantity <= minStockLevel;

  factory AccountantInventoryModel.fromMap(Map<String, dynamic> map) {
    // warehouse_inventory embedded relation se quantity nikaalo
    double qty = 0;
    final inv = map['warehouse_inventory'];
    if (inv is List) {
      for (final row in inv) {
        if (row is Map) qty += _toDouble(row['quantity']);
      }
    } else if (inv is Map) {
      qty = _toDouble(inv['quantity']);
    }

    return AccountantInventoryModel(
      id:            map['id']?.toString() ?? '',
      name:          map['name']?.toString() ?? 'Unknown',
      sku:           map['sku']?.toString(),
      unitOfMeasure: map['unit_of_measure']?.toString() ?? 'pcs',
      quantity:      qty,
      purchasePrice: _toDouble(map['purchase_price']),
      sellingPrice:  _toDouble(map['selling_price']),
      minStockLevel: _toInt(map['min_stock_level']),
      maxStockLevel: _toInt(map['max_stock_level']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
