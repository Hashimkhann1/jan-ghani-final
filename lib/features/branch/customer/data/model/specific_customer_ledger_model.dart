class SpecificCustomerLedgerModel {
  final String   id;
  final String   storeId;
  final String   customerId;
  final String   customerName;
  final String?  counterId;
  final double   previousAmount;
  final double   payAmount;
  final double   newAmount;
  final String?  notes;
  final DateTime createdAt;

  const SpecificCustomerLedgerModel({
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
  });

  // Payment → balance kam hua, Credit/Sale → balance barha
  bool get isPayment => payAmount > 0 && newAmount < previousAmount;

  static SpecificCustomerLedgerModel fromMap(Map<String, dynamic> m) =>
      SpecificCustomerLedgerModel(
        id:             m['id'].toString(),
        storeId:        m['store_id'].toString(),
        customerId:     m['customer_id'].toString(),
        customerName:   m['customer_name']?.toString() ?? '',
        counterId:      m['counter_id']?.toString(),
        previousAmount: _dbl(m['previous_amount']) ?? 0,
        payAmount:      _dbl(m['pay_amount'])       ?? 0,
        newAmount:      _dbl(m['new_amount'])       ?? 0,
        notes:          m['notes']?.toString(),
        createdAt:      DateTime.parse(m['created_at'].toString()).toLocal(),
      );

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num)  return v.toDouble();
    return double.tryParse(v.toString());
  }
}