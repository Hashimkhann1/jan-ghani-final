// =============================================================
// salary_tracking_screen.dart — monthly salary tracking (main)
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import '../../domain/employee_month_status.dart';
import '../../domain/salary_payment_model.dart';
import '../provider/salary_provider.dart';
import '../widgets/employee_history_dialog.dart';
import '../widgets/pay_salary_dialog.dart';
import 'employees_screen.dart';

const _kMonths = [
  'January','February','March','April','May','June',
  'July','August','September','October','November','December'
];

class SalaryTrackingScreen extends ConsumerWidget {
  const SalaryTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(salaryProvider);
    final notifier = ref.read(salaryProvider.notifier);

    ref.listen<SalaryState>(salaryProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
              label: 'OK', textColor: Colors.white,
              onPressed: notifier.clearError),
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top bar: title + month nav + manage employees ──
          Container(
            color: AppColor.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(children: [
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Salary Tracking',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary)),
                    Text('Kis employee ki salary/advance paid, kaun pending',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Month navigator
              _MonthNav(
                month: state.month,
                onPrev: notifier.prevMonth,
                onNext: notifier.nextMonth,
              ),
              const SizedBox(width: 8),
              // Refresh — naya employee/payment turant dikhe (restart nahi)
              Tooltip(
                message: 'Refresh',
                child: InkWell(
                  onTap: notifier.load,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.grey100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColor.grey200),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        size: 20, color: AppColor.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                // height: 100,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => const EmployeesScreen()))
                      // Wapis aane par auto-reload — naya employee turant dikhe
                      .then((_) => notifier.load()),
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: const Text('Employees'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ),

          if (state.isLoading) const LinearProgressIndicator(minHeight: 2),

          // ── Summary cards ──
          Container(
            color: AppColor.surface,
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Row(children: [
              _StatCard(label: 'Paid', value: '${state.paidCount}/${state.totalEmployees}',
                  icon: Icons.check_circle_outline_rounded, color: AppColor.success),
              const SizedBox(width: 12),
              _StatCard(label: 'Pending', value: '${state.pendingCount}',
                  icon: Icons.schedule_rounded, color: AppColor.warning),
              const SizedBox(width: 12),
              _StatCard(label: 'Total Paid', value: 'Rs ${state.totalPaid.pkrFormat}',
                  icon: Icons.payments_outlined, color: AppColor.primary),
              const SizedBox(width: 12),
              _StatCard(label: 'Remaining', value: 'Rs ${state.totalRemaining.pkrFormat}',
                  icon: Icons.account_balance_wallet_outlined, color: AppColor.error),
            ]),
          ),

          // ── Employee list ──
          Expanded(
            child: state.statuses.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.statuses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _EmployeeRow(
                      status: state.statuses[i],
                      onPay: () => PaySalaryDialog.show(context, state.statuses[i]),
                      onHistory: () => EmployeeHistoryDialog.show(
                          context, state.statuses[i].employee),
                      onDeletePayment: (p) => notifier.deletePayment(p),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Month navigator ──
class _MonthNav extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev, onNext;
  const _MonthNav({required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.grey100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, size: 20)),
        SizedBox(
          width: 130,
          child: Text('${_kMonths[month.month - 1]} ${month.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary)),
        ),
        IconButton(onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, size: 20)),
      ]),
    );
  }
}

// ── Employee row ──
class _EmployeeRow extends StatelessWidget {
  final EmployeeMonthStatus status;
  final VoidCallback onPay;
  final VoidCallback onHistory;
  final ValueChanged<SalaryPaymentModel> onDeletePayment;

  const _EmployeeRow({
    required this.status,
    required this.onPay,
    required this.onHistory,
    required this.onDeletePayment,
  });

  Color get _statusColor {
    switch (status.status) {
      case SalaryStatus.paid:    return AppColor.success;
      case SalaryStatus.partial: return AppColor.warning;
      case SalaryStatus.pending: return AppColor.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = status;
    // Row par tap → employee ka poora salary record (history dialog)
    return InkWell(
      onTap: onHistory,
      borderRadius: BorderRadius.circular(12),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(children: [
        Row(children: [
          // Avatar
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              s.employee.name.isEmpty ? '?' : s.employee.name[0].toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColor.primary),
            ),
          ),
          const SizedBox(width: 12),
          // Name + phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.employee.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(
                    'Salary Rs ${s.monthlySalary.pkrFormat}'
                    '${s.employee.phone != null ? " · ${s.employee.phone}" : ""}',
                    style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
              ],
            ),
          ),
          // Paid / remaining
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Paid Rs ${s.totalPaid.pkrFormat}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary)),
              Text('Baaki Rs ${s.remaining.pkrFormat}',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor)),
            ],
          ),
          const SizedBox(width: 12),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(s.statusLabel,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
          ),
          const SizedBox(width: 8),
          // History hint — row tap se poora record khulta hai
          const Icon(Icons.history_rounded, size: 16, color: AppColor.grey400),
          const SizedBox(width: 8),
          // Pay button
          SizedBox(
            width: 120,
            height: 35,
            child: ElevatedButton(
              onPressed: s.status == SalaryStatus.paid ? null : onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: AppColor.white,
                disabledBackgroundColor: AppColor.grey200,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),

        // This month ke payments
        if (s.payments.isNotEmpty) ...[
          const Divider(height: 18),
          ...s.payments.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Icon(p.isAdvance ? Icons.trending_down_rounded : Icons.payments_outlined,
                      size: 13, color: p.isAdvance ? AppColor.warning : AppColor.success),
                  const SizedBox(width: 6),
                  Text('${p.typeLabel} · Rs ${p.amount.pkrFormat}',
                      style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                  if (p.notes != null && p.notes!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('· ${p.notes}',
                          style: const TextStyle(fontSize: 11, color: AppColor.textHint),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ] else const Spacer(),
                  Text(
                      DateFormat('dd MMM yyyy · hh:mm a')
                          .format(p.createdAt.toLocal()),
                      style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
                  // GestureDetector(
                  //   onTap: () => onDeletePayment(p),
                  //   child: const Padding(
                  //     padding: EdgeInsets.only(left: 8),
                  //     child: Icon(Icons.delete_outline_rounded,
                  //         size: 15, color: AppColor.error),
                  //   ),
                  // ),
                ]),
              )),
        ],
      ]),
      ),
    );
  }
}

// ── Stat card ──
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.badge_outlined, size: 56, color: AppColor.grey300),
        const SizedBox(height: 12),
        const Text('Koi active employee nahi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColor.textSecondary)),
        const SizedBox(height: 4),
        const Text('"Employees" button se employee add karein',
            style: TextStyle(fontSize: 13, color: AppColor.textHint)),
      ]),
    );
  }
}
