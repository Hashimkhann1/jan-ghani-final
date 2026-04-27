class AccountantTransactionEntity {
  final String id;
  final String accountantId;
  final String accountantName;
  final String branchId;
  final String branchName;
  final String transactionType;
  final double amount;
  final double previousAmount;
  final double remainingAmount;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountantTransactionEntity({
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

  bool get isCashIn => transactionType == 'cash_in';
  String get typeLabel => isCashIn ? 'Cash In' : 'Cash Out';
}