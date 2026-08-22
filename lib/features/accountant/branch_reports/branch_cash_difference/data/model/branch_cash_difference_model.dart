class BranchCashDifferenceEntry {
  final String id;
  final String counterId;
  final double previousAmount;
  final double amount;
  final double remainingAmount;
  final String transactionType; // cash_in | cash_out
  final String? description;
  final String userId;
  final DateTime createdAt;

  const BranchCashDifferenceEntry({
    required this.id,
    required this.counterId,
    required this.previousAmount,
    required this.amount,
    required this.remainingAmount,
    required this.transactionType,
    this.description,
    required this.userId,
    required this.createdAt,
  });

  factory BranchCashDifferenceEntry.fromMap(Map<String, dynamic> m) =>
      BranchCashDifferenceEntry(
        id:        m['id'] as String,
        counterId: m['counter_id'] as String? ?? '',
        previousAmount: double.tryParse(
            m['previous_amount']?.toString() ?? '0') ?? 0,
        amount: double.tryParse(
            m['cash_out_amount']?.toString() ?? '0') ?? 0,
        remainingAmount: double.tryParse(
            m['remaining_amount']?.toString() ?? '0') ?? 0,
        transactionType: m['transaction_type'] as String? ?? '',
        description:     m['description'] as String?,
        userId:          m['user_id'] as String? ?? '',
        createdAt: DateTime.tryParse(
            m['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  bool get isCashIn => transactionType == 'cash_in';

  /// Change in cash-on-hand caused by this entry (signed).
  double get difference => remainingAmount - previousAmount;
}

/// One page of entries plus whether another page exists after it.
class PagedBranchCashDifference {
  final List<BranchCashDifferenceEntry> entries;
  final bool hasNextPage;

  const PagedBranchCashDifference({
    required this.entries,
    required this.hasNextPage,
  });
}

/// Aggregate totals across every entry matching the current filters
/// (not just the current page).
class BranchCashDifferenceTotals {
  final int    totalCount;
  final double totalCashIn;
  final double totalCashOut;

  const BranchCashDifferenceTotals({
    required this.totalCount,
    required this.totalCashIn,
    required this.totalCashOut,
  });

  double get netDifference => totalCashIn - totalCashOut;
}
