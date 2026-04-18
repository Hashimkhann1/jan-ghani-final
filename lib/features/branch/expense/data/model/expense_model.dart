class ExpenseModel {
  final String   id;
  final String   storeId;
  final String   expenseHead;
  final double   amount;
  final String?  description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ExpenseModel({
    required this.id,
    required this.storeId,
    required this.expenseHead,
    required this.amount,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  String get amountLabel => 'Rs ${amount.toStringAsFixed(0)}';

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id:          _str(map['id'])           ?? '',
      storeId:     _str(map['store_id'])     ?? '',
      expenseHead: _str(map['expense_head']) ?? '',
      amount:      _dbl(map['amount'])       ?? 0.0,
      description: _str(map['description']),
      createdAt:   _date(map['created_at'])  ?? DateTime.now(),
      updatedAt:   _date(map['updated_at'])  ?? DateTime.now(),
      deletedAt:   _date(map['deleted_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'store_id':     storeId,
    'expense_head': expenseHead,
    'amount':       amount,
    'description':  description,
  };

  ExpenseModel copyWith({
    String?  expenseHead,
    double?  amount,
    String?  description,
  }) {
    return ExpenseModel(
      id:          id,
      storeId:     storeId,
      expenseHead: expenseHead ?? this.expenseHead,
      amount:      amount      ?? this.amount,
      description: description ?? this.description,
      createdAt:   createdAt,
      updatedAt:   DateTime.now(),
      deletedAt:   deletedAt,
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
      identical(this, other) ||
          other is ExpenseModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ExpenseModel(id: $id, head: $expenseHead, amount: $amount)';
}