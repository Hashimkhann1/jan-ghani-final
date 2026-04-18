import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/cash_counter/presentation/provider/cash_counter_provider.dart';

class AddCashRegistrationDialog extends ConsumerStatefulWidget {
  const AddCashRegistrationDialog({super.key});

  @override
  ConsumerState<AddCashRegistrationDialog> createState() =>
      _AddCashRegistrationDialogState();
}

class _AddCashRegistrationDialogState
    extends ConsumerState<AddCashRegistrationDialog> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  bool  _isSaving   = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
      print('💰 Saving amount: $amount');

      await ref
          .read(cashCounterProvider.notifier)
          .registerOpeningAmount(amount);

      final hasError =
          ref.read(cashCounterProvider).errorMessage != null;

      if (!hasError && mounted) Navigator.of(context).pop();
    } catch (e) {
      print('❌ Dialog save error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    // ✅ Error snackbar
    ref.listen<CashCounterState>(cashCounterProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ───────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:        AppColor.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColor.success,
                        size:  20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cash Registration',
                            style: TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w700)),
                        Text('Aaj ka opening amount dalein',
                            style: TextStyle(
                                fontSize: 12,
                                color:    AppColor.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon:  const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                          foregroundColor: AppColor.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: AppColor.grey200),
                const SizedBox(height: 16),

                // ── Info Banner ───────────────────────────
                Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:        AppColor.info.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColor.info.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 15, color: AppColor.info),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kal ka bacha hua ya aaj ka opening cash amount dalein',
                          style: TextStyle(
                              fontSize: 11, color: AppColor.info),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Amount Field ──────────────────────────
                const Text('Opening Amount (Rs)',
                    style: TextStyle(
                        fontSize:      12,
                        fontWeight:    FontWeight.w600,
                        color:         AppColor.textSecondary,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                TextFormField(
                  controller:      _amountCtrl,
                  keyboardType:    const TextInputType.numberWithOptions(
                      decimal: true),
                  cursorHeight:    14,
                  autofocus:       true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  style: const TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w700,
                      color:      AppColor.textPrimary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Amount required hai';
                    if (double.tryParse(v.trim()) == null)
                      return 'Valid amount dalein';
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixText:  'Rs ',
                    prefixStyle: const TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.success),
                    hintText:  '0',
                    hintStyle: const TextStyle(
                        color: AppColor.textHint, fontSize: 14),
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColor.grey200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColor.grey200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColor.success, width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColor.error)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Save Button ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      AppColor.success.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                        width:  20,
                        height: 20,
                        child:  CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       Colors.white))
                        : const Text('Register Opening Amount',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize:   15)),
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