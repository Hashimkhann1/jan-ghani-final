class CustomerLedgerModel {
  final String   id;
  final String   storeId;
  final String   customerId;
  final String   customerName;
  final String?  counterId;    // ← new
  final double   previousAmount;
  final double   payAmount;
  final double   newAmount;
  final String?  notes;
  final DateTime  createdAt;
  final DateTime  updatedAt;
  final DateTime? deletedAt;

  const CustomerLedgerModel({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.customerName,
    this.counterId,             // ← new
    required this.previousAmount,
    required this.payAmount,
    required this.newAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  String get previousAmountLabel => 'Rs ${previousAmount.toStringAsFixed(0)}';
  String get payAmountLabel      => 'Rs ${payAmount.toStringAsFixed(0)}';
  String get newAmountLabel      => 'Rs ${newAmount.toStringAsFixed(0)}';

  factory CustomerLedgerModel.fromMap(Map<String, dynamic> map) {
    return CustomerLedgerModel(
      id:             _str(map['id'])              ?? '',
      storeId:        _str(map['store_id'])        ?? '',
      customerId:     _str(map['customer_id'])     ?? '',
      customerName:   _str(map['customer_name'])   ?? '',
      counterId:      _str(map['counter_id']),      // ← new
      previousAmount: _dbl(map['previous_amount']) ?? 0.0,
      payAmount:      _dbl(map['pay_amount'])      ?? 0.0,
      newAmount:      _dbl(map['new_amount'])      ?? 0.0,
      notes:          _str(map['notes']),
      createdAt:      _date(map['created_at'])     ?? DateTime.now(),
      updatedAt:      _date(map['updated_at'])     ?? DateTime.now(),
      deletedAt:      _date(map['deleted_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'store_id':       storeId,
    'customer_id':    customerId,
    'customer_name':  customerName,
    'counter_id':     counterId,   // ← new
    'previous_amount': previousAmount,
    'pay_amount':     payAmount,
    'new_amount':     newAmount,
    'notes':          notes,
  };

  static String?   _str(dynamic v) => v?.toString();
  static double?   _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
  static DateTime? _date(dynamic v) {
    if (v == null)     return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CustomerLedgerModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}