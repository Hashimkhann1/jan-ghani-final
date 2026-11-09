/// (naam, value, note) — ranked bar graphs ki ek row.
class InsightItem {
  final String name;
  final double value;
  final double extra; // second number (profit / count / stock)
  const InsightItem(this.name, this.value, [this.extra = 0]);
}

class InsightsRange {
  final List<InsightItem> hourly; // name = hour ('9'), value = sale, extra = invoices
  final List<InsightItem> category; // value = sale, extra = profit
  final List<InsightItem> staff; // value = sale, extra = invoices
  final List<InsightItem> lossProducts; // value = loss, extra = qty
  final List<InsightItem> topCustomers; // value = total, extra = invoices
  final List<InsightItem> topUdhaar; // value = balance
  final List<InsightItem> deadStock; // value = stock value, extra = stock qty
  const InsightsRange({
    required this.hourly,
    required this.category,
    required this.staff,
    required this.lossProducts,
    required this.topCustomers,
    required this.topUdhaar,
    required this.deadStock,
  });
}

/// Ek bucket (din / mahina) ke numbers.
class InsightsBucket {
  final String label;
  final double revenue, profit, discount, credit, recovered, damage, cashIn, cashOut;
  const InsightsBucket({
    required this.label,
    required this.revenue,
    required this.profit,
    required this.discount,
    required this.credit,
    required this.recovered,
    required this.damage,
    required this.cashIn,
    required this.cashOut,
  });
  double get marginPct => revenue <= 0 ? 0 : profit / revenue * 100;
}

class InsightsResult {
  final InsightsRange range;
  final List<InsightsBucket> trend;
  const InsightsResult(this.range, this.trend);
}
