class CustomerLedgerModel {
  final String   id;
  final String   storeId;
  final String   customerId;
  final String   customerName;
  final String?  counterId;
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
    this.counterId,
    required this.previousAmount,
    required this.payAmount,
    required this.newAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  String get previousAmountLabel => 'Rs ${previousAmount.toString()}';
  String get payAmountLabel      => 'Rs ${payAmount.toString()}';
  String get newAmountLabel      => 'Rs ${newAmount.toString()}';

  /// Flexible converter jo int aur double dono ko double ma convert kara
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;
    if (value is int) return value.toDouble();

    // String ko parse kara
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }

    // Agar num type ho
    if (value is num) return value.toDouble();

    return 0.0;
  }

  factory CustomerLedgerModel.fromMap(Map<String, dynamic> map) {
    return CustomerLedgerModel(
      id:             _str(map['id'])              ?? '',
      storeId:        _str(map['store_id'])        ?? '',
      customerId:     _str(map['customer_id'])     ?? '',
      customerName:   _str(map['customer_name'])   ?? '',
      counterId:      _str(map['counter_id']),
      previousAmount: _toDouble(map['previous_amount']),
      payAmount:      _toDouble(map['pay_amount']),
      newAmount:      _toDouble(map['new_amount']),
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
    'counter_id':     counterId,
    'previous_amount': previousAmount,
    'pay_amount':     payAmount,
    'new_amount':     newAmount,
    'notes':          notes,
  };

  static String?   _str(dynamic v) => v?.toString();

  static DateTime? _date(dynamic v) {
    if (v == null)     return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CustomerLedgerModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}