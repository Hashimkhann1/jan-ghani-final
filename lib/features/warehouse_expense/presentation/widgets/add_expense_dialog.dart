// =============================================================
// add_expense_dialog.dart
// Location: features/warehouse_expense/presentation/widgets/
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/auth/local/auth_local_storage.dart';
import 'package:jan_ghani_final/features/warehouse_expense/domain/warehouse_expense_model.dart';

class AddExpenseDialog extends StatefulWidget {
  final void Function({
  required String expenseHead,
  required double amount,
  String?         description,
  String?         userId,
  String?         userName,
  }) onConfirm;

  const AddExpenseDialog({super.key, required this.onConfirm});

  static void show(BuildContext context, {
    required void Function({
    required String expenseHead,
    required double amount,
    String?         description,
    String?         userId,
    String?         userName,
    }) onConfirm,
  }) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => AddExpenseDialog(onConfirm: onConfirm),
    );
  }

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _headCtrl    = TextEditingController();
  final _amountCtrl  = TextEditingController();
  final _notesCtrl   = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  bool  _isSaving    = false;

  @override
  void dispose() {
    _headCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _selectChip(String label) {
    setState(() => _headCtrl.text = label);
    _headCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _headCtrl.text.length),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final userMap  = await AuthLocalStorage.loadUser();
    final userId   = userMap?['id']?.toString();
    final userName = userMap?['full_name']?.toString();

    if (!mounted) return;

    widget.onConfirm(
      expenseHead: _headCtrl.text.trim(),
      amount:      double.parse(_amountCtrl.text.trim()),
      description: _notesCtrl.text.trim().isEmpty
          ? null : _notesCtrl.text.trim(),
      userId:      userId,
      userName:    userName,
    );

    Navigator.pop(context);
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText:  hint,
    hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 13),
    filled:    true,
    fillColor: AppColor.grey100,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColor.border)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColor.border)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
            color: AppColor.borderFocused, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColor.error)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColor.error, width: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_outlined,
                          color: AppColor.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('New Expense',
                            style: TextStyle(
                              fontSize:   17,
                              fontWeight: FontWeight.w700,
                              color:      AppColor.textPrimary,
                            )),
                        Text('Expense ki details bharein',
                            style: TextStyle(
                                fontSize: 11,
                                color:    AppColor.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    InkWell(
                      onTap:        () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color:        AppColor.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColor.textSecondary),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Expense Head ─────────────────────────────
                const Text('Expense Head *',
                    style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w500,
                        color:      AppColor.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _headCtrl,
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  decoration: _deco('e.g. Rent, Salary...'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Expense head zaroori hai'
                      : null,
                ),

                // ── Quick Select chips ────────────────────────
                const SizedBox(height: 12),
                const Text('Quick Select',
                    style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w500,
                        color:      AppColor.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing:   8,
                  runSpacing: 8,
                  children: kExpenseQuickSelect.map((label) {
                    final isSelected =
                        _headCtrl.text.trim().toLowerCase() ==
                            label.toLowerCase();
                    return GestureDetector(
                      onTap: () => _selectChip(label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColor.primary
                              : AppColor.grey100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColor.primary
                                : AppColor.grey300,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColor.white
                                : AppColor.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // ── Amount ───────────────────────────────────
                const Text('Amount (Rs) *',
                    style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w500,
                        color:      AppColor.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller:   _amountCtrl,
                  keyboardType: const TextInputType
                      .numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary),
                  decoration: _deco('0').copyWith(
                    prefixText:  'Rs ',
                    prefixStyle: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Amount zaroori hai';
                    final d = double.tryParse(v.trim());
                    if (d == null) return 'Sahi number daalo';
                    if (d <= 0)   return 'Amount zero se zyada hona chahiye';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ── Description ──────────────────────────────
                const Text('Description (Optional)',
                    style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w500,
                        color:      AppColor.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines:   3,
                  style: const TextStyle(
                      fontSize: 13, color: AppColor.textPrimary),
                  decoration: _deco('Extra details...'),
                ),

                const SizedBox(height: 28),

                // ── Save Button ───────────────────────────────
                SizedBox(
                  width:  double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColor.white))
                        : const Text('Save Expense',
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}