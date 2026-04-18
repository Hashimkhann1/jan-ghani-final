double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  return double.tryParse(value.toString()) ?? 0.0;
}

class StockTransfer {
  final String id;
  final String transferNumber;
  final String toStoreId;
  final String toStoreName;
  final String warehouseId;
  final String? assignedByName;
  final DateTime assignedAt;
  final String? notes;
  final int totalItems;
  final double totalCost;
  final double totalSalePrice;
  final String status;
  final List<StockTransferItem> items;

  StockTransfer({
    required this.id,
    required this.transferNumber,
    required this.toStoreId,
    required this.toStoreName,
    required this.warehouseId,
    this.assignedByName,
    required this.assignedAt,
    this.notes,
    required this.totalItems,
    required this.totalCost,
    required this.totalSalePrice,
    required this.status,
    required this.items,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id:             json['id'],
      transferNumber: json['transfer_number'],
      toStoreId:      json['to_store_id'],
      toStoreName:    json['to_store_name'] ?? '',
      warehouseId:    json['warehouse_id'],
      assignedByName: json['assigned_by_name'],
      assignedAt:     DateTime.parse(json['assigned_at']),
      notes:          json['notes'],
      totalItems:     (json['total_items'] as num?)?.toInt() ?? 0,
      totalCost:      _toDouble(json['total_cost']),
      totalSalePrice: _toDouble(json['total_sale_price']),
      status:         json['status'],
      items: (json['stock_transfer_items'] as List? ?? [])
          .map((e) => StockTransferItem.fromJson(e))
          .toList(),
    );
  }

  bool get isPending  => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  double get subtotal =>
      items.fold(0.0, (s, i) => s + (i.purchasePrice * i.quantity));
  double get totalDiscount =>
      items.fold(0.0, (s, i) => s + i.discountAmount);
  double get totalTax =>
      items.fold(0.0, (s, i) => s + i.taxAmount);
  double get grandTotal => subtotal + totalTax - totalDiscount;
}

class StockTransferItem {
  final String id;
  final String transferId;
  final String productId;
  final String productName;
  final String sku;
  final List<String> barcode;
  final String? description;
  final String unitOfMeasure;
  final double quantity;
  final double purchasePrice;
  final double salePrice;
  final double wholesalePrice;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double totalCost;
  final double quantitySent;
  final int minStockLevel;
  final int maxStockLevel;

  StockTransferItem({
    required this.id,
    required this.transferId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.barcode,
    this.description,
    required this.unitOfMeasure,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
    required this.wholesalePrice,
    required this.taxRate,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalCost,
    required this.quantitySent,
    required this.minStockLevel,
    required this.maxStockLevel,
  });

  factory StockTransferItem.fromJson(Map<String, dynamic> json) {
    return StockTransferItem(
      id:             json['id'],
      transferId:     json['transfer_id'],
      productId:      json['product_id'],
      productName:    json['product_name'],
      sku:            json['sku'] ?? '',
      barcode:        List<String>.from(json['barcode'] ?? []),
      description:    json['description'],
      unitOfMeasure:  json['unit_of_measure'] ?? 'pcs',

      // ✅ quantity_sent use karo, fallback quantity_requested
      quantity:       _toDouble(
          json['quantity_sent'] ??
              json['quantity_requested']),

      // ✅ purchase_price, fallback unit_cost
      purchasePrice:  _toDouble(
          json['purchase_price'] ??
              json['unit_cost']),

      salePrice:      _toDouble(json['sale_price']),
      wholesalePrice: _toDouble(json['wholesale_price']),
      taxRate:        _toDouble(json['tax_rate']),
      taxAmount:      _toDouble(json['tax_amount']),
      discountAmount: _toDouble(json['discount_amount']),
      totalCost:      _toDouble(json['total_cost']),
      quantitySent:   _toDouble(json['quantity_sent']),
      minStockLevel:  (json['min_stock_level'] as num?)?.toInt() ?? 0,
      maxStockLevel:  (json['max_stock_level'] as num?)?.toInt() ?? 0,
    );
  }
}