// =============================================================
// cash_transfer_model.dart
// Accountant → Warehouse cash transfer (janghani_warehouse_cash_transfers)
// =============================================================

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
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

class CashTransferModel {
  final String    id;
  final String    warehouseId;
  final String?   warehouseName;
  final double    amount;
  final String?   sentByName;
  final String    status; // pending | accepted | rejected
  final String?   notes;
  final String?   respondedByName;
  final DateTime? respondedAt;
  final DateTime  createdAt;

  const CashTransferModel({
    required this.id,
    required this.warehouseId,
    this.warehouseName,
    required this.amount,
    this.sentByName,
    required this.status,
    this.notes,
    this.respondedByName,
    this.respondedAt,
    required this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case 'pending':  return 'Pending';
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      default:         return status;
    }
  }

  factory CashTransferModel.fromMap(Map<String, dynamic> map) {
    return CashTransferModel(
      id:              map['id']?.toString() ?? '',
      warehouseId:     map['warehouse_id']?.toString() ?? '',
      warehouseName:   map['warehouse_name']?.toString(),
      amount:          _toDouble(map['amount']),
      sentByName:      map['sent_by_name']?.toString(),
      status:          map['status']?.toString() ?? 'pending',
      notes:           map['notes']?.toString(),
      respondedByName: map['responded_by_name']?.toString(),
      respondedAt:     _toDateN(map['responded_at']),
      createdAt:       _toDate(map['created_at']),
    );
  }
}
