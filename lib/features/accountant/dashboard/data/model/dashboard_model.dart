class AccountantCounterModel {
  final double totalAmount;
  final double totalInvestment;

  const AccountantCounterModel({
    required this.totalAmount,
    required this.totalInvestment,
  });

  factory AccountantCounterModel.fromMap(Map<String, dynamic> map) {
    return AccountantCounterModel(
      totalAmount:      (map['total_amount']      as num?)?.toDouble() ?? 0,
      totalInvestment:  (map['total_investment']  as num?)?.toDouble() ?? 0,
    );
  }
}

class RecentTransactionModel {
  final String id;
  final String branchName;
  final String transactionType;
  final double amount;
  final DateTime createdAt;

  const RecentTransactionModel({
    required this.id,
    required this.branchName,
    required this.transactionType,
    required this.amount,
    required this.createdAt,
  });

  factory RecentTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecentTransactionModel(
      id:              map['id']?.toString()               ?? '',
      branchName:      map['branch_name']?.toString()      ?? 'Unknown',
      transactionType: map['transaction_type']?.toString() ?? '',
      amount:          (map['amount'] as num?)?.toDouble() ?? 0,
      createdAt:       DateTime.tryParse(
        map['created_at']?.toString() ?? '',
      ) ?? DateTime.now(),
    );
  }
}