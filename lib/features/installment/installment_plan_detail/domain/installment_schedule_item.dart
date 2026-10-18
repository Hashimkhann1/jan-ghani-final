import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';

/// Ek qist ki haalat (schedule row ke liye).
enum ScheduleStatus { paid, due, upcoming }

extension ScheduleStatusX on ScheduleStatus {
  String get label => switch (this) {
        ScheduleStatus.paid => 'Paid',
        ScheduleStatus.due => 'Due',
        ScheduleStatus.upcoming => 'Upcoming',
      };

  Color get color => switch (this) {
        ScheduleStatus.paid => AppColor.success,
        ScheduleStatus.due => AppColor.warningDark,
        ScheduleStatus.upcoming => AppColor.grey600,
      };

  Color get bgColor => switch (this) {
        ScheduleStatus.paid => AppColor.successLight,
        ScheduleStatus.due => AppColor.warningLight,
        ScheduleStatus.upcoming => AppColor.grey100,
      };
}

/// Schedule ki ek qist.
class InstallmentScheduleItem {
  final int number;
  final DateTime dueDate;
  final double amount;
  final ScheduleStatus status;

  /// Qist ka id (record payment ke liye) aur ab tak kitna ada hua.
  final String? id;
  final double paidAmount;

  const InstallmentScheduleItem({
    required this.number,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.id,
    this.paidAmount = 0,
  });

  double get remaining =>
      (amount - paidAmount).clamp(0, double.infinity).toDouble();

  bool get isPartial => paidAmount > 0 && status != ScheduleStatus.paid;

  /// Due qist ki date guzar chuki hai?
  bool get isOverdue {
    if (status != ScheduleStatus.due) return false;
    final now = DateTime.now();
    return DateTime(dueDate.year, dueDate.month, dueDate.day)
        .isBefore(DateTime(now.year, now.month, now.day));
  }
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "15 Apr 2026" format.
String planDetailDmy(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Plan se qiston ka schedule generate karo (abhi mock — baad mein DB se aayega).
/// paid qisten → Paid, agli ek → Due, baaki → Upcoming.
List<InstallmentScheduleItem> buildScheduleFromPlan(InstallmentPlan plan) {
  // Asli schedule (database) ho to wahi: paid → Paid, pehli unpaid → Due.
  if (plan.dues.isNotEmpty) {
    final firstUnpaid = plan.dues.indexWhere((d) => !d.isPaid);
    return [
      for (var i = 0; i < plan.dues.length; i++)
        InstallmentScheduleItem(
          id: plan.dues[i].id,
          number: plan.dues[i].number,
          dueDate: plan.dues[i].dueDate,
          amount: plan.dues[i].amount,
          paidAmount: plan.dues[i].paidAmount,
          status: plan.dues[i].isPaid
              ? ScheduleStatus.paid
              : (i == firstUnpaid ? ScheduleStatus.due : ScheduleStatus.upcoming),
        ),
    ];
  }
  final monthly = plan.totalCount == 0 ? 0.0 : plan.totalPayable / plan.totalCount;
  return List.generate(plan.totalCount, (i) {
    final date = DateTime(
      plan.startDate.year,
      plan.startDate.month + i,
      plan.startDate.day,
    );
    final ScheduleStatus status;
    if (i < plan.paidCount) {
      status = ScheduleStatus.paid;
    } else if (i == plan.paidCount) {
      status = ScheduleStatus.due;
    } else {
      status = ScheduleStatus.upcoming;
    }
    return InstallmentScheduleItem(
      number: i + 1,
      dueDate: date,
      amount: monthly,
      status: status,
    );
  });
}
