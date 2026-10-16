
class BranchTransactionModel {
  final String  id;
  final String  branchId;
  final String  assignById;
  final String  assignByName;
  final String  assignToId;
  final String  type;           // cash_in | cash_out
  final double  beforeAmount;
  final double  payAmount;
  final double  afterAmount;
  final bool    isSynced;
  /// Accountant ne cash receive kar liya → amount janghani_net_amount mein add.
  /// false = Pending.
  final bool    isReceived;
  final DateTime? receivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BranchTransactionModel({
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
    required this.isReceived,
    this.receivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchTransactionModel.fromMap(Map<String, dynamic> m) =>
      BranchTransactionModel(
        id:           m['id']             as String,
        branchId:     m['branch_id']      as String?  ?? '',
        assignById:   m['assign_by_id']   as String?  ?? '',
        assignByName: m['assign_by_name'] as String?  ?? '',
        assignToId:   m['assign_to_id']   as String?  ?? '',
        type:         m['type']           as String?  ?? '',
        beforeAmount: double.tryParse(
            m['before_amount']?.toString() ?? '0') ?? 0,
        payAmount:    double.tryParse(
            m['pay_amount']?.toString()    ?? '0') ?? 0,
        afterAmount:  double.tryParse(
            m['after_amount']?.toString()  ?? '0') ?? 0,
        isSynced:     m['is_synced']       as bool?   ?? false,
        isReceived:   m['is_received']     as bool?   ?? false,
        receivedAt:   DateTime.tryParse(m['received_at']?.toString() ?? ''),
        createdAt:    DateTime.tryParse(
            m['created_at']?.toString()    ?? '') ?? DateTime.now(),
        updatedAt:    DateTime.tryParse(
            m['updated_at']?.toString()    ?? '') ?? DateTime.now(),
      );

  /// Cash In ya Cash Out check karna
  bool get isCashIn  => type == 'cash_in';
  bool get isCashOut => type == 'cash_out';

  bool get isPending => isCashOut && !isReceived;

  BranchTransactionModel markReceived() => BranchTransactionModel(
        id:           id,
        branchId:     branchId,
        assignById:   assignById,
        assignByName: assignByName,
        assignToId:   assignToId,
        type:         type,
        beforeAmount: beforeAmount,
        payAmount:    payAmount,
        afterAmount:  afterAmount,
        isSynced:     isSynced,
        isReceived:   true,
        receivedAt:   DateTime.now(),
        createdAt:    createdAt,
        updatedAt:    updatedAt,
      );
}

/// One page of transactions plus whether another page exists after it.
class PagedBranchTransactions {
  final List<BranchTransactionModel> transactions;
  final bool hasNextPage;

  const PagedBranchTransactions({
    required this.transactions,
    required this.hasNextPage,
  });
}

/// Aggregate totals across every transaction matching the current filters
/// (not just the current page).
class BranchTransactionTotals {
  final int    totalCount;
  final double totalCashOut;
  final double pendingAmount;

  const BranchTransactionTotals({
    required this.totalCount,
    required this.totalCashOut,
    required this.pendingAmount,
  });
}