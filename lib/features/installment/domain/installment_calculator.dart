import 'package:jan_ghani_final/features/website/data/website_content.dart'
    as web show InstallmentPlan, WebsiteContent;

/// Qiston ki ek draft qist (plan banate waqt database ko jati hai).
class InstallmentDueDraft {
  final int number;
  final DateTime dueDate;
  final double amount;
  const InstallmentDueDraft(this.number, this.dueDate, this.amount);
}

/// Calculator ka nateeja — website ke calculator wala hi formula:
/// baqi raqam x (1 + 2.5% x mahine), qist 50 ke multiple mein, aakhri qist
/// mein farq adjust.
class InstallmentQuote {
  final int months;
  final double price;
  final double advance;
  final double financed;
  final double total;
  final double monthly;
  final double last;

  const InstallmentQuote({
    required this.months,
    required this.price,
    required this.advance,
    required this.financed,
    required this.total,
    required this.monthly,
    required this.last,
  });

  /// Kul charge (total - financed).
  double get charge => total - financed;

  /// Customer ko advance samet kul kitna dena hoga.
  double get grandTotal => advance + total;

  /// Qiston ka schedule: pehli qist start date se 1 mahine baad.
  List<InstallmentDueDraft> schedule(DateTime start) => [
        for (var i = 1; i <= months; i++)
          InstallmentDueDraft(
            i,
            InstallmentCalculator.addMonths(start, i),
            i == months ? last : monthly,
          ),
      ];
}

class InstallmentCalculator {
  InstallmentCalculator._();

  static const List<int> plans = web.WebsiteContent.instPlans;
  static const double minAdvancePct = web.WebsiteContent.instMinAdvance;
  static const double ratePerMonth = web.WebsiteContent.instRatePerMonth;

  /// Kam az kam advance (qeemat ka 15%).
  static double minAdvance(double price) => (price * minAdvancePct).ceilToDouble();

  /// Advance theek hai? (kam az kam 15%, aur qeemat se kam taake qist bane)
  static String? validateAdvance(double price, double advance) {
    if (price <= 0) return 'Enter the product price';
    if (advance < minAdvance(price)) {
      return 'Advance must be at least ${(minAdvancePct * 100).round()}% '
          '(Rs ${minAdvance(price).toStringAsFixed(0)})';
    }
    if (advance >= price) return 'Advance must be less than the price';
    return null;
  }

  static InstallmentQuote quote({
    required double price,
    required double advance,
    required int months,
  }) {
    final financed = price - advance;
    final p = web.InstallmentPlan.of(financed, months);
    return InstallmentQuote(
      months: months,
      price: price,
      advance: advance,
      financed: financed,
      total: p.total,
      monthly: p.monthly,
      last: p.last,
    );
  }

  /// Mahina add karo — din us mahine ki aakhri tareekh se zyada na ho (31 → 28/30).
  static DateTime addMonths(DateTime d, int months) {
    final target = DateTime(d.year, d.month + months, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(target.year, target.month, d.day > lastDay ? lastDay : d.day);
  }
}
