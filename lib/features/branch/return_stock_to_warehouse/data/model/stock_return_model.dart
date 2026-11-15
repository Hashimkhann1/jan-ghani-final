double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

/// Ek return ke andar ek line (branch_stock_inventory ka snapshot).
class StockReturnItem {
  final String  id;
  final String  productId;
  final String  productName;
  final String? sku;
  final List<String> barcode;
  final String? categoryId;
  final String  unit;
  final double  purchasePrice;
  final double  salePrice;
  final double  wholesalePrice;
  final double  minStock;
  final double  maxStock;
  final String? shelfName;
  final double  quantityReturned;
  final double  totalCost;
  final double  totalSalePrice;

  const StockReturnItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.sku,
    this.barcode = const [],
    this.categoryId,
    this.unit = 'pcs',
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.wholesalePrice = 0,
    this.minStock = 0,
    this.maxStock = 0,
    this.shelfName,
    required this.quantityReturned,
    this.totalCost = 0,
    this.totalSalePrice = 0,
  });

  factory StockReturnItem.fromJson(Map<String, dynamic> j) => StockReturnItem(
        id:               j['id'].toString(),
        productId:        j['product_id'].toString(),
        productName:      j['product_name'] ?? '',
        sku:              j['sku'],
        barcode:          List<String>.from(j['barcode'] ?? const []),
        categoryId:       j['category_id']?.toString(),
        unit:             j['unit'] ?? 'pcs',
        purchasePrice:    _d(j['purchase_price']),
        salePrice:        _d(j['sale_price']),
        wholesalePrice:   _d(j['wholesale_price']),
        minStock:         _d(j['min_stock']),
        maxStock:         _d(j['max_stock']),
        shelfName:        j['shelf_name'],
        quantityReturned: _d(j['quantity_returned']),
        totalCost:        _d(j['total_cost']),
        totalSalePrice:   _d(j['total_sale_price']),
      );
}

class StockReturn {
  final String   id;
  final String   returnNumber;
  final String   fromStoreId;
  final String   warehouseId;
  final String   status; // pending | accepted | rejected
  final String?  returnedByName;
  final DateTime returnedAt;
  final String?  notes;
  final double   totalItems; // total qty
  final double   totalCost;
  final double   totalSalePrice;
  final DateTime? respondedAt;
  final String?  respondedByName;
  final String?  rejectReason;
  final bool     stockRestored;
  final List<StockReturnItem> items;

  const StockReturn({
    required this.id,
    required this.returnNumber,
    required this.fromStoreId,
    required this.warehouseId,
    required this.status,
    this.returnedByName,
    required this.returnedAt,
    this.notes,
    this.totalItems = 0,
    this.totalCost = 0,
    this.totalSalePrice = 0,
    this.respondedAt,
    this.respondedByName,
    this.rejectReason,
    this.stockRestored = false,
    this.items = const [],
  });

  bool get isPending  => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  factory StockReturn.fromJson(Map<String, dynamic> j) => StockReturn(
        id:              j['id'].toString(),
        returnNumber:    j['return_number'] ?? '',
        fromStoreId:     j['from_store_id'].toString(),
        warehouseId:     j['warehouse_id'].toString(),
        status:          j['status'] ?? 'pending',
        returnedByName:  j['returned_by_name'],
        returnedAt:      DateTime.parse(j['returned_at']).toLocal(),
        notes:           j['notes'],
        totalItems:      _d(j['total_items']),
        totalCost:       _d(j['total_cost']),
        totalSalePrice:  _d(j['total_sale_price']),
        respondedAt:     j['responded_at'] == null
            ? null
            : DateTime.parse(j['responded_at']).toLocal(),
        respondedByName: j['responded_by_name'],
        rejectReason:    j['reject_reason'],
        stockRestored:   j['stock_restored'] == true,
        items: (j['stock_return_items'] as List? ?? const [])
            .map((e) => StockReturnItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Return cart ki ek line.
class ReturnCartLine {
  final String productId;
  final String name;
  final String sku;
  final String unit;
  final double costPrice;
  final double salePrice;
  final double available; // branch stock
  final double qty;

  const ReturnCartLine({
    required this.productId,
    required this.name,
    required this.sku,
    required this.unit,
    required this.costPrice,
    required this.salePrice,
    required this.available,
    required this.qty,
  });

  double get totalCost => costPrice * qty;
  double get totalSale => salePrice * qty;

  ReturnCartLine withQty(double q) => ReturnCartLine(
        productId: productId, name: name, sku: sku, unit: unit,
        costPrice: costPrice, salePrice: salePrice,
        available: available, qty: q,
      );
}
