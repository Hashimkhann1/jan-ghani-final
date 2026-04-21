import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../data/model/accountant_user_model.dart';
import '../provider/accountant_transaction_provider.dart';

class CashOutDialog extends ConsumerStatefulWidget {
  final String branchId;
  const CashOutDialog({super.key, required this.branchId});

  @override
  ConsumerState<CashOutDialog> createState() => _CashOutDialogState();
}

class _CashOutDialogState extends ConsumerState<CashOutDialog> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();

  AccountantUserModel? _selected;
  bool _isSaving = false;

  double get _enteredAmount => double.tryParse(_amountCtrl.text.trim()) ?? 0.0;

  double get _branchBalance => ref.read(branchTotalAmountProvider(widget.branchId)).asData?.value ?? 0.0;

  double get _remaining => _branchBalance - _enteredAmount;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(accountantTransactionProvider(widget.branchId).notifier)
          .doCashOut(
        accountantId: _selected!.id,
        accountantName: _selected!.name,
        branchCurrentBalance: _branchBalance,
        amount: _enteredAmount,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      );

      // refresh branch balance
      ref.invalidate(branchTotalAmountProvider(widget.branchId));

      if (!mounted) return;

      // dialog close
      Navigator.of(context).pop();

      // show snackbar on parent scaffold
      ScaffoldMessenger.of(
        Navigator.of(context, rootNavigator: true).context,
      ).showSnackBar(
        const SnackBar(
          content: Text('Cash out successfully recorded'),
          backgroundColor: AppColor.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColor.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountantsAsync = ref.watch(accountantsProvider);
    final branchAmountAsync = ref.watch(branchTotalAmountProvider(widget.branchId));

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding:    const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:        AppColor.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded,
                          color: AppColor.error, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cash Out',
                            style: TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w700)),
                        Text('Accountant ko amount transfer karein',
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

                // ── Accountant Dropdown (sirf naam) ──────────────────────
                const _Label('Accountant *'),
                const SizedBox(height: 6),
                accountantsAsync.when(
                  loading: () => Container(
                    height:     52,
                    decoration: BoxDecoration(
                      color:        AppColor.grey100,
                      borderRadius: BorderRadius.circular(8),
                      border:       Border.all(color: AppColor.grey200),
                    ),
                    child: const Center(
                      child: SizedBox(
                          width:  18,
                          height: 18,
                          child:  CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                  error: (e, _) => Text('Load error: $e',
                      style: const TextStyle(color: AppColor.error)),
                  data: (accountants) =>
                      AppSearchableDropdown<AccountantUserModel>(
                        fullWidth:  true,
                        value:      _selected,
                        hint:       'Select accountant',
                        prefixIcon: Icons.person_outline_rounded,
                        items: accountants
                            .map((acc) => DropdownItem<AccountantUserModel>(
                          value: acc,
                          label: acc.name, // ✅ sirf naam
                          icon:  Icons.account_circle_outlined,
                        ))
                            .toList(),
                        onChanged: (v) => setState(() => _selected = v),
                        validator: (v) =>
                        v == null ? 'Accountant select karein' : null,
                      ),
                ),

                const SizedBox(height: 16),

                // ── Current Balance = Branch ka total_amount ─────────────
                branchAmountAsync.when(
                  loading: () => const _ReadOnlyAmountField(
                    label: 'Current Balance (Branch)',
                    value: 'Loading...',
                    color: AppColor.textHint,
                    icon:  Icons.account_balance_wallet_outlined,
                  ),
                  error: (e, _) => _ReadOnlyAmountField(
                    label: 'Current Balance (Branch)',
                    value: 'Error: $e',
                    color: AppColor.error,
                    icon:  Icons.error_outline,
                  ),
                  data: (branchAmount) => _ReadOnlyAmountField(
                    label: 'Current Balance (Branch)',
                    value: 'Rs ${branchAmount.toStringAsFixed(0)}',
                    color: branchAmount > 0
                        ? AppColor.success
                        : AppColor.textHint,
                    icon:  Icons.account_balance_wallet_outlined,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Cash Out Amount ──────────────────────────────────────
                const _Label('Cash Out Amount *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _amountCtrl,
                  onChanged:    (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  cursorHeight: 14,
                  style: const TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.textPrimary),
                  decoration: InputDecoration(
                    prefixText:  'Rs ',
                    prefixStyle: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.error),
                    hintText:  '0',
                    hintStyle: const TextStyle(
                        color: AppColor.textHint, fontSize: 13),
                    filled:    true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColor.error.withOpacity(0.4))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColor.error.withOpacity(0.4))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.error, width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.error)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Amount required hai';
                    final p = double.tryParse(v.trim());
                    if (p == null || p <= 0) return 'Valid amount dalein';
                    if (p > _branchBalance) {
                      return 'Branch balance se zyada nahi '
                          '(Max: Rs ${_branchBalance.toStringAsFixed(0)})';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Remaining After Cash Out ─────────────────────────────
                _ReadOnlyAmountField(
                  label: 'Remaining After Cash Out',
                  value: _amountCtrl.text.isEmpty
                      ? '—'
                      : 'Rs ${_remaining.toStringAsFixed(0)}',
                  color: _remaining < 0
                      ? AppColor.error
                      : _remaining == 0
                      ? AppColor.success
                      : AppColor.warning,
                  icon:     Icons.calculate_outlined,
                  subtitle: _remaining < 0 ? 'Insufficient' : null,
                ),

                const SizedBox(height: 16),

                // ── Description ──────────────────────────────────────────
                const _Label('Description (Optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _descCtrl,
                  maxLines:     2,
                  cursorHeight: 14,
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  decoration: InputDecoration(
                    hintText:  'e.g. Owner request, salary payment...',
                    hintStyle: const TextStyle(
                        color: AppColor.textHint, fontSize: 13),
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.grey200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.grey200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColor.primary, width: 1.5)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Submit Button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      AppColor.error.withOpacity(0.6),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                        width:  18,
                        height: 18,
                        child:  CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       Colors.white))
                        : const Icon(Icons.arrow_upward_rounded,
                        size: 18),
                    label: Text(
                      _isSaving ? 'Processing...' : 'Confirm Cash Out',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
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

// ─────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────

class _ReadOnlyAmountField extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;
  final String?  subtitle;

  const _ReadOnlyAmountField({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        Container(
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w700,
                          color:      color)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style:
                        TextStyle(fontSize: 10, color: color)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize:      12,
        fontWeight:    FontWeight.w600,
        color:         AppColor.textSecondary,
        letterSpacing: 0.5),
  );
}