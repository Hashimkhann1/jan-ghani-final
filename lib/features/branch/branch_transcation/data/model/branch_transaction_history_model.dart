class BranchTransactionHistoryModel {
  final String   id;
  final String   branchId;
  final String   assignById;
  final String   assignByName;
  final String   assignToId;
  final String   type;
  final double   beforeAmount;
  final double   payAmount;
  final double   afterAmount;
  final bool     isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BranchTransactionHistoryModel({
    required this.id,
    required this.branchId,
    required this.assignById,
    required this.assignByName,
    required this.assignToId,
    required this.type,
    required this.beforeAmount,
    required this.payAmount,
    required this.afterAmount,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchTransactionHistoryModel.fromMap(Map<String, dynamic> m) {
    return BranchTransactionHistoryModel(
      id:            m['id']?.toString()             ?? '',
      branchId:      m['branch_id']?.toString()      ?? '',
      assignById:    m['assign_by_id']?.toString()   ?? '',
      assignByName:  m['assign_by_name']?.toString() ?? '',
      assignToId:    m['assign_to_id']?.toString()   ?? '',
      type:          m['type']?.toString()           ?? 'cash_out',
      beforeAmount:  _toDouble(m['before_amount']),
      payAmount:     _toDouble(m['pay_amount']),
      afterAmount:   _toDouble(m['after_amount']),
      isSynced:      m['is_synced'] as bool?         ?? false,
      createdAt:     DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:     DateTime.tryParse(m['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    return double.tryParse(v.toString()) ?? 0.0;
  }
}