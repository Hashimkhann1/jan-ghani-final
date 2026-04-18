class CashTransactionModel {
  final String   id;
  final String   storeId;
  final String?  counterId;       // ← FIX: add kiya
  final double   previousAmount;
  final double   cashOutAmount;
  final double   remainingAmount;
  final String?  description;
  final String   transactionType;
  final DateTime  createdAt;
  final DateTime  updatedAt;
  final DateTime? deletedAt;

  const CashTransactionModel({
    required this.id,
    required this.storeId,
    this.counterId,
    required this.previousAmount,
    required this.cashOutAmount,
    required this.remainingAmount,
    this.description,
    required this.transactionType,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isCashIn  => transactionType == 'cash_in';
  bool get isCashOut => transactionType == 'cash_out';

  String get typeLabel            => isCashIn ? 'Cash In' : 'Cash Out';
  String get previousAmountLabel  => 'Rs ${previousAmount.toStringAsFixed(0)}';
  String get cashOutAmountLabel   => 'Rs ${cashOutAmount.toStringAsFixed(0)}';
  String get remainingAmountLabel => 'Rs ${remainingAmount.toStringAsFixed(0)}';

  factory CashTransactionModel.fromMap(Map<String, dynamic> map) {
    return CashTransactionModel(
      id:              _str(map['id'])               ?? '',
      storeId:         _str(map['store_id'])         ?? '',
      counterId:       _str(map['counter_id']),      // ← FIX
      previousAmount:  _dbl(map['previous_amount'])  ?? 0.0,
      cashOutAmount:   _dbl(map['cash_out_amount'])  ?? 0.0,
      remainingAmount: _dbl(map['remaining_amount']) ?? 0.0,
      description:     _str(map['description']),
      transactionType: _str(map['transaction_type']) ?? 'cash_in',
      createdAt:       _date(map['created_at'])      ?? DateTime.now(),
      updatedAt:       _date(map['updated_at'])      ?? DateTime.now(),
      deletedAt:       _date(map['deleted_at']),
    );
  }

  static String?   _str(dynamic v)  => v?.toString();
  static double?   _dbl(dynamic v)  {
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
      identical(this, other) || other is CashTransactionModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}