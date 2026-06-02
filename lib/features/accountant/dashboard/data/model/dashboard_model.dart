class JanghaniAmountModel {
  final double cashInHand;

  const JanghaniAmountModel({required this.cashInHand});

  factory JanghaniAmountModel.fromMap(Map<String, dynamic> map) {
    return JanghaniAmountModel(
      cashInHand: (map['cash_in_hand'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
      id:              map['id']?.toString() ?? '',
      branchName:      map['assign_by_name']?.toString() ?? 'Unknown',
      transactionType: map['type']?.toString() ?? '',
      amount:          (map['pay_amount'] as num?)?.toDouble() ?? 0,
      createdAt:       DateTime.tryParse(
        map['created_at']?.toString() ?? '',
      ) ?? DateTime.now(),
    );
  }
}