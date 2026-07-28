// =============================================================
// employee_history_dialog.dart
// Employee par tap → uska POORA salary/advance record (sab months).
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import '../../data/employee_repository.dart';
import '../../domain/employee_model.dart';
import '../../domain/salary_payment_model.dart';

class EmployeeHistoryDialog extends StatefulWidget {
  final EmployeeModel employee;
  const EmployeeHistoryDialog({super.key, required this.employee});

  static void show(BuildContext context, EmployeeModel employee) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => EmployeeHistoryDialog(employee: employee),
    );
  }

  @override
  State<EmployeeHistoryDialog> createState() => _EmployeeHistoryDialogState();
}

class _EmployeeHistoryDialogState extends State<EmployeeHistoryDialog> {
  List<SalaryPaymentModel>? _payments;
  String? _error;

  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await EmployeeRepository.instance
          .getPaymentsForEmployee(widget.employee.id);
      if (mounted) setState(() => _payments = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.employee;
    final p = _payments;

    // Month-wise groups (naya month upar)
    final groups = <DateTime, List<SalaryPaymentModel>>{};
    if (p != null) {
      for (final pay in p) {
        final key = DateTime(pay.salaryMonth.year, pay.salaryMonth.month, 1);
        groups.putIfAbsent(key, () => []).add(pay);
      }
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    final totalPaid    = p?.fold<double>(0, (s, x) => s + x.amount) ?? 0;
    final salaryTotal  = p?.where((x) => !x.isAdvance)
            .fold<double>(0, (s, x) => s + x.amount) ?? 0;
    final advanceTotal = p?.where((x) => x.isAdvance)
            .fold<double>(0, (s, x) => s + x.amount) ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 12, 0),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                      e.name.isEmpty ? '?' : e.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.name} — Salary Record',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      Text('Monthly salary: Rs ${e.monthlySalary.pkrFormat}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColor.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                      foregroundColor: AppColor.textSecondary),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Totals ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  _totCol('Total Paid', totalPaid, AppColor.textPrimary),
                  _vDiv(),
                  _totCol('Salary', salaryTotal, AppColor.success),
                  _vDiv(),
                  _totCol('Advance', advanceTotal, AppColor.warning),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // ── Body ──
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(22),
                child: Text('Load masla: $_error',
                    style: const TextStyle(
                        color: AppColor.error, fontSize: 12)),
              )
            else if (p == null)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (p.isEmpty)
              const Padding(
                padding: EdgeInsets.all(26),
                child: Center(
                  child: Text('Abhi tak koi payment nahi',
                      style: TextStyle(
                          fontSize: 13, color: AppColor.textHint)),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                  itemCount: keys.length,
                  itemBuilder: (_, i) {
                    final month    = keys[i];
                    final list     = groups[month]!;
                    final monthSum =
                        list.fold<double>(0, (s, x) => s + x.amount);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month header
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 6),
                          child: Row(children: [
                            Text(
                                '${_months[month.month - 1]} ${month.year}',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.textPrimary)),
                            const Spacer(),
                            Text('Rs ${monthSum.pkrFormat}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.primary)),
                          ]),
                        ),
                        // Payments of that month
                        ...list.map((pay) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColor.surface,
                                borderRadius: BorderRadius.circular(9),
                                border:
                                    Border.all(color: AppColor.grey200),
                              ),
                              child: Row(children: [
                                Icon(
                                    pay.isAdvance
                                        ? Icons.trending_down_rounded
                                        : Icons.payments_outlined,
                                    size: 15,
                                    color: pay.isAdvance
                                        ? AppColor.warning
                                        : AppColor.success),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (pay.isAdvance
                                            ? AppColor.warning
                                            : AppColor.success)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(pay.typeLabel,
                                      style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: pay.isAdvance
                                              ? AppColor.warning
                                              : AppColor.success)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      pay.notes?.isNotEmpty == true
                                          ? pay.notes!
                                          : '—',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColor.textSecondary),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text('Rs ${pay.amount.pkrFormat}',
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColor.textPrimary)),
                                    Text(
                                        DateFormat('dd MMM yyyy · hh:mm a')
                                            .format(pay.createdAt.toLocal()),
                                        style: const TextStyle(
                                            fontSize: 9.5,
                                            color: AppColor.textHint)),
                                  ],
                                ),
                              ]),
                            )),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _totCol(String label, double value, Color color) => Expanded(
        child: Column(children: [
          Text('Rs ${value.pkrFormat}',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColor.textSecondary)),
        ]),
      );

  Widget _vDiv() => Container(
        width: 1, height: 28, color: AppColor.grey300,
        margin: const EdgeInsets.symmetric(horizontal: 10),
      );
}
