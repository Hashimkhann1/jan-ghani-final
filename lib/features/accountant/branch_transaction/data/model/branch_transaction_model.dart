class BranchTransactionModel {
  final String  id;
  final String  accountantId;
  final String  accountantName;
  final String  branchId;
  final String  branchName;
  final String  transactionType;
  final double  amount;
  final String? description;
  final DateTime createdAt;

  const BranchTransactionModel({
    required this.id,
    required this.accountantId,
    required this.accountantName,
    required this.branchId,
    required this.branchName,
    required this.transactionType,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  bool get isCashIn => transactionType == 'cash_in';

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  factory BranchTransactionModel.fromJson(Map<String, dynamic> json) =>
      BranchTransactionModel(
        id:              json['id']?.toString()              ?? '',
        accountantId:    json['accountant_id']?.toString()   ?? '',
        accountantName:  json['accountant_name']?.toString() ?? '',
        branchId:        json['branch_id']?.toString()       ?? '',
        branchName:      json['branch_name']?.toString()     ?? '',
        transactionType: json['transaction_type']?.toString() ?? '',
        amount:          _toDouble(json['amount']),
        description:     json['description']?.toString(),
        createdAt:       json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
      );
}