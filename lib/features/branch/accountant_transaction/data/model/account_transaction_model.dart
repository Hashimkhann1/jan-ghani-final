import '../../domain/entity/accountant_transaction_entity.dart';
import '../../domain/entity/accountant_user_entity.dart';

// ── AccountantTransactionModel ────────────────────────────────────────────────

class AccountantTransactionModel {
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

  /// Local DB row map → model (nullable-safe, type-flexible)
  factory AccountantTransactionModel.fromRowMap(Map<String, dynamic> m) =>
      AccountantTransactionModel(
        id:              m['id']?.toString()              ?? '',
        accountantId:    m['accountant_id']?.toString()   ?? '',
        accountantName:  m['accountant_name']?.toString() ?? '',
        branchId:        m['branch_id']?.toString()       ?? '',
        branchName:      m['branch_name']?.toString()     ?? '',
        transactionType: m['transaction_type']?.toString() ?? '',
        amount:          _toDouble(m['amount']),
        previousAmount:  _toDouble(m['previous_amount']),
        remainingAmount: _toDouble(m['remaining_amount']),
        description:     m['description']?.toString(),
        createdAt:       m['created_at'] != null
            ? DateTime.parse(m['created_at'].toString())
            : DateTime.now(),
        updatedAt:       m['updated_at'] != null
            ? DateTime.parse(m['updated_at'].toString())
            : DateTime.now(),
      );

  AccountantTransactionEntity toEntity() => AccountantTransactionEntity(
    id:              id,
    accountantId:    accountantId,
    accountantName:  accountantName,
    branchId:        branchId,
    branchName:      branchName,
    transactionType: transactionType,
    amount:          amount,
    previousAmount:  previousAmount,
    remainingAmount: remainingAmount,
    description:     description,
    createdAt:       createdAt,
    updatedAt:       updatedAt,
  );

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}


