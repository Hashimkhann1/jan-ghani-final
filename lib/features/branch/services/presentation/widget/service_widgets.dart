// lib/features/branch/service/presentation/widget/service_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/color/app_color.dart';
import '../../data/model/service_model.dart';
import '../provideer/service_provider.dart';


// ════════════════════════════════════════════════════════════
//  1. SERVICE CART ITEM WIDGET  (discount field added)
// ════════════════════════════════════════════════════════════
class ServiceCartItemWidget extends StatefulWidget {
  final ServiceCartItem      item;
  final NumberFormat         formatter;
  final VoidCallback         onRemove;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<double> onDiscountChanged;   // ← NEW

  const ServiceCartItemWidget({
    super.key,
    required this.item,
    required this.formatter,
    required this.onRemove,
    required this.onAmountChanged,
    required this.onDiscountChanged,              // ← NEW
  });

  @override
  State<ServiceCartItemWidget> createState() => _ServiceCartItemWidgetState();
}

class _ServiceCartItemWidgetState extends State<ServiceCartItemWidget> {
  late TextEditingController _amountCtrl;
  late TextEditingController _discountCtrl;        // ← NEW
  bool _amountFocused   = false;
  bool _discountFocused = false;                   // ← NEW

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.item.amount > 0
          ? widget.item.amount.toStringAsFixed(0)
          : '',
    );
    _discountCtrl = TextEditingController(        // ← NEW
      text: widget.item.discount > 0
          ? widget.item.discount.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void didUpdateWidget(ServiceCartItemWidget old) {
    super.didUpdateWidget(old);
    if (!_amountFocused && old.item.amount != widget.item.amount) {
      _amountCtrl.text = widget.item.amount > 0
          ? widget.item.amount.toStringAsFixed(0)
          : '';
    }
    if (!_discountFocused && old.item.discount != widget.item.discount) {  // ← NEW
      _discountCtrl.text = widget.item.discount > 0
          ? widget.item.discount.toStringAsFixed(0)
          : '';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _discountCtrl.dispose();   // ← NEW
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.service.serviceType,
                    style: TextStyle(
                      fontSize:   11,
                      color:      AppColor.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:   14,
                    ),
                  ),
                ),
                IconButton(
                  icon:        const Icon(Icons.close, size: 18),
                  color:       Colors.red.shade300,
                  onPressed:   widget.onRemove,
                  constraints: const BoxConstraints(),
                  padding:     EdgeInsets.zero,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Row 1: Amount | Service Fee | Total ───────
            Row(
              children: [
                // Amount (editable)
                Expanded(
                  child: _FieldLabel(
                    label: 'Amount',
                    child: Focus(
                      onFocusChange: (focused) {
                        setState(() => _amountFocused = focused);
                        if (!focused) {
                          final val =
                              double.tryParse(_amountCtrl.text) ?? 0;
                          widget.onAmountChanged(val);
                        }
                      },
                      child: TextFormField(
                        controller:   _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]')),
                        ],
                        decoration: _inputDeco('Rs '),
                        onTap: () => _selectAll(_amountCtrl),
                        onFieldSubmitted: (v) =>
                            widget.onAmountChanged(
                                double.tryParse(v) ?? 0),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Service Fee (read-only)
                Expanded(
                  child: _FieldLabel(
                    label: 'Service Fee',
                    child: _ReadOnlyBox(
                      value: 'Rs ${widget.formatter.format(item.calculatedFee)}',
                      color: AppColor.primary,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Total (read-only, green)
                Expanded(
                  child: _FieldLabel(
                    label: 'Total',
                    child: _ReadOnlyBox(
                      value: 'Rs ${widget.formatter.format(item.total)}',
                      color: Colors.green.shade700,
                      bgColor: Colors.green.shade50,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Row 2: Discount ───────────────────────────
            Row(
              children: [
                // Discount (editable)
                Expanded(
                  flex: 1,
                  child: _FieldLabel(
                    label: 'Discount',
                    child: Focus(
                      onFocusChange: (focused) {
                        setState(() => _discountFocused = focused);
                        if (!focused) {
                          final val =
                              double.tryParse(_discountCtrl.text) ?? 0;
                          widget.onDiscountChanged(val);
                        }
                      },
                      child: TextFormField(
                        controller:   _discountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]')),
                        ],
                        decoration: _inputDeco('Rs ', hintText: '0'),
                        onTap: () => _selectAll(_discountCtrl),
                        onFieldSubmitted: (v) =>
                            widget.onDiscountChanged(
                                double.tryParse(v) ?? 0),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Fee rule info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(
                      'Fee rule: Rs ${widget.formatter.format(item.service.perAmount)}'
                          ' per → Rs ${widget.formatter.format(item.service.feeAmount)} fee',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String prefix, {String? hintText}) =>
      InputDecoration(
        prefixText:     prefix,
        hintText:       hintText,
        isDense:        true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );

  void _selectAll(TextEditingController ctrl) =>
      ctrl.selection = TextSelection(
        baseOffset:   0,
        extentOffset: ctrl.text.length,
      );
}

// ── Small helpers ──────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldLabel({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppColor.textSecondary)),
      const SizedBox(height: 4),
      child,
    ],
  );
}

class _ReadOnlyBox extends StatelessWidget {
  final String color;
  final Color  bgColor;
  final String value;

  const _ReadOnlyBox({
    required this.value,
    required Color color,
    Color? bgColor,
  })  : color   = '',
        bgColor = const Color(0x00000000),
        _color  = color,
        _bgColor = bgColor ?? const Color(0xFFF5F5F5);

  final Color _color;
  final Color _bgColor;

  @override
  Widget build(BuildContext context) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color:        _bgColor,
      borderRadius: BorderRadius.circular(8),
      border:       Border.all(color: Colors.grey.shade300),
    ),
    child: Text(
      value,
      style: TextStyle(
        fontSize:   13,
        color:      _color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}


// ════════════════════════════════════════════════════════════
//  2. SERVICE PAYMENT DIALOG  (unchanged)
// ════════════════════════════════════════════════════════════
class ServicePaymentDialog extends StatefulWidget {
  final String              method;
  final double              grandTotal;
  final ValueChanged<double> onConfirm;

  const ServicePaymentDialog({
    super.key,
    required this.method,
    required this.grandTotal,
    required this.onConfirm,
  });

  @override
  State<ServicePaymentDialog> createState() => _ServicePaymentDialogState();
}

class _ServicePaymentDialogState extends State<ServicePaymentDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.grandTotal.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.method == 'cash' ? 'Cash Payment' : 'Credit Payment',
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Grand Total: Rs ${NumberFormat('#,##0.00').format(widget.grandTotal)}',
            style: const TextStyle(
                fontSize: 14, color: AppColor.textSecondary),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller:   _ctrl,
            autofocus:    true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(
              labelText:  'Amount',
              prefixText: 'Rs ',
              border:     OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onTap: () => _ctrl.selection = TextSelection(
              baseOffset:   0,
              extentOffset: _ctrl.text.length,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_ctrl.text) ?? 0;
            if (amount <= 0) return;
            widget.onConfirm(amount);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary),
          child: const Text('Confirm',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}


// ════════════════════════════════════════════════════════════
//  3. CASH TRANSFER DIALOG  (NEW)
//
//  Do modes:
//  - Cash → Bank: customer ne bank transfer bheja, branch ne
//    us ko cash diya. Branch ka cash NIKLA, bank AAYA.
//  - Bank → Cash: branch ne cash bank mein dala. Branch ka
//    cash NIKLA, bank GAYA.
// ════════════════════════════════════════════════════════════
class CashTransferDialog extends ConsumerStatefulWidget {
  const CashTransferDialog({super.key});

  @override
  ConsumerState<CashTransferDialog> createState() =>
      _CashTransferDialogState();
}

class _CashTransferDialogState extends ConsumerState<CashTransferDialog> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();

  // 'bank_to_cash' = customer ne bank se bheja, branch ne cash diya
  // 'cash_to_bank' = branch ne cash diya aur bank se liya
  String _transferType = 'bank_to_cash';
  bool   _saving       = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.swap_horiz_rounded,
              color: AppColor.primary, size: 22),
          const SizedBox(width: 8),
          const Text(
            'Cash Transfer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Transfer Type Toggle ───────────────────
              const Text(
                'Transfer Type',
                style: TextStyle(
                    fontSize: 12, color: AppColor.textSecondary),
              ),
              const SizedBox(height: 8),

              // Bank → Cash card
              _TransferTypeCard(
                title:       'Bank → Cash',
                subtitle:    'Customer ne bank se bheja,\nbranch ne cash diya',
                icon:        Icons.account_balance_outlined,
                iconColor:   Colors.blue,
                selected:    _transferType == 'bank_to_cash',
                onTap:       () => setState(
                        () => _transferType = 'bank_to_cash'),
              ),

              const SizedBox(height: 8),

              // Cash → Bank card
              _TransferTypeCard(
                title:       'Cash → Bank',
                subtitle:    'Branch ka cash bank mein gaya\n(outgoing)',
                icon:        Icons.upload_outlined,
                iconColor:   Colors.orange,
                selected:    _transferType == 'cash_to_bank',
                onTap:       () => setState(
                        () => _transferType = 'cash_to_bank'),
              ),

              const SizedBox(height: 16),

              // ── Amount ────────────────────────────────
              TextFormField(
                controller:   _amountCtrl,
                autofocus:    true,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: InputDecoration(
                  labelText:  'Amount',
                  prefixText: 'Rs ',
                  border:     OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) {
                  final val = double.tryParse(v ?? '') ?? 0;
                  if (val <= 0) return 'Valid amount enter karein';
                  return null;
                },
                onTap: () => _amountCtrl.selection = TextSelection(
                  baseOffset:   0,
                  extentOffset: _amountCtrl.text.length,
                ),
              ),

              const SizedBox(height: 12),

              // ── Description ───────────────────────────
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border:    OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: 12),

              // ── Info Box ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        _transferType == 'bank_to_cash'
                      ? Colors.blue.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _transferType == 'bank_to_cash'
                        ? Colors.blue.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Text(
                  _transferType == 'bank_to_cash'
                      ? '✅ Cash counter mein IZAFA hoga\n'
                      '(cash_in badhe ga, total_amount badhe ga)'
                      : '⬇️ Cash counter se GHATA hoga\n'
                      '(cash_out badhe ga, total_amount ghate ga)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _transferType == 'bank_to_cash'
                        ? Colors.blue.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _submit,
          icon:  _saving
              ? const SizedBox(
              height: 16, width: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 18, color: Colors.white),
          label: const Text('Save Transfer',
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final amount = double.parse(_amountCtrl.text);
    final desc   = _descCtrl.text.trim().isEmpty
        ? null
        : _descCtrl.text.trim();

    final ok = await ref
        .read(serviceInvoiceProvider.notifier)
        .saveCashTransfer(
      amount:       amount,
      transferType: _transferType,
      description:  desc,
    );

    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _transferType == 'bank_to_cash'
                  ? 'Bank → Cash transfer saved!'
                  : 'Cash → Bank transfer saved!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

// ── Transfer Type Card ─────────────────────────────────────
class _TransferTypeCard extends StatelessWidget {
  final String     title;
  final String     subtitle;
  final IconData   icon;
  final Color      iconColor;
  final bool       selected;
  final VoidCallback onTap;

  const _TransferTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:  const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        selected
              ? AppColor.primary.withOpacity(0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColor.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColor.primary : iconColor,
                size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize:   13,
                      color: selected ? AppColor.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle,
                  color: AppColor.primary, size: 20),
          ],
        ),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════
//  4. SERVICE FORM DIALOG  (unchanged)
// ════════════════════════════════════════════════════════════
class ServiceFormDialog extends ConsumerStatefulWidget {
  final ServiceModel? existing;
  const ServiceFormDialog({super.key, required this.existing});

  @override
  ConsumerState<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends ConsumerState<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _perAmountCtrl;
  late TextEditingController _feeAmountCtrl;
  late TextEditingController _notesCtrl;
  late String _selectedType;
  bool _saving = false;

  static const _serviceTypes = [
    'mobile_load',
    'mobile_package',
    'pay_bill',
    'money_transfer',
    'bank_to_cash',
    'cash_to_bank',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    final e        = widget.existing;
    _nameCtrl      = TextEditingController(text: e?.name ?? '');
    _selectedType  = e?.serviceType ?? _serviceTypes.first;
    _perAmountCtrl = TextEditingController(
        text: e?.perAmount.toStringAsFixed(0) ?? '1000');
    _feeAmountCtrl = TextEditingController(
        text: e?.feeAmount.toStringAsFixed(0) ?? '10');
    _notesCtrl     = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _perAmountCtrl.dispose();
    _feeAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit Service' : 'Add New Service',
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'Name required'
                    : null,
              ),
              const SizedBox(height: 12),

              // Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Service Type',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: _serviceTypes
                    .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    t.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ))
                    .toList(),
                onChanged: (v) => setState(
                        () => _selectedType = v ?? _serviceTypes.first),
              ),
              const SizedBox(height: 12),

              // Fee Rule
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller:   _perAmountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText:  'Per Amount (Rs)',
                        helperText: 'e.g. 1000',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) =>
                      (double.tryParse(v ?? '') ?? 0) <= 0
                          ? 'Required'
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child:   Text('→',
                        style: TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller:   _feeAmountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText:  'Fee (Rs)',
                        helperText: 'e.g. 10',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) =>
                      (double.tryParse(v ?? '') ?? -1) < 0
                          ? 'Required'
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                'Means: Rs ${_perAmountCtrl.text.isEmpty ? '?' : _perAmountCtrl.text} '
                    'gets Rs ${_feeAmountCtrl.text.isEmpty ? '?' : _feeAmountCtrl.text} fee',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                maxLines:   2,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary),
          child: _saving
              ? const SizedBox(
            height: 18, width: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : Text(
            isEdit ? 'Update' : 'Add Service',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final notifier = ref.read(serviceListProvider.notifier);
    bool ok;

    if (widget.existing != null) {
      ok = await notifier.update(
        id:          widget.existing!.id,
        name:        _nameCtrl.text.trim(),
        serviceType: _selectedType,
        perAmount:   double.parse(_perAmountCtrl.text),
        feeAmount:   double.parse(_feeAmountCtrl.text),
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );
    } else {
      ok = await notifier.create(
        name:        _nameCtrl.text.trim(),
        serviceType: _selectedType,
        perAmount:   double.parse(_perAmountCtrl.text),
        feeAmount:   double.parse(_feeAmountCtrl.text),
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context);
    }
  }
}