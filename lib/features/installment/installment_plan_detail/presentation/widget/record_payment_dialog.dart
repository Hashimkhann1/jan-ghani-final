import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/presentation/provider/installment_dashboard_provider.dart';
import 'package:jan_ghani_final/features/installment/installment_plan_detail/domain/installment_schedule_item.dart';

/// Qist ki payment record karne ka dialog: unpaid qist chuno, raqam (poori ya
/// partial) aur note → record_installment_payment RPC.
Future<bool?> showRecordPaymentDialog(BuildContext context, InstallmentPlan plan) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _RecordPaymentDialog(plan: plan),
  );
}

class _RecordPaymentDialog extends ConsumerStatefulWidget {
  final InstallmentPlan plan;
  const _RecordPaymentDialog({required this.plan});

  @override
  ConsumerState<_RecordPaymentDialog> createState() =>
      _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<_RecordPaymentDialog> {
  late final List<InstallmentDue> _unpaid =
      widget.plan.dues.where((d) => !d.isPaid).toList();
  late InstallmentDue _selected = _unpaid.first;
  late final TextEditingController _amountCtrl =
      TextEditingController(text: _selected.remaining.toStringAsFixed(0));
  final _noteCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Enter the amount received');
      return;
    }
    if (amount > _selected.remaining + 0.5) {
      setState(() => _error =
          'Maximum for this installment is Rs ${_selected.remaining.pkrFormat}');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(installmentRemoteProvider).recordPayment(
            scheduleId: _selected.id,
            amount: amount,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      if (!mounted) return;
      refreshInstallments(ref);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$e'.replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Record Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.plan.product,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColor.textSecondary)),
            14.hBox,
            DropdownButtonFormField<InstallmentDue>(
              initialValue: _selected,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Installment'),
              items: [
                for (final d in _unpaid)
                  DropdownMenuItem(
                    value: d,
                    child: Text(
                        '#${d.number} • ${planDetailDmy(d.dueDate)} • Rs ${d.remaining.pkrFormat}'),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (d) {
                      if (d == null) return;
                      setState(() {
                        _selected = d;
                        _amountCtrl.text = d.remaining.toStringAsFixed(0);
                        _error = null;
                      });
                    },
            ),
            12.hBox,
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Amount received', prefixText: 'Rs '),
            ),
            12.hBox,
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            if (_error != null) ...[
              12.hBox,
              Text(_error!,
                  style: const TextStyle(color: AppColor.error, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
