// =============================================================
// employee_month_status.dart
// Ek employee ka ek MAHINE ka status (computed) — salary tracking screen.
// =============================================================

import 'employee_model.dart';
import 'salary_payment_model.dart';

enum SalaryStatus { pending, partial, paid }

class EmployeeMonthStatus {
  final EmployeeModel employee;
  final DateTime      month;                 // 1st of month
  final List<SalaryPaymentModel> payments;   // is mahine ke saare payments

  const EmployeeMonthStatus({
    required this.employee,
    required this.month,
    this.payments = const [],
  });

  double get monthlySalary => employee.monthlySalary;

  // Advance + salary alag-alag totals (is mahine)
  double get advancePaid =>
      payments.where((p) => p.isAdvance).fold(0.0, (s, p) => s + p.amount);
  double get salaryPaid =>
      payments.where((p) => !p.isAdvance).fold(0.0, (s, p) => s + p.amount);

  // Advance BHI salary total mein count hota hai (auto-adjust)
  double get totalPaid => advancePaid + salaryPaid;

  // Ab tak kitna dena baaki
  double get remaining =>
      (monthlySalary - totalPaid).clamp(0.0, double.infinity);

  // Advance ki bacchi hui limit (max − already taken)
  double get advanceRemaining =>
      (employee.maxAdvanceAmount - advancePaid).clamp(0.0, double.infinity);

  SalaryStatus get status {
    if (totalPaid <= 0) return SalaryStatus.pending;
    if (totalPaid >= monthlySalary && monthlySalary > 0) return SalaryStatus.paid;
    return SalaryStatus.partial;
  }

  String get statusLabel {
    switch (status) {
      case SalaryStatus.paid:    return 'Paid';
      case SalaryStatus.partial: return 'Partial';
      case SalaryStatus.pending: return 'Pending';
    }
  }
}
