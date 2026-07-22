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
//  2. SERVICE ADD DIALOG  (Bottom Sheet ki jagah AlertDialog)
//     AppBar mein "Add Service" button se khulta hai
// ════════════════════════════════════════════════════════════
class ServiceAddDialog extends ConsumerWidget {
  final ValueChanged<ServiceModel> onServiceSelected;

  const ServiceAddDialog({super.key, required this.onServiceSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.miscellaneous_services_outlined,
                      color: AppColor.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Service Select Karo',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Add New service shortcut
                  TextButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const _ServiceFormDialog(existing: null),
                    ),
                    icon:  const Icon(Icons.add, size: 16),
                    label: const Text('New', style: TextStyle(fontSize: 13)),
                  ),
                  IconButton(
                    icon:      const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Service List ────────────────────────────────
            Expanded(
              child: servicesAsync.when(
                loading: () =>
                const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (services) {
                  final active =
                  services.where((s) => s.isActive).toList();

                  if (active.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.miscellaneous_services_outlined,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          const Text('Koi active service nahi'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) =>
                              const _ServiceFormDialog(existing: null),
                            ),
                            icon:  const Icon(Icons.add),
                            label: const Text('Add Service'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding:          const EdgeInsets.symmetric(vertical: 8),
                    itemCount:        active.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final s = active[i];
                      return ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor:
                          AppColor.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.miscellaneous_services_outlined,
                            color: AppColor.primary,
                            size:  20,
                          ),
                        ),
                        title: Text(
                          s.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${s.serviceType.replaceAll('_', ' ').toUpperCase()}'
                              '  •  Rs ${s.feeAmount.toStringAsFixed(0)}'
                              ' per Rs ${s.perAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            onServiceSelected(s);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize:   Size.zero,
                            tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Add',
                              style: TextStyle(fontSize: 13)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════
//  3. SERVICE PAYMENT DIALOG
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
//  4. SERVICE MANAGE SCREEN
//     AppBar mein "Manage Services" se khulta hai
// ════════════════════════════════════════════════════════════
class ServiceManageScreen extends ConsumerWidget {
  const ServiceManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services'),
        actions: [
          IconButton(
            icon:      const Icon(Icons.add),
            tooltip:   'New Service',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _ServiceFormDialog(existing: null),
            ),
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.miscellaneous_services_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('Koi service nahi'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) =>
                      const _ServiceFormDialog(existing: null),
                    ),
                    icon:  const Icon(Icons.add),
                    label: const Text('Add Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding:          const EdgeInsets.all(12),
            itemCount:        services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final s = services[i];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColor.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.miscellaneous_services_outlined,
                      color: AppColor.primary,
                      size:  20,
                    ),
                  ),
                  title: Text(s.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${s.serviceType}  •  '
                        'Rs ${s.feeAmount.toStringAsFixed(0)} per '
                        'Rs ${s.perAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value:       s.isActive,
                        activeColor: AppColor.primary,
                        onChanged:   (_) => ref
                            .read(serviceListProvider.notifier)
                            .update(
                          id:          s.id,
                          name:        s.name,
                          serviceType: s.serviceType,
                          perAmount:   s.perAmount,
                          feeAmount:   s.feeAmount,
                          notes:       s.notes,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => _ServiceFormDialog(existing: s),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: Colors.red.shade300),
                        onPressed: () =>
                            _confirmDelete(context, ref, s),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ServiceModel s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Service Delete Karo?'),
        content: Text('"${s.name}" delete ho jayega.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(serviceListProvider.notifier).delete(s.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════
//  5. SERVICE FORM DIALOG  (Add + Edit)
// ════════════════════════════════════════════════════════════
class _ServiceFormDialog extends ConsumerStatefulWidget {
  final ServiceModel? existing;
  const _ServiceFormDialog({this.existing});

  @override
  ConsumerState<_ServiceFormDialog> createState() =>
      _ServiceFormDialogState();
}

class _ServiceFormDialogState extends ConsumerState<_ServiceFormDialog> {
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
        isEdit ? 'Service Edit Karo' : 'Nai Service Add Karo',
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
                'Matlab: Rs ${_perAmountCtrl.text.isEmpty ? '?' : _perAmountCtrl.text} '
                    'par Rs ${_feeAmountCtrl.text.isEmpty ? '?' : _feeAmountCtrl.text} fee loge',
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