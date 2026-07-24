// lib/features/branch/service/presentation/widget/service_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/color/app_color.dart';
import '../../data/model/service_model.dart';
import '../provideer/service_provider.dart';


// ════════════════════════════════════════════════════════════
//  1. SERVICE CART ITEM WIDGET
// ════════════════════════════════════════════════════════════
class ServiceCartItemWidget extends StatefulWidget {
  final ServiceCartItem      item;
  final NumberFormat         formatter;
  final VoidCallback         onRemove;
  final ValueChanged<double> onAmountChanged;

  const ServiceCartItemWidget({
    super.key,
    required this.item,
    required this.formatter,
    required this.onRemove,
    required this.onAmountChanged,
  });

  @override
  State<ServiceCartItemWidget> createState() => _ServiceCartItemWidgetState();
}

class _ServiceCartItemWidgetState extends State<ServiceCartItemWidget> {
  late TextEditingController _amountCtrl;
  bool _amountFocused = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.item.amount > 0
          ? widget.item.amount.toStringAsFixed(0)
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
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
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
            // Header
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

            // Amount | Fee | Total
            Row(
              children: [
                // Amount (editable)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColor.textSecondary)),
                      const SizedBox(height: 4),
                      Focus(
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
                          decoration: InputDecoration(
                            prefixText: 'Rs ',
                            isDense:    true,
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onTap: () => _amountCtrl.selection =
                              TextSelection(
                                baseOffset:   0,
                                extentOffset: _amountCtrl.text.length,
                              ),
                          onFieldSubmitted: (v) {
                            final val = double.tryParse(v) ?? 0;
                            widget.onAmountChanged(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Fee (read-only)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Service Fee',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColor.textSecondary)),
                      const SizedBox(height: 4),
                      Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color:        Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Rs ${widget.formatter.format(item.calculatedFee)}',
                          style: TextStyle(
                            fontSize:   13,
                            color:      AppColor.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Total (read-only)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColor.textSecondary)),
                      const SizedBox(height: 4),
                      Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color:        Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Rs ${widget.formatter.format(item.total)}',
                          style: TextStyle(
                            fontSize:   13,
                            color:      Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              'Fee rule: Rs ${widget.formatter.format(item.service.perAmount)} '
                  'per → Rs ${widget.formatter.format(item.service.feeAmount)} fee',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════
//  2. SERVICE PAYMENT DIALOG
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
  final _fmt = NumberFormat('#,##0.00');

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
        '${widget.method == 'cash' ? 'Cash' : 'Credit'} Payment',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize:       MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grand Total: Rs ${_fmt.format(widget.grandTotal)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller:   _ctrl,
            autofocus:    true,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(
              labelText:  'Amount',
              prefixText: 'Rs ',
              border: OutlineInputBorder(
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
            final val = double.tryParse(_ctrl.text) ?? 0;
            if (val <= 0) return;
            widget.onConfirm(val);
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
//  3. SERVICE FORM DIALOG  (Add + Edit) — public, used directly
//     from ServiceScreen's "Add Service" button
// ════════════════════════════════════════════════════════════
class ServiceFormDialog extends ConsumerStatefulWidget {
  final ServiceModel? existing;
  const ServiceFormDialog({super.key, this.existing});

  @override
  ConsumerState<ServiceFormDialog> createState() =>
      _ServiceFormDialogState();
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