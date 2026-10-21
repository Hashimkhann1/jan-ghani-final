class AssignedStockItem {
  final String productName;
  final String sku;
  final String unit;
  final double quantitySent;
  final double purchasePrice;
  final double salePrice;

  const AssignedStockItem({
    required this.productName,
    required this.sku,
    required this.unit,
    required this.quantitySent,
    required this.purchasePrice,
    required this.salePrice,
  });

  double get costValue => quantitySent * purchasePrice;
  double get saleValue => quantitySent * salePrice;
}

class AssignedStockTransfer {
  final String transferNumber;
  final DateTime assignedAt;
  final String? assignedByName;
  final String status;
  final String notes;
  final List<AssignedStockItem> items;

  const AssignedStockTransfer({
    required this.transferNumber,
    required this.assignedAt,
    required this.assignedByName,
    required this.status,
    required this.notes,
    required this.items,
  });

  double get totalUnits => items.fold(0.0, (s, i) => s + i.quantitySent);
  double get totalCost  => items.fold(0.0, (s, i) => s + i.costValue);
  double get totalSale  => items.fold(0.0, (s, i) => s + i.saleValue);
}
