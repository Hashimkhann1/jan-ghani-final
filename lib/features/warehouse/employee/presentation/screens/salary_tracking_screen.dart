// Updated on 2026-10-02 10:04 AM
// =============================================================
// salary_tracking_screen.dart — monthly salary tracking (main)
// Mobile (< 700px): top bar 2 lines, cards 2×2, employee row 2 lines.
// Desktop layout pehle jaisa.
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

    // ── Shared top-bar parts (desktop + mobile dono) ──
    const title = Column(
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
    );

    final monthNav = _MonthNav(
      month: state.month,
      onPrev: notifier.prevMonth,
      onNext: notifier.nextMonth,
    );

    // Refresh — naya employee/payment turant dikhe (restart nahi)
    final refreshBtn = Tooltip(
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
    );

    void openEmployees() => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const EmployeesScreen()))
        // Wapis aane par auto-reload — naya employee turant dikhe
        .then((_) => notifier.load());

    final employeesBtn = SizedBox(
      width: 160,
      // height: 100,
      child: OutlinedButton.icon(
        onPressed: openEmployees,
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
    );

    // Mobile: sirf icon (same outlined style) — label ki jagah nahi
    final employeesIconBtn = Tooltip(
      message: 'Employees',
      child: SizedBox(
        width: 44,
        height: 44,
        child: OutlinedButton(
          onPressed: openEmployees,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColor.primary,
            side: const BorderSide(color: AppColor.primary),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Icon(Icons.badge_outlined, size: 18),
        ),
      ),
    );

    final cards = [
      _StatCard(label: 'Paid', value: '${state.paidCount}/${state.totalEmployees}',
          icon: Icons.check_circle_outline_rounded, color: AppColor.success),
      _StatCard(label: 'Pending', value: '${state.pendingCount}',
          icon: Icons.schedule_rounded, color: AppColor.warningDark),
      _StatCard(label: 'Total Paid', value: 'Rs ${state.totalPaid.pkrFormat}',
          icon: Icons.payments_outlined, color: AppColor.primary),
      _StatCard(label: 'Remaining', value: 'Rs ${state.totalRemaining.pkrFormat}',
          icon: Icons.account_balance_wallet_outlined, color: AppColor.error),
    ];

    return Scaffold(
      backgroundColor: AppColor.background,
      body: LayoutBuilder(builder: (context, c) {
        // Mobile (< 700px): top bar 2 lines, cards 2×2, row 2 lines.
        // Desktop: bilkul pehle wala layout.
        final narrow = c.maxWidth < _kNarrowWidth;
        final hPad   = narrow ? 16.0 : 24.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top bar: title + month nav + manage employees ──
            Container(
              color: AppColor.surface,
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 14),
              child: narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          const Expanded(child: title),
                          const SizedBox(width: 8),
                          refreshBtn,
                          const SizedBox(width: 8),
                          employeesIconBtn,
                        ]),
                        const SizedBox(height: 10),
                        Center(child: monthNav),
                      ],
                    )
                  : Row(children: [
                      const Expanded(child: title),
                      const SizedBox(width: 12),
                      // Month navigator
                      monthNav,
                      const SizedBox(width: 8),
                      refreshBtn,
                      const SizedBox(width: 8),
                      employeesBtn,
                    ]),
            ),

            if (state.isLoading) const LinearProgressIndicator(minHeight: 2),

            // ── Summary cards ──
            Container(
              color: AppColor.surface,
              padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 16),
              child: narrow
                  ? Column(children: [
                      Row(children: [cards[0], const SizedBox(width: 12), cards[1]]),
                      const SizedBox(height: 12),
                      Row(children: [cards[2], const SizedBox(width: 12), cards[3]]),
                    ])
                  : Row(children: [
                      cards[0],
                      const SizedBox(width: 12),
                      cards[1],
                      const SizedBox(width: 12),
                      cards[2],
                      const SizedBox(width: 12),
                      cards[3],
                    ]),
            ),

            // ── Employee list ──
            Expanded(
              child: state.statuses.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.all(narrow ? 12 : 20),
                      itemCount: state.statuses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _EmployeeRow(
                        status: state.statuses[i],
                        compact: narrow,
                        onPay: () => PaySalaryDialog.show(context, state.statuses[i]),
                        onHistory: () => EmployeeHistoryDialog.show(
                            context, state.statuses[i].employee),
                        onDeletePayment: (p) => notifier.deletePayment(p),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

// Is se kam chaudai = mobile layout
const double _kNarrowWidth = 700;

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
  final bool compact; // mobile: 2 lines (overflow se bachao)

  const _EmployeeRow({
    required this.status,
    required this.onPay,
    required this.onHistory,
    required this.onDeletePayment,
    this.compact = false,
  });

  Color get _statusColor {
    switch (status.status) {
      case SalaryStatus.paid:    return AppColor.success;
      case SalaryStatus.partial: return AppColor.warningDark;
      case SalaryStatus.pending: return AppColor.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = status;

    // ── Parts (desktop + mobile dono mein same) ──
    final avatar = Container(
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
    );

    // Name + phone
    final nameCol = Column(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
      ],
    );

    // Paid / remaining
    Widget paidCol(CrossAxisAlignment align) => Column(
      crossAxisAlignment: align,
      children: [
        Text('Paid Rs ${s.totalPaid.pkrFormat}',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColor.textPrimary)),
        Text('Baaki Rs ${s.remaining.pkrFormat}',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor)),
      ],
    );

    // Status badge
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(s.statusLabel,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
    );

    // History hint — row tap se poora record khulta hai
    const historyIcon =
        Icon(Icons.history_rounded, size: 16, color: AppColor.grey400);

    // Pay button
    Widget payBtn(double width) => SizedBox(
      width: width,
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
    );

    // Desktop: ek line (pehle jaisa). Mobile: 2 lines.
    final header = compact
        ? Column(children: [
            Row(children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(child: nameCol),
              const SizedBox(width: 8),
              badge,
              const SizedBox(width: 8),
              historyIcon,
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: paidCol(CrossAxisAlignment.start)),
              const SizedBox(width: 8),
              payBtn(100),
            ]),
          ])
        : Row(children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(child: nameCol),
            paidCol(CrossAxisAlignment.end),
            const SizedBox(width: 12),
            badge,
            const SizedBox(width: 8),
            historyIcon,
            const SizedBox(width: 8),
            payBtn(120),
          ]);

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
        header,

        // This month ke payments
        if (s.payments.isNotEmpty) ...[
          const Divider(height: 18),
          ...s.payments.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Icon(p.isAdvance ? Icons.trending_down_rounded : Icons.payments_outlined,
                      size: 13, color: p.isAdvance ? AppColor.warningDark : AppColor.success),
                  const SizedBox(width: 6),
                  // Mobile: type + amount + notes ek Expanded text (ellipsis),
                  // date right par — tang jagah mein overflow nahi
                  if (compact) ...[
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${p.typeLabel} · Rs ${p.amount.pkrFormat}'),
                          if (p.notes != null && p.notes!.isNotEmpty)
                            TextSpan(text: ' · ${p.notes}',
                                style: const TextStyle(color: AppColor.textHint)),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ] else
                  Text('${p.typeLabel} · Rs ${p.amount.pkrFormat}',
                      style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                  if (!compact && p.notes != null && p.notes!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('· ${p.notes}',
                          style: const TextStyle(fontSize: 11, color: AppColor.textHint),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ] else if (!compact) const Spacer(),
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
                // scaleDown — mobile 2×2 mein amount kate nahi, chhota ho
                // jaye (desktop par jagah kaafi — koi farq nahi)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary)),
                ),
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
