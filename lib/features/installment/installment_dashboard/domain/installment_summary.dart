/// Dashboard ke top stat cards ka summary data.
class InstallmentSummary {
  final int totalCustomers;
  final double customersGrowthPct;
  final int activeCount;
  final double remainingTotal;
  final double collectedThisMonth;

  const InstallmentSummary({
    required this.totalCustomers,
    required this.customersGrowthPct,
    required this.activeCount,
    required this.remainingTotal,
    required this.collectedThisMonth,
  });
}
