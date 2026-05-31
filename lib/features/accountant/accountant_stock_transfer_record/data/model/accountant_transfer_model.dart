// =============================================================
// accountant_transfer_model.dart
// Accountant ke Stock Transfer Record feature ke models (read-only)
//   • AccTransferModel      → stock_transfers
//   • AccTransferItemModel  → stock_transfer_items
// =============================================================

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime _toDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString()) ?? DateTime.now();
}

DateTime? _toDateN(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

// ─────────────────────────────────────────────────────────────
// TRANSFER  (stock_transfers)
// ─────────────────────────────────────────────────────────────
class AccTransferModel {
  final String    id;
  final String    transferNumber;
  final String    toStoreName;
  final String    status;
  final String?   assignedByName;
  final DateTime? assignedAt;
  final String?   notes;
  final int       totalItems;
  final double    totalCost;
  final double    totalSalePrice;
  final DateTime  createdAt;

  const AccTransferModel({
    required this.id,
    required this.transferNumber,
    required this.toStoreName,
    required this.status,
    this.assignedByName,
    this.assignedAt,
    this.notes,
    required this.totalItems,
    required this.totalCost,
    required this.totalSalePrice,
    required this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case 'pending':   return 'Pending';
      case 'accepted':  return 'Accepted';
      case 'approved':  return 'Approved';
      case 'received':  return 'Received';
      case 'rejected':  return 'Rejected';
      case 'cancelled': return 'Cancelled';
      default:          return status;
    }
  }

  factory AccTransferModel.fromMap(Map<String, dynamic> map) {
    return AccTransferModel(
      id:             map['id']?.toString() ?? '',
      transferNumber: map['transfer_number']?.toString() ?? '',
      toStoreName:    map['to_store_name']?.toString() ?? 'Unknown Store',
      status:         map['status']?.toString() ?? '',
      assignedByName: map['assigned_by_name']?.toString(),
      assignedAt:     _toDateN(map['assigned_at']),
      notes:          map['notes']?.toString(),
      totalItems:     _toInt(map['total_items']),
      totalCost:      _toDouble(map['total_cost']),
      totalSalePrice: _toDouble(map['total_sale_price']),
      createdAt:      _toDate(map['created_at']),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TRANSFER ITEM  (stock_transfer_items)
// ─────────────────────────────────────────────────────────────
class AccTransferItemModel {
  final String  id;
  final String  productName;
  final String? sku;
  final String  unitOfMeasure;
  final double  quantitySent;
  final double  quantityReceived;
  final double  unitCost;
  final double  salePrice;
  final double  totalCost;

  const AccTransferItemModel({
    required this.id,
    required this.productName,
    this.sku,
    required this.unitOfMeasure,
    required this.quantitySent,
    required this.quantityReceived,
    required this.unitCost,
    required this.salePrice,
    required this.totalCost,
  });

  factory AccTransferItemModel.fromMap(Map<String, dynamic> map) {
    return AccTransferItemModel(
      id:               map['id']?.toString() ?? '',
      productName:      map['product_name']?.toString() ?? 'Unknown',
      sku:              map['sku']?.toString(),
      unitOfMeasure:    map['unit_of_measure']?.toString() ?? 'pcs',
      quantitySent:     _toDouble(map['quantity_sent']),
      quantityReceived: _toDouble(map['quantity_received']),
      unitCost:         _toDouble(map['unit_cost']),
      salePrice:        _toDouble(map['sale_price']),
      totalCost:        _toDouble(map['total_cost']),
    );
  }
}
