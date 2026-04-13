// =============================================================
// cash_in_dialog.dart
// Widget: Cash In Dialog
// Location: features/warehouse_finance/presentation/widgets/
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/auth/local/auth_local_storage.dart';

class CashInDialog extends StatefulWidget {
  final void Function({required double amount, String? notes, String? userId,String? userName}) onConfirm;

  const CashInDialog({super.key, required this.onConfirm});

  @override
  State<CashInDialog> createState() => _CashInDialogState();
}

class _CashInDialogState extends State<CashInDialog> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userMap  = await AuthLocalStorage.loadUser();
    final userId   = userMap?['id']?.toString();
    final userName = userMap?['full_name']?.toString();

    if (!mounted) return;  // ← yeh add karo

    widget.onConfirm(
      amount:   double.parse(_amountCtrl.text.trim()),
      notes:    _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      userId:   userId,
      userName: userName,
    );
    Navigator.pop(context);
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText:  hint,
      hintStyle: const TextStyle(color: AppColor.textHint),
      filled:    true,
      fillColor: AppColor.grey100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColor.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColor.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
            color: AppColor.borderFocused, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColor.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColor.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cash In Karo',
                      style: TextStyle(
                        fontSize:   18,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColor.textSecondary, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Amount
                const Text(
                  'Amount *',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color:      AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller:   _amountCtrl,
                  keyboardType: const TextInputType
                      .numberWithOptions(decimal: true),
                  style: const TextStyle(
                      fontSize: 15, color: AppColor.textPrimary),
                  decoration: _inputDeco('0.00').copyWith(
                    prefixText:  'Rs. ',
                    prefixStyle: const TextStyle(
                        color:      AppColor.primary,
                        fontWeight: FontWeight.w600),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Amount zaroori hai';
                    if (double.tryParse(v) == null)
                      return 'Sahi number daalo';
                    if (double.parse(v) <= 0)
                      return 'Zero se zyada hona chahiye';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Notes (optional)',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color:      AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines:   3,
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  decoration: _inputDeco(
                      'Jaise: Opening cash, Investment...'),
                ),
                const SizedBox(height: 28),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColor.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color:      AppColor.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: AppColor.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Add Karo',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}