import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "15 Apr 2026" format.
String formatDmy(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Plan-level derived values (UI ke liye — abhi schedule mock se compute).
extension InstallmentPlanDetailX on InstallmentPlan {
  /// Har qist ka amount (total ÷ count).
  double get monthlyAmount =>
      totalCount == 0 ? 0 : totalPayable / totalCount;

  /// Agli unpaid qist ki due date (completed plan ka koi nahi).
  DateTime? get nextDueDate {
    if (status == InstallmentStatus.completed) return null;
    // Paid qiston ke baad wali = startDate + paidCount mahine.
    return DateTime(startDate.year, startDate.month + paidCount, startDate.day);
  }
}

/// Customer-level derived values (saari plans milakar).
extension InstallmentCustomerDetailX on InstallmentCustomer {
  /// Jo plans abhi chal rahe hain (completed nahi).
  int get activePlanCount =>
      plans.where((p) => p.status != InstallmentStatus.completed).length;

  /// Sabse qareeb agli due wala plan (saari plans mein se).
  InstallmentPlan? get nextDuePlan {
    final due = plans.where((p) => p.nextDueDate != null).toList()
      ..sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
    return due.isEmpty ? null : due.first;
  }

  DateTime? get nextDueDate => nextDuePlan?.nextDueDate;

  double get nextDueAmount => nextDuePlan?.monthlyAmount ?? 0;
}
