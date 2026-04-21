class InvestmentModel {
  final String id;
  final String accountantId;
  final String name;
  final double amount;
  final String? note;
  final DateTime createdAt;

  const InvestmentModel({
    required this.id,
    required this.accountantId,
    required this.name,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id:           map['id']?.toString()            ?? '',
      accountantId: map['accountant_id']?.toString() ?? '',
      name:         map['name']?.toString()          ?? '',
      amount:       (map['amount'] as num?)?.toDouble() ?? 0,
      note:         map['note']?.toString(),
      createdAt:    DateTime.tryParse(
        map['created_at']?.toString() ?? '',
      ) ?? DateTime.now(),
    );
  }
}