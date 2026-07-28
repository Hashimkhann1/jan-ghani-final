// =============================================================
// pay_salary_dialog.dart — salary ya advance pay karo
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/auth/local/auth_local_storage.dart';
import '../../domain/employee_month_status.dart';
import '../../domain/salary_payment_model.dart';
import '../provider/salary_provider.dart';

class PaySalaryDialog extends ConsumerStatefulWidget {
  final EmployeeMonthStatus status;
  const PaySalaryDialog({super.key, required this.status});

  static void show(BuildContext context, EmployeeMonthStatus status) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => PaySalaryDialog(status: status),
    );
  }

  @override
  ConsumerState<PaySalaryDialog> createState() => _PaySalaryDialogState();
}

class _PaySalaryDialogState extends ConsumerState<PaySalaryDialog> {
  late final SalaryPaymentType _type;
  final _amount = TextEditingController();
  final _notes  = TextEditingController();
  bool _isSaving = false;
  String? _error;

  EmployeeMonthStatus get s => widget.status;

  @override
  void initState() {
    super.initState();
    // AUTO type: selected month FUTURE hai → Advance, warna (current/past) → Salary.
    // (Current month = Salary, taake month-end par poori salary advance-cap
    //  par block na ho. Future month ka paisa = advance, cap ke saath.)
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    _type = s.month.isAfter(currentMonth)
        ? SalaryPaymentType.advance
        : SalaryPaymentType.salary;

    // Default amount type ke hisaab se
    if (_type == SalaryPaymentType.advance) {
      _amount.text =
          s.advanceRemaining > 0 ? s.advanceRemaining.toStringAsFixed(0) : '';
    } else {
      _amount.text = s.remaining > 0 ? s.remaining.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Amount 0 se zyada daalein');
      return;
    }
    // Advance cap validation
    if (_type == SalaryPaymentType.advance && amount > s.advanceRemaining + 0.001) {
      setState(() => _error =
          'Max advance Rs ${s.advanceRemaining.pkrFormat} tak (${s.employee.maxAdvancePercent.toStringAsFixed(0)}%)');
      return;
    }
    // Salary/total cap — monthly salary se zyada na jaye
    if (amount > s.remaining + 0.001) {
      setState(() => _error =
          'Sirf Rs ${s.remaining.pkrFormat} baaki hai (monthly salary se zyada nahi)');
      return;
    }

    setState(() { _isSaving = true; _error = null; });

    final user = await AuthLocalStorage.loadUser();
    final err = await ref.read(salaryProvider.notifier).pay(
      employee:   s.employee,
      type:       _type,
      amount:     amount,
      notes:      _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      paidBy:     user?['id']?.toString(),
      paidByName: user?['full_name']?.toString(),
    );

    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() { _isSaving = false; _error = err; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdvance = _type == SalaryPaymentType.advance;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payments_outlined,
                      color: AppColor.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pay — ${s.employee.name}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      Text('Monthly salary: Rs ${s.monthlySalary.pkrFormat}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColor.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                      foregroundColor: AppColor.textSecondary),
                ),
              ]),
              const SizedBox(height: 14),

              // Status summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColor.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  _sumRow('Advance liya', 'Rs ${s.advancePaid.pkrFormat}'),
                  const SizedBox(height: 6),
                  _sumRow('Salary di', 'Rs ${s.salaryPaid.pkrFormat}'),
                  const Divider(height: 16),
                  _sumRow('Baaki (remaining)', 'Rs ${s.remaining.pkrFormat}',
                      strong: true, color: AppColor.error),
                ]),
              ),
              const SizedBox(height: 16),

              // AUTO type badge (user select nahi karta — month se khud decide)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (isAdvance ? AppColor.warning : AppColor.success)
                      .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: (isAdvance ? AppColor.warning : AppColor.success)
                          .withOpacity(0.35)),
                ),
                child: Row(children: [
                  Icon(
                      isAdvance
                          ? Icons.trending_down_rounded
                          : Icons.payments_outlined,
                      size: 16,
                      color: isAdvance ? AppColor.warning : AppColor.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAdvance
                          ? 'ADVANCE — yeh month abhi aaya nahi, isliye yeh '
                              'advance count hoga (salary se auto-adjust)'
                          : 'SALARY — is month ki salary payment',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color:
                              isAdvance ? AppColor.warning : AppColor.success),
                    ),
                  ),
                ]),
              ),
              if (isAdvance) ...[
                const SizedBox(height: 8),
                Text(
                  'Max advance: Rs ${s.employee.maxAdvanceAmount.pkrFormat} '
                  '(${s.employee.maxAdvancePercent.toStringAsFixed(0)}%) · '
                  'baaki Rs ${s.advanceRemaining.pkrFormat}',
                  style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
                ),
              ],
              const SizedBox(height: 14),

              const Text('Amount *',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary),
                decoration: _dec('0', prefix: 'Rs '),
              ),
              const SizedBox(height: 12),

              const Text('Notes (optional)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _notes,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
                decoration: _dec('Extra details...'),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColor.error, fontSize: 12)),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _pay,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(
                      isAdvance ? 'Pay Advance' : 'Pay Salary',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: AppColor.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sumRow(String label, String value,
      {bool strong = false, Color? color}) {
    return Row(children: [
      Text(label,
          style: TextStyle(
              fontSize: 12,
              color: AppColor.textSecondary,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w400)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              fontSize: strong ? 14 : 12,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              color: color ?? AppColor.textPrimary)),
    ]);
  }

  InputDecoration _dec(String hint, {String? prefix}) => InputDecoration(
        hintText: hint,
        prefixText: prefix,
        hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: AppColor.grey100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColor.grey200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColor.grey200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
      );
}
