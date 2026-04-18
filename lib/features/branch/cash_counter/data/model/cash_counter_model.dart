class CashCounterModel {
  final String   id;
  final String   storeId;
  final String   counterId;
  final DateTime counterDate;
  final double   cashSale;
  final double   cardSale;
  final double   creditSale;
  final double   installment;
  final double   cashIn;
  final double   cashOut;
  final double   totalSale;
  final double   totalAmount;
  final DateTime  createdAt;
  final DateTime  updatedAt;
  final DateTime? deletedAt;

  const CashCounterModel({
    required this.id,
    required this.storeId,
    required this.counterId,
    required this.counterDate,
    required this.cashSale,
    required this.cardSale,
    required this.creditSale,
    required this.installment,
    required this.cashIn,
    required this.cashOut,
    required this.totalSale,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // ── Labels ────────────────────────────────────────────────
  String get cashSaleLabel    => 'Rs ${cashSale.toStringAsFixed(0)}';
  String get cardSaleLabel    => 'Rs ${cardSale.toStringAsFixed(0)}';
  String get creditSaleLabel  => 'Rs ${creditSale.toStringAsFixed(0)}';
  String get installmentLabel => 'Rs ${installment.toStringAsFixed(0)}';
  String get cashInLabel      => 'Rs ${cashIn.toStringAsFixed(0)}';
  String get cashOutLabel     => 'Rs ${cashOut.toStringAsFixed(0)}';
  String get totalSaleLabel   => 'Rs ${totalSale.toStringAsFixed(0)}';
  String get totalAmountLabel => 'Rs ${totalAmount.toStringAsFixed(0)}';

  factory CashCounterModel.fromMap(Map<String, dynamic> map) {
    return CashCounterModel(
      id:          _str(map['id'])           ?? '',
      storeId:     _str(map['store_id'])     ?? '',
      counterId:   _str(map['counter_id'])   ?? '',
      counterDate: _date(map['counter_date']) ?? DateTime.now(),
      cashSale:    _dbl(map['cash_sale'])    ?? 0.0,
      cardSale:    _dbl(map['card_sale'])    ?? 0.0,
      creditSale:  _dbl(map['credit_sale'])  ?? 0.0,
      installment: _dbl(map['installment'])  ?? 0.0,
      cashIn:      _dbl(map['cash_in'])      ?? 0.0,
      cashOut:     _dbl(map['cash_out'])     ?? 0.0,
      totalSale:   _dbl(map['total_sale'])   ?? 0.0,
      totalAmount: _dbl(map['total_amount']) ?? 0.0,
      createdAt:   _date(map['created_at'])  ?? DateTime.now(),
      updatedAt:   _date(map['updated_at'])  ?? DateTime.now(),
      deletedAt:   _date(map['deleted_at']),
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
      identical(this, other) || other is CashCounterModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}