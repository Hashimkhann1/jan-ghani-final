class StoreSummaryModel {
  final String   id;
  final String   storeId;
  final DateTime counterDate;
  final double   totalCashSale;
  final double   totalCardSale;
  final double   totalCreditSale;
  final double   totalInstallment;
  final double   totalCashIn;
  final double   totalCashOut;
  final double   totalExpense;
  final double   totalAmount;
  final double   totalSale;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoreSummaryModel({
    required this.id,
    required this.storeId,
    required this.counterDate,
    required this.totalCashSale,
    required this.totalCardSale,
    required this.totalCreditSale,
    required this.totalInstallment,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.totalExpense,
    required this.totalAmount,
    required this.totalSale,
    required this.createdAt,
    required this.updatedAt,
  });

  String get totalCashSaleLabel    => 'Rs ${totalCashSale.toStringAsFixed(0)}';
  String get totalCardSaleLabel    => 'Rs ${totalCardSale.toStringAsFixed(0)}';
  String get totalCreditSaleLabel  => 'Rs ${totalCreditSale.toStringAsFixed(0)}';
  String get totalInstallmentLabel => 'Rs ${totalInstallment.toStringAsFixed(0)}';
  String get totalCashInLabel      => 'Rs ${totalCashIn.toStringAsFixed(0)}';
  String get totalCashOutLabel     => 'Rs ${totalCashOut.toStringAsFixed(0)}';
  String get totalExpenseLabel     => 'Rs ${totalExpense.toStringAsFixed(0)}';
  String get totalAmountLabel      => 'Rs ${totalAmount.toStringAsFixed(0)}';
  String get totalSaleLabel        => 'Rs ${totalSale.toStringAsFixed(0)}';

  factory StoreSummaryModel.fromMap(Map<String, dynamic> map) {
    return StoreSummaryModel(
      id:               _str(map['id'])                ?? '',
      storeId:          _str(map['store_id'])          ?? '',
      counterDate:      _date(map['counter_date'])     ?? DateTime.now(),
      totalCashSale:    _dbl(map['total_cash_sale'])   ?? 0.0,
      totalCardSale:    _dbl(map['total_card_sale'])   ?? 0.0,
      totalCreditSale:  _dbl(map['total_credit_sale']) ?? 0.0,
      totalInstallment: _dbl(map['total_installment']) ?? 0.0,
      totalCashIn:      _dbl(map['total_cash_in'])     ?? 0.0,
      totalCashOut:     _dbl(map['total_cash_out'])    ?? 0.0,
      totalExpense:     _dbl(map['total_expense'])     ?? 0.0,
      totalAmount:      _dbl(map['total_amount'])      ?? 0.0,
      totalSale:        _dbl(map['total_sale'])        ?? 0.0,
      createdAt:        _date(map['created_at'])       ?? DateTime.now(),
      updatedAt:        _date(map['updated_at'])       ?? DateTime.now(),
    );
  }

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
      identical(this, other) || other is StoreSummaryModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}