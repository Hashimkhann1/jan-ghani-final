class InventoryCountingRecord {
  final String       id;
  final String       productId;
  final String       productName;
  final List<String> barcodes;
  final double       minStock;
  final double       maxStock;
  final double       productStock;
  final double       countingStock;
  final DateTime     updatedAt;
  final DateTime     createdAt;
  final DateTime     countedDate;

  InventoryCountingRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.barcodes,
    required this.minStock,
    required this.maxStock,
    required this.productStock,
    required this.countingStock,
    required this.updatedAt,
    required this.createdAt,
    required this.countedDate,
  });

  double get difference => countingStock - productStock;

  /// Do alag maps se banao — counting table + inventory table
  factory InventoryCountingRecord.fromMerged({
    required Map<String, dynamic> counting,
    required Map<String, dynamic> inventory,
  }) {
    List<String> barcodes = [];
    final rawBarcode = inventory['barcode'];
    if (rawBarcode is List) {
      barcodes = rawBarcode.map((e) => e.toString()).toList();
    } else if (rawBarcode is String && rawBarcode.isNotEmpty) {
      barcodes = [rawBarcode];
    }

    return InventoryCountingRecord(
      id: counting['id'] as String,
      productId: counting['product_id'] as String,
      productName: inventory['product_name'] as String? ?? counting['product_id'] as String,
      barcodes: barcodes,
      minStock: double.tryParse(inventory['min_stock']?.toString() ?? '0') ?? 0.0,
      maxStock: double.tryParse(inventory['max_stock']?.toString() ?? '0') ?? 0.0,
      productStock: double.tryParse(counting['product_stock'].toString()) ?? 0.0,
      countingStock: double.tryParse(counting['counting_stock'].toString()) ?? 0.0,
      updatedAt: DateTime.parse(counting['updated_at'] as String),
      createdAt: DateTime.parse(counting['created_at'] as String),
      countedDate: DateTime.parse(counting['counted_date'] as String),
    );
  }
}
