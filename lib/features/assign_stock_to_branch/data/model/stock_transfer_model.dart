enum TransferStatus { pending, accepted, rejected }

class StockTransferItem {
  final int productId;
  final String productName;
  final String barcode;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double tax;
  final double discount;

  const StockTransferItem({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.tax,
    required this.discount,
  });

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * (tax / 100);
  double get discountAmount => subtotal * (discount / 100);
  double get total => subtotal + taxAmount - discountAmount;
}

class StockTransfer {
  final String transferId;
  final String warehouseName;
  final String warehouseAddress;
  final String branchName;
  final DateTime transferDate;
  final String notes;
  final List<StockTransferItem> items;
  TransferStatus status;

  StockTransfer({
    required this.transferId,
    required this.warehouseName,
    required this.warehouseAddress,
    required this.branchName,
    required this.transferDate,
    required this.notes,
    required this.items,
    this.status = TransferStatus.pending,
  });

  double get grandTotal => items.fold(0.0, (sum, i) => sum + i.total);
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);
}
