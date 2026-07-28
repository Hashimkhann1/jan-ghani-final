// =============================================================
// add_employee_dialog.dart — Add + Edit employee
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:uuid/uuid.dart';
import '../../domain/employee_model.dart';
import '../provider/employee_provider.dart';

class AddEmployeeDialog extends ConsumerStatefulWidget {
  final EmployeeModel? employee; // null = add

  const AddEmployeeDialog({super.key, this.employee});

  static void show(BuildContext context, {EmployeeModel? employee}) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => AddEmployeeDialog(employee: employee),
    );
  }

  @override
  ConsumerState<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends ConsumerState<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name    = TextEditingController();
  final _phone   = TextEditingController();
  final _address = TextEditingController();
  final _salary  = TextEditingController();
  final _advPct  = TextEditingController();

  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    if (e != null) {
      _name.text    = e.name;
      _phone.text   = e.phone ?? '';
      _address.text = e.address ?? '';
      _salary.text  = e.monthlySalary == 0 ? '' : _fmt(e.monthlySalary);
      _advPct.text  = e.maxAdvancePercent == 0 ? '' : _fmt(e.maxAdvancePercent);
      _isActive     = e.isActive;
    }
  }

  String _fmt(double d) =>
      d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toString();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _salary.dispose();
    _advPct.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(employeeProvider.notifier);
    final salary   = double.tryParse(_salary.text.trim()) ?? 0;
    final advPct   = double.tryParse(_advPct.text.trim()) ?? 0;

    try {
      if (_isEdit) {
        await notifier.updateEmployee(widget.employee!.copyWith(
          name:              _name.text.trim(),
          phone:             _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          address:           _address.text.trim().isEmpty ? null : _address.text.trim(),
          monthlySalary:     salary,
          maxAdvancePercent: advPct,
          isActive:          _isActive,
        ));
      } else {
        await notifier.addEmployee(EmployeeModel(
          id:                const Uuid().v4(),
          warehouseId:       AppConfig.warehouseId,
          name:              _name.text.trim(),
          phone:             _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          address:           _address.text.trim().isEmpty ? null : _address.text.trim(),
          monthlySalary:     salary,
          maxAdvancePercent: advPct,
          isActive:          _isActive,
          createdAt:         DateTime.now(),
          updatedAt:         DateTime.now(),
        ));
      }
      final hasError = ref.read(employeeProvider).errorMessage != null;
      if (!hasError && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                          _isEdit ? Icons.edit_outlined : Icons.badge_outlined,
                          color: AppColor.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(_isEdit ? 'Edit Employee' : 'New Employee',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary)),
                    const Spacer(),
                    IconButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColor.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppColor.grey200),
                const SizedBox(height: 14),

                _label('Name *'),
                _field(_name, hint: 'Employee ka naam',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name required' : null),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Phone'),
                      _field(_phone, hint: '03xx...',
                          keyboard: TextInputType.phone),
                    ],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Monthly Salary *'),
                      _field(_salary, hint: '0', prefix: 'Rs ',
                          keyboard: const TextInputType.numberWithOptions(decimal: true),
                          formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          validator: (v) {
                            final d = double.tryParse(v?.trim() ?? '');
                            if (d == null || d <= 0) return 'Salary daalein';
                            return null;
                          }),
                    ],
                  )),
                ]),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Max Advance %'),
                      _field(_advPct, hint: 'e.g. 30', suffix: '%',
                          keyboard: const TextInputType.numberWithOptions(decimal: true),
                          formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]),
                    ],
                  )),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ]),
                const SizedBox(height: 12),

                _label('Address'),
                _field(_address, hint: 'Address (optional)', maxLines: 2),
                const SizedBox(height: 14),

                // Active toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.grey100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColor.grey200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.toggle_on_outlined,
                        size: 18, color: AppColor.textSecondary),
                    const SizedBox(width: 8),
                    const Text('Active',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textPrimary)),
                    const Spacer(),
                    Switch(
                        value: _isActive,
                        activeColor: AppColor.primary,
                        onChanged: (v) => setState(() => _isActive = v)),
                  ]),
                ),
                const SizedBox(height: 20),

                Consumer(builder: (context, ref, _) {
                  final err = ref.watch(
                      employeeProvider.select((s) => s.errorMessage));
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(err,
                        style: const TextStyle(color: AppColor.error, fontSize: 12)),
                  );
                }),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Save Changes' : 'Save Employee',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColor.textPrimary)),
      );

  Widget _field(TextEditingController c,
      {required String hint,
      String? prefix,
      String? suffix,
      int maxLines = 1,
      TextInputType? keyboard,
      List<TextInputFormatter>? formatters,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: formatters,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColor.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        suffixText: suffix,
        hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColor.error)),
      ),
    );
  }
}
