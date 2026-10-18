/// Dashboard ke top stat cards ka summary data.
class InstallmentSummary {
  final int totalCustomers;
  final int newThisMonth;
  final int activeCount;
  final double remainingTotal;
  final double collectedThisMonth;

  const InstallmentSummary({
    required this.totalCustomers,
    required this.newThisMonth,
    required this.activeCount,
    required this.remainingTotal,
    required this.collectedThisMonth,
  });

  static const empty = InstallmentSummary(
    totalCustomers: 0,
    newThisMonth: 0,
    activeCount: 0,
    remainingTotal: 0,
    collectedThisMonth: 0,
  );
}
