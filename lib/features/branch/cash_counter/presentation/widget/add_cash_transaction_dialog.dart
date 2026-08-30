import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/cash_counter/presentation/provider/cash_counter_provider.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../provider/cash_transaction_provider.dart';

// Cash Count dialog — operator drawer ka physical cash count karke yahan
// "Counted Amount" likhta hai (jitna paisa drawer mein mila, poora amount —
// jaise 5000). System khud current net amount (jaise 4580) se difference
// (420) nikaal ke dikhata hai, aur "Add" par sirf wohi DIFFERENCE cash_in
// ke taur par submit hota hai — isse net amount, Cash In total, aur
// "Difference" screen (CounterCashTransactionScreen / accountant ka
// branch_cash_difference report — dono isi branch_cash_transaction table
// se aate hain) sab khud-ba-khud reconcile ho jate hain.
class AddCashTransactionDialog extends ConsumerStatefulWidget {
  const AddCashTransactionDialog({super.key});

  @override
  ConsumerState<AddCashTransactionDialog> createState() =>
      _AddCashTransactionDialogState();
}

class _AddCashTransactionDialogState
    extends ConsumerState<AddCashTransactionDialog> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();

  double get _countedAmount => double.tryParse(_amountCtrl.text) ?? 0.0;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(double difference, double systemTotal) async {
    if (!_formKey.currentState!.validate()) return;
    if (difference <= 0) return; // guarded by the disabled button too

    final userId = ref.read(authProvider).userId;
    final note   = _descCtrl.text.trim();

    final autoDescription =
        'Cash Count — counted Rs ${_countedAmount.toStringAsFixed(0)}'
        ' vs system Rs ${systemTotal.toStringAsFixed(0)}'
        '${note.isNotEmpty ? ' — $note' : ''}';

    await ref.read(cashTransactionProvider.notifier).addTransaction(
      amount:        difference,
      previousTotal: systemTotal,
      userId:        userId,
      description:   autoDescription,
    );

    final hasError = ref.read(cashTransactionProvider).errorMessage != null;
    if (!hasError && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(cashTransactionProvider);
    final isSaving = state.isSaving;

    // ✅ Watch cashCounterProvider — aaj ka correct system net amount
    final records = ref.watch(cashCounterProvider).allRecords;
    final today   = DateTime.now();
    final systemTotal = records
        .where((r) =>
    r.counterDate.year  == today.year  &&
        r.counterDate.month == today.month &&
        r.counterDate.day   == today.day)
        .firstOrNull
        ?.totalAmount ?? 0.0;

    final hasAmount   = _amountCtrl.text.trim().isNotEmpty;
    final difference  = _countedAmount - systemTotal;
    final canSubmit   = hasAmount && difference > 0 && !isSaving;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 460,
        child: SingleChildScrollView(
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
                        Icons.calculate_rounded,
                        color: AppColor.success,
                        size:  20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cash Count',
                            style: TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w700)),
                        Text('Drawer mein jitna cash mila, wo likhein',
                            style: TextStyle(
                                fontSize: 12,
                                color:    AppColor.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: isSaving
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

                // ── System Net Amount ─────────────────────
                const _Label('System Net Amount'),
                const SizedBox(height: 6),
                Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColor.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size:  18,
                        color: AppColor.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Rs ${systemTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize:   18,
                          fontWeight: FontWeight.w800,
                          color:      AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Counted Amount Field ───────────────────
                const _Label('Counted Amount (Rs) *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  cursorHeight: 14,
                  onChanged:    (_) => setState(() {}),
                  style: const TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.textPrimary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Counted amount required hai';
                    final p = double.tryParse(v);
                    if (p == null || p < 0) return 'Valid amount dalein';
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixText:  'Rs ',
                    prefixStyle: const TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.primary),
                    hintText:  'e.g. 5000',
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
                            color: AppColor.primary, width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColor.error)),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Difference Preview ────────────────────
                if (hasAmount) ...[
                  _DifferenceCard(difference: difference),
                  const SizedBox(height: 12),
                ],

                // ── Description ───────────────────────────
                const _Label('Note (Optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _descCtrl,
                  maxLines:     2,
                  cursorHeight: 14,
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  decoration: InputDecoration(
                    hintText:  'e.g. Closing count, shift end...',
                    hintStyle: const TextStyle(
                        color: AppColor.textHint, fontSize: 13),
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
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
                            color: AppColor.primary, width: 1.5)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Submit Button ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canSubmit
                        ? () => _submit(difference, systemTotal)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColor.grey200,
                      disabledForegroundColor: AppColor.textHint,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: isSaving
                        ? const SizedBox(
                        width:  16,
                        height: 16,
                        child:  CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.arrow_downward_rounded, size: 18),
                    label: Text(
                      !hasAmount
                          ? 'Enter counted amount'
                          : difference > 0
                          ? 'Add Rs ${difference.toStringAsFixed(0)} to Cash In'
                          : difference == 0
                          ? 'Already balanced'
                          : 'No shortfall entry — count only',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
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

// ── Difference Preview Card ─────────────────────────────────────
class _DifferenceCard extends StatelessWidget {
  final double difference;
  const _DifferenceCard({required this.difference});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;
    final String value;

    if (difference > 0) {
      color = AppColor.success;
      icon  = Icons.trending_up_rounded;
      label = 'Difference — will be added to Cash In';
      value = '+ Rs ${difference.toStringAsFixed(0)}';
    } else if (difference < 0) {
      color = AppColor.error;
      icon  = Icons.trending_down_rounded;
      label = 'Shortage — kam mila hai, cash out abhi enable nahi';
      value = '- Rs ${difference.abs().toStringAsFixed(0)}';
    } else {
      color = AppColor.textSecondary;
      icon  = Icons.check_circle_outline_rounded;
      label = 'Balanced — koi difference nahi';
      value = 'Rs 0';
    }

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize:   11,
                        color:      color,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.w800,
                        color:      color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize:      12,
          fontWeight:    FontWeight.w600,
          color:         AppColor.textSecondary,
          letterSpacing: 0.5));
}
