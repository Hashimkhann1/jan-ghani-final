import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/cash_counter/presentation/provider/cash_counter_provider.dart';
import '../provider/cash_transaction_provider.dart';

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

  double get _enteredAmount =>
      double.tryParse(_amountCtrl.text) ?? 0.0;

  // ✅ cashCounterProvider se aaj ka correct total
  double _getTodayTotal() {
    final records = ref.read(cashCounterProvider).allRecords;
    final today   = DateTime.now();
    return records
        .where((r) =>
    r.counterDate.year  == today.year  &&
        r.counterDate.month == today.month &&
        r.counterDate.day   == today.day)
        .firstOrNull
        ?.totalAmount ?? 0.0;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String type) async {
    if (!_formKey.currentState!.validate()) return;

    final previousTotal = _getTodayTotal(); // ← correct total

    await ref.read(cashTransactionProvider.notifier).addTransaction(
      amount:          _enteredAmount,
      transactionType: type,
      previousTotal:   previousTotal,
      description:     _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
    );

    final hasError =
        ref.read(cashTransactionProvider).errorMessage != null;
    if (!hasError && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(cashTransactionProvider);
    final isSaving = state.isSaving;

    // ✅ Watch cashCounterProvider — aaj ka correct total
    final records    = ref.watch(cashCounterProvider).allRecords;
    final today      = DateTime.now();
    final todayTotal = records
        .where((r) =>
    r.counterDate.year  == today.year  &&
        r.counterDate.month == today.month &&
        r.counterDate.day   == today.day)
        .firstOrNull
        ?.totalAmount ?? 0.0;

    final cashInRemaining  = todayTotal + _enteredAmount;
    final cashOutRemaining = todayTotal - _enteredAmount;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
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
                        color:        AppColor.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: AppColor.primary,
                        size:  20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cash Transaction',
                            style: TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w700)),
                        Text('Cash in ya out record karein',
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

                // ── Current Total ─────────────────────────
                const _Label('Current Total Amount'),
                const SizedBox(height: 6),
                Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: todayTotal >= 0
                        ? AppColor.success.withValues(alpha: 0.06)
                        : AppColor.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: todayTotal >= 0
                          ? AppColor.success.withValues(alpha: 0.3)
                          : AppColor.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size:  18,
                        color: todayTotal >= 0
                            ? AppColor.success
                            : AppColor.error,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Rs ${todayTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize:   18,
                          fontWeight: FontWeight.w800,
                          color: todayTotal >= 0
                              ? AppColor.success
                              : AppColor.error,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Amount Field ──────────────────────────
                const _Label('Amount *'),
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
                      return 'Amount required hai';
                    final p = double.tryParse(v);
                    if (p == null || p <= 0)
                      return 'Valid amount dalein';
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixText:  'Rs ',
                    prefixStyle: const TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.primary),
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
                            color: AppColor.primary, width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        const BorderSide(color: AppColor.error)),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Preview Cards ─────────────────────────
                if (_amountCtrl.text.isNotEmpty &&
                    _enteredAmount > 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _PreviewCard(
                          label: 'After Cash In',
                          value: 'Rs ${cashInRemaining.toStringAsFixed(0)}',
                          color: AppColor.success,
                          icon:  Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PreviewCard(
                          label: 'After Cash Out',
                          value: 'Rs ${cashOutRemaining.toStringAsFixed(0)}',
                          color: AppColor.error,
                          icon:  Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Description ───────────────────────────
                const _Label('Description (Optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _descCtrl,
                  maxLines:     2,
                  cursorHeight: 14,
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  decoration: InputDecoration(
                    hintText:  'e.g. Owner ne nikale, Cash aaya...',
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

                // ── Cash In / Cash Out Buttons ────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () => _submit('cash_in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.success,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          AppColor.success.withValues(alpha: 0.5),
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
                                strokeWidth: 2,
                                color:       Colors.white))
                            : const Icon(Icons.arrow_downward_rounded,
                            size: 18),
                        label: const Text('Cash In',
                            style: TextStyle(
                                fontSize:   14,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () => _submit('cash_out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.error,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          AppColor.error.withValues(alpha: 0.5),
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
                                strokeWidth: 2,
                                color:       Colors.white))
                            : const Icon(Icons.arrow_upward_rounded,
                            size: 18),
                        label: const Text('Cash Out',
                            style: TextStyle(
                                fontSize:   14,
                                fontWeight: FontWeight.w700)),
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

// ── Preview Card ──────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;
  const _PreviewCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize:   10,
                      color:      color,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      color)),
            ],
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