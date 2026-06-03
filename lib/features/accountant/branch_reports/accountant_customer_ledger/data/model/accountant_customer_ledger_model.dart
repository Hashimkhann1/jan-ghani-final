// accountant_customer_ledger_model.dart

class CustomerLedgerModel {
  final String  id;
  final String  customerId;
  final String  customerName;
  final double  previousAmount;
  final double  payAmount;
  final double  newAmount;
  final String? notes;
  final DateTime createdAt;

  const CustomerLedgerModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.previousAmount,
    required this.payAmount,
    required this.newAmount,
    this.notes,
    required this.createdAt,
  });

  factory CustomerLedgerModel.fromMap(Map<String, dynamic> m) =>
      CustomerLedgerModel(
        id:             m['id']            as String,
        customerId:     m['customer_id']   as String,
        customerName:   m['customer_name'] as String,
        previousAmount: double.parse(m['previous_amount'].toString()),
        payAmount:      double.parse(m['pay_amount'].toString()),
        newAmount:      double.parse(m['new_amount'].toString()),
        notes:          m['notes']         as String?,
        createdAt:      DateTime.parse(m['created_at'] as String),
      );
}