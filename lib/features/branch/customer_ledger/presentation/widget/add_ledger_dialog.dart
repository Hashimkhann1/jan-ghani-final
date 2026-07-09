import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/branch/customer/data/model/customer_model.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/provider/customer_provider.dart';
import 'package:jan_ghani_final/features/branch/customer_ledger/presentation/provider/customer_ledger_provider.dart';

import '../../../../../core/service/print/customer_ledger_print_service.dart';
import '../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../branch_info/presentation/provider/branch_provider.dart';
import '../../../counter/presentation/provider/counter_provider.dart';
import '../../data/model/customer_ledger_model.dart';

class AddLedgerDialog extends ConsumerStatefulWidget {
  const AddLedgerDialog({super.key, this.ledger});
  final CustomerLedgerModel? ledger;

  @override
  ConsumerState<AddLedgerDialog> createState() => _AddLedgerDialogState();
}

class _AddLedgerDialogState extends ConsumerState<AddLedgerDialog> {
  final _formKey   = GlobalKey<FormState>();
  final _payCtrl   = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool get _isEdit => widget.ledger != null;
  CustomerModel? _selectedCustomer;
  bool _isSaving   = false;
  bool _printReceipt = true;

  double get _previousAmount =>
      _isEdit ? widget.ledger!.previousAmount : (_selectedCustomer?.balance ?? 0.0);

  /// Full amount the customer physically handed over.
  double get _payAmount => double.tryParse(_payCtrl.text) ?? 0.0;

  /// Amount actually applied/adjusted against the due balance.
  /// This — NOT the full pay amount — is what gets saved as `pay_amount`
  /// in the database, since the trigger computes new_amount = balance - pay_amount
  /// and the cash counter adds pay_amount to installment.
  double get _appliedAmount {
    if (_previousAmount <= 0) return 0.0;
    return _payAmount > _previousAmount ? _previousAmount : _payAmount;
  }

  /// Remaining due after applying the payment. Never negative.
  double get _newAmount => _previousAmount - _appliedAmount;

  /// Amount to hand back to the customer when they pay more than the due amount.
  double get _returnAmount => _payAmount - _appliedAmount;

  /// Builds final notes: user's typed notes + auto-generated payment breakdown
  /// when there's a return involved, so the record is self-explanatory.
  String? _buildNotes() {
    final parts = <String>[];
    final typed = _notesCtrl.text.trim();
    if (typed.isNotEmpty) parts.add(typed);
    if (_returnAmount > 0) {
      parts.add(
        'Customer paid Rs ${_payAmount.toStringAsFixed(0)}, '
            'Rs ${_appliedAmount.toStringAsFixed(0)} adjusted against due, '
            'Rs ${_returnAmount.toStringAsFixed(0)} returned to customer.',
      );
    }
    return parts.isEmpty ? null : parts.join(' | ');
  }

  @override
  void initState() {
    super.initState();
    if (widget.ledger != null) {
      _payCtrl.text   = widget.ledger!.payAmount.toStringAsFixed(0);
      _notesCtrl.text = widget.ledger!.notes ?? '';
      final customers = ref.read(customerProvider).allCustomers;
      try {
        _selectedCustomer =
            customers.firstWhere((c) => c.id == widget.ledger!.customerId);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _payCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onCustomerChanged(CustomerModel? customer) =>
      setState(() => _selectedCustomer = customer);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) setState(() => _isSaving = true);

    try {
      if (_isEdit) {
        await ref.read(customerLedgerProvider.notifier).updateLedger(
          id:        widget.ledger!.id,
          payAmount: _appliedAmount,
          newAmount: _newAmount,
          notes:     _buildNotes(),
        );
      } else {
        await ref.read(customerLedgerProvider.notifier).addLedger(
          customerId:     _selectedCustomer!.id,
          customerName:   _selectedCustomer!.name,
          previousAmount: _previousAmount,
          payAmount:      _appliedAmount,
          newAmount:      _newAmount,
          notes:          _buildNotes(),
        );
      }

      // ✅ Print receipt if checkbox is on
      if (_printReceipt) {
        final auth     = ref.read(authProvider);
        final branch = await ref.read(branchProvider(auth.storeId).future);
        final counters = ref.read(counterProvider).counters;
        final counterName = auth.counterId != null ? counters.where((c) => c.id == auth.counterId).map((c) => c.counterName).firstOrNull ?? 'Counter' : 'Counter';
        await CustomerLedgerPrintService.printReceipt(
          storeName: branch?.name ?? "",
          branchAddress: branch?.address ?? "",
          branchPhone: branch?.phone ?? "",
          counterName: counterName,
          customerName: _selectedCustomer?.name ?? widget.ledger?.customerName ?? '',
          previousAmount:  _previousAmount,
          payAmount:  _payAmount,
          dueAmount: _newAmount,
          date: DateTime.now(),
          notes: _buildNotes(),
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Error: $e'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider)
        .allCustomers
        .where((c) => c.deletedAt == null && c.isActive)
        .toList();

    final dropdownItems = customers
        .map((c) => DropdownItem<CustomerModel>(
      value: c,
      label: '${c.name} — ${c.code}',
      icon:  Icons.person_outline_rounded,
    ))
        .toList();

    final hasReturn = _returnAmount > 0;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColor.primary,
                          size:  20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment Record', style: TextStyle(fontSize:   16, fontWeight: FontWeight.w700)),
                        Text('Record a customer payment', style: TextStyle(fontSize: 12, color:    AppColor.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      icon:  const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(foregroundColor: AppColor.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: AppColor.grey200),
                const SizedBox(height: 16),

                // ── Customer Dropdown ────────────────────
                const _Label('Customer *'),
                const SizedBox(height: 6),
                AppSearchableDropdown<CustomerModel>(
                  items: dropdownItems,
                  value: _selectedCustomer,
                  hint: 'Select customer...',
                  fullWidth: true,
                  onChanged: _onCustomerChanged,
                  validator: (v) =>
                  v == null ? 'Please select a customer' : null,
                ),

                const SizedBox(height: 16),

                // ── Previous Balance ─────────────────────
                _AmountField(
                  label: 'Current Balance',
                  value: _selectedCustomer == null ? '—' : 'Rs $_previousAmount',
                  color: _previousAmount > 0 ? AppColor.error : AppColor.success,
                  icon: Icons.account_balance_outlined,
                  readOnly: true,
                ),

                const SizedBox(height: 12),

                // ── Pay Amount ───────────────────────────
                const _Label('Pay Amount *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _payCtrl,
                  onChanged:    (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  cursorHeight: 14,
                  style: const TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.textPrimary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final p = double.tryParse(v);
                    if (p == null || p <= 0) return 'Enter a valid amount';
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixText:  'Rs ',
                    prefixStyle: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.primary),
                    hintText:  '0',
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
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: AppColor.error)),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Applied to Due (only shown when it differs from pay amount) ──
                if (hasReturn) ...[
                  _AmountField(
                    label: 'Applied to Due',
                    value: 'Rs ${_appliedAmount.toStringAsFixed(0)}',
                    color: AppColor.success,
                    icon: Icons.check_circle_outline_rounded,
                    readOnly: true,
                    subtitle: 'Amount adjusted against customer due',
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Remaining ────────────────────────────
                _AmountField(
                  label: 'Remaining',
                  value: _payCtrl.text.isEmpty || _selectedCustomer == null
                      ? '—'
                      : 'Rs ${_newAmount.toStringAsFixed(0)}',
                  color: _newAmount > 0 ? AppColor.warning : AppColor.success,
                  icon:     Icons.calculate_outlined,
                  readOnly: true,
                  subtitle: _newAmount == 0 && _payCtrl.text.isNotEmpty
                      ? 'Cleared'
                      : null,
                ),

                // ── Return Amount (only when customer overpays) ──
                if (hasReturn) ...[
                  const SizedBox(height: 12),
                  _AmountField(
                    label: 'Return to Customer',
                    value: 'Rs ${_returnAmount.toStringAsFixed(0)}',
                    color: AppColor.info,
                    icon: Icons.keyboard_return_rounded,
                    readOnly: true,
                    subtitle: 'Give this amount back to the customer',
                  ),
                ],

                const SizedBox(height: 16),

                // ── Notes ────────────────────────────────
                const _Label('Notes (Optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller:   _notesCtrl,
                  maxLines:     2,
                  cursorHeight: 14,
                  style: const TextStyle(
                      fontSize: 14, color: AppColor.textPrimary),
                  decoration: InputDecoration(
                    hintText:  'Payment notes...',
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

                const SizedBox(height: 16),

                // ── Print Checkbox ✅ ────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _printReceipt
                        ? AppColor.primary.withValues(alpha: 0.06)
                        : AppColor.grey100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _printReceipt
                          ? AppColor.primary.withValues(alpha: 0.3)
                          : AppColor.grey200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.print_rounded,
                        size:  18,
                        color: _printReceipt
                            ? AppColor.primary
                            : AppColor.textHint,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Print Receipt',
                                style: TextStyle(
                                    fontSize:   13,
                                    fontWeight: FontWeight.w600,
                                    color:      AppColor.textPrimary)),
                            Text('Receipt will print after saving',
                                style: TextStyle(
                                    fontSize: 11,
                                    color:    AppColor.textSecondary)),
                          ],
                        ),
                      ),
                      Switch(
                        value:          _printReceipt,
                        onChanged:      (v) =>
                            setState(() => _printReceipt = v),
                        activeColor:    AppColor.primary,
                        materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Save Button ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      AppColor.primary.withValues(alpha: 0.6),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                        width:  20,
                        height: 20,
                        child:  CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : Icon(
                        _printReceipt
                            ? Icons.print_rounded
                            : Icons.save_rounded,
                        size: 18),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : _printReceipt
                          ? 'Save & Print'
                          : 'Save Payment',
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
//  WIDGETS
// ─────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;
  final bool     readOnly;
  final String?  subtitle;

  const _AmountField({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.readOnly = false,
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
            color:        color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w700,
                            color:      color)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              fontSize: 10, color: color)),
                  ],
                ),
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