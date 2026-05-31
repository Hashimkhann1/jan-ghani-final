// =============================================================
// warehouse_cash_request_model.dart
// Accountant se aayi cash request (janghani_warehouse_cash_transfers)
// Warehouse side — pending requests dikhane ke liye
// =============================================================

class WarehouseCashRequestModel {
  final String    id;
  final String    warehouseId;
  final double    amount;
  final String?   sentByName;
  final String    status;
  final String?   notes;
  final DateTime  createdAt;

  const WarehouseCashRequestModel({
    required this.id,
    required this.warehouseId,
    required this.amount,
    this.sentByName,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory WarehouseCashRequestModel.fromMap(Map<String, dynamic> map) {
    return WarehouseCashRequestModel(
      id:          map['id']?.toString() ?? '',
      warehouseId: map['warehouse_id']?.toString() ?? '',
      amount:      (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount']?.toString() ?? '') ?? 0,
      sentByName:  map['sent_by_name']?.toString(),
      status:      map['status']?.toString() ?? 'pending',
      notes:       map['notes']?.toString(),
      createdAt:   DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
