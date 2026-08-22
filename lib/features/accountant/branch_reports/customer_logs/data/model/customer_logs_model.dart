class CustomerLogEntry {
  final String id;
  final String customerId;
  final String customerName;
  final double oldBalance;
  final double newBalance;
  final double changeAmount;
  final String createdBy;
  final DateTime createdAt;

  const CustomerLogEntry({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.oldBalance,
    required this.newBalance,
    required this.changeAmount,
    required this.createdBy,
    required this.createdAt,
  });

  factory CustomerLogEntry.fromMap(Map<String, dynamic> m) =>
      CustomerLogEntry(
        id:           m['id'] as String,
        customerId:   m['customer_id'] as String? ?? '',
        customerName: m['customer_name'] as String? ?? '',
        oldBalance: double.tryParse(
            m['old_balance']?.toString() ?? '0') ?? 0,
        newBalance: double.tryParse(
            m['new_balance']?.toString() ?? '0') ?? 0,
        changeAmount: double.tryParse(
            m['change_amount']?.toString() ?? '0') ?? 0,
        createdBy: m['created_by'] as String? ?? '',
        createdAt: DateTime.tryParse(
            m['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  bool get isIncrease => changeAmount >= 0;
}

/// One page of entries plus whether another page exists after it.
class PagedCustomerLogs {
  final List<CustomerLogEntry> entries;
  final bool hasNextPage;

  const PagedCustomerLogs({
    required this.entries,
    required this.hasNextPage,
  });
}

/// Aggregate totals across every entry matching the current filters
/// (not just the current page).
class CustomerLogsTotals {
  final int    totalCount;
  final double totalIncrease;
  final double totalDecrease;

  const CustomerLogsTotals({
    required this.totalCount,
    required this.totalIncrease,
    required this.totalDecrease,
  });

  double get netChange => totalIncrease - totalDecrease;
}
