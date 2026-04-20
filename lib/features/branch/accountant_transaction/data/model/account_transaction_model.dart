class AccountantTransactionModel {
  final String  id;
  final String  accountantId;
  final String  accountantName;
  final String  branchId;
  final String  branchName;       // ← نیا field
  final String  transactionType;
  final double  amount;
  final double  previousAmount;
  final double  remainingAmount;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountantTransactionModel({
    required this.id,
    required this.accountantId,
    required this.accountantName,
    required this.branchId,
    required this.branchName,
    required this.transactionType,
    required this.amount,
    required this.previousAmount,
    required this.remainingAmount,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  bool   get isCashIn   => transactionType == 'cash_in';
  String get typeLabel  => isCashIn ? 'Cash In' : 'Cash Out';

  factory AccountantTransactionModel.fromJson(Map<String, dynamic> json) =>
      AccountantTransactionModel(
        id:              json['id']               as String,
        accountantId:    json['accountant_id']    as String,
        accountantName:  json['accountant_name']  as String,
        branchId:        json['branch_id']        as String,
        branchName:      json['branch_name']      as String? ?? '',
        transactionType: json['transaction_type'] as String,
        amount:          (json['amount']          as num).toDouble(),
        previousAmount:  (json['previous_amount'] as num? ?? 0).toDouble(),
        remainingAmount: (json['remaining_amount'] as num? ?? 0).toDouble(),
        description:     json['description']      as String?,
        createdAt:       DateTime.parse(json['created_at'] as String),
        updatedAt:       DateTime.parse(json['updated_at'] as String),
      );
}