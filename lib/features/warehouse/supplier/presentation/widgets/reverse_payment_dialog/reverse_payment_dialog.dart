// Updated on 2026-09-28 11:49 AM
// =============================================================
// reverse_payment_dialog.dart
// Ledger mein galat MANUAL payment ko reverse karne ka dialog
// Ledger row ke "Reverse" button se khulta hai
//
// Flow: purani payment ki ULTI entry (balance + cash wapas) —
// "Sahi amount" diya ho to usi transaction mein nayi sahi payment bhi.
// Purani rows untouched rehti hain (history + cash chain safe).
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/auth/local/auth_local_storage.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_detail_models.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_detail_provider/supplier_detail_provider.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_provider/supplier_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_finance/data/warehouse_finance_repository.dart';

class ReversePaymentDialog extends ConsumerStatefulWidget {
  final SupplierModel       supplier; // fresh (detail screen se)
  final SupplierLedgerEntry entry;    // jo payment reverse karni hai

  const ReversePaymentDialog({
    super.key,
    required this.supplier,
    required this.entry,
  });

  // ── Static helper — easily open karo ─────────────────────
  static void show(BuildContext context, SupplierModel supplier,
      SupplierLedgerEntry entry) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) =>
          ReversePaymentDialog(supplier: supplier, entry: entry),
    );
  }

  @override
  ConsumerState<ReversePaymentDialog> createState() =>
      _ReversePaymentDialogState();
}

class _ReversePaymentDialogState extends ConsumerState<ReversePaymentDialog> {
  static const int _minReasonLength = 5;

  final _correctController = TextEditingController();
  final _reasonController  = TextEditingController();
  bool    _isSaving   = false;
  double? _cashInHand; // preview ke liye (load hone tak null)

  // ── Live calculations ─────────────────────────────────────
  double get _paidAmount => widget.entry.amount.abs();
  double get _balanceNow => widget.supplier.outstandingBalance;
  double get _correct {
    final text = _correctController.text.trim().replaceAll(',', '');
    return double.tryParse(text) ?? 0.0;
  }

  double get _balanceAfterReversal => _balanceNow + _paidAmount;
  double get _balanceFinal         => _balanceAfterReversal - _correct;
  bool   get _isOverpaying         => _correct > _balanceAfterReversal + 0.001;
  bool   get _reasonOk =>
      _reasonController.text.trim().length >= _minReasonLength;
  bool   get _canSave  => _reasonOk && !_isOverpaying && !_isSaving;

  @override
  void initState() {
    super.initState();
    _loadCash();
  }

  Future<void> _loadCash() async {
    try {
      final fin = await WarehouseFinanceRepository.instance.getOrCreate();
      if (mounted) setState(() => _cashInHand = fin.cashInHand);
    } catch (_) {
      // Preview sirf info hai — na mile to cash line nahi dikhegi
    }
  }

  @override
  void dispose() {
    _correctController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;

    return Dialog(
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColor.surface,
      child: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────
              _DialogHeader(
                supplierName: widget.supplier.name,
                onClose:      () => Navigator.of(context).pop(),
              ),

              // ── Body ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Galat payment info
                    Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:        AppColor.errorLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColor.error.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Galat payment',
                              style: TextStyle(fontSize: 11,
                                  color: AppColor.textSecondary)),
                          const SizedBox(height: 2),
                          Text('Rs ${_paidAmount.pkrFormat}',
                              style: TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.error)),
                          const SizedBox(height: 4),
                          Text(
                            '${_fmtDateTime(e.createdAt)}'
                            '${e.notes != null ? '  •  ${e.notes}' : ''}',
                            style: TextStyle(fontSize: 12,
                                color: AppColor.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Sahi amount (optional) ───────────────
                    Text('Sahi amount (optional)',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller:   _correctController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final text = newValue.text.replaceAll(',', '');
                          if (text.split('.').length > 2) return oldValue;
                          if (text.contains('.') &&
                              text.split('.')[1].length > 2) {
                            return oldValue;
                          }
                          return newValue;
                        }),
                      ],
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary),
                      decoration: _inputDecoration(
                        hint: 'Asal mein kitna diya tha',
                        prefixText: 'Rs ',
                        helperText:
                            'Khali chhodein agar payment hui hi nahi thi',
                        errorText: _isOverpaying
                            ? 'Amount outstanding (Rs ${_balanceAfterReversal.pkrFormat}) se zyada hai'
                            : null,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Wajah (required) ─────────────────────
                    Text('Wajah *',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _reasonController,
                      maxLines:   2,
                      onChanged:  (_) => setState(() {}),
                      style: TextStyle(fontSize: 13,
                          color: AppColor.textPrimary),
                      decoration: _inputDecoration(
                        hint: 'e.g. Galti se ek 0 zyada lag gaya',
                        helperText:
                            'Kam az kam $_minReasonLength huroof — record mein save hogi',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Preview ──────────────────────────────
                    Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:        AppColor.grey100,
                        borderRadius: BorderRadius.circular(10),
                        border:       Border.all(color: AppColor.grey200),
                      ),
                      child: Column(
                        children: [
                          _PreviewRow(
                            label: 'Supplier balance',
                            from:  _balanceNow,
                            to:    _balanceFinal,
                          ),
                          if (_cashInHand != null) ...[
                            const SizedBox(height: 8),
                            _PreviewRow(
                              label: 'Cash in hand',
                              from:  _cashInHand!,
                              to:    _cashInHand! + _paidAmount - _correct,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Footer — Cancel + Reverse ────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColor.grey200))),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap:        () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:        AppColor.grey100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text('Cancel',
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textSecondary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap:        _canSave ? _reverse : null,
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _canSave
                                ? AppColor.error
                                : AppColor.error.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(
                                  _correct > 0 ? 'Reverse & Save' : 'Reverse',
                                  style: TextStyle(fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reverse action ────────────────────────────────────────
  Future<void> _reverse() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    final correct = _correct;
    try {
      final userMap  = await AuthLocalStorage.loadUser();
      final userId   = userMap?['id']?.toString();
      final userName = userMap?['full_name']?.toString();

      await ref.read(supplierDetailProvider.notifier).reversePayment(
        supplierId:    widget.supplier.id,
        ledgerId:      widget.entry.id,
        reason:        _reasonController.text.trim(),
        correctAmount: correct,
        userId:        userId,
        userName:      userName,
      );

      // Fresh balance list state mein — detail top bar + agla dialog
      await ref.read(supplierProvider.notifier)
          .refreshSupplier(widget.supplier.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(correct > 0
                ? 'Rs ${_paidAmount.pkrFormat} reverse — '
                  'sahi payment Rs ${correct.pkrFormat} save ho gayi'
                : 'Rs ${_paidAmount.pkrFormat} payment reverse ho gayi'),
            backgroundColor: AppColor.success,
            behavior:        SnackBarBehavior.floating,
            duration:        const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Reverse mein masla: $e'),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    String? prefixText,
    String? helperText,
    String? errorText,
  }) {
    return InputDecoration(
      hintText:    hint,
      hintStyle:   TextStyle(fontSize: 13, color: AppColor.textHint,
          fontWeight: FontWeight.w400),
      prefixText:  prefixText,
      prefixStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColor.textSecondary),
      helperText:  helperText,
      helperStyle: TextStyle(fontSize: 11, color: AppColor.textSecondary),
      errorText:   errorText,
      filled:         true,
      fillColor:      AppColor.grey100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor.grey200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor.grey200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor.error)),
    );
  }

  // timestamptz → local display (UTC store, toLocal display rule)
  String _fmtDateTime(DateTime d) {
    final l  = d.toLocal();
    final h  = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final ap = l.hour < 12 ? 'AM' : 'PM';
    return '${l.day.toString().padLeft(2, '0')}-'
        '${l.month.toString().padLeft(2, '0')}-${l.year}, '
        '$h:${l.minute.toString().padLeft(2, '0')} $ap';
  }
}

// ─────────────────────────────────────────────────────────────
// DIALOG HEADER
// ─────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final String       supplierName;
  final VoidCallback onClose;

  const _DialogHeader({required this.supplierName, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColor.grey200))),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        AppColor.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.undo_rounded, size: 18, color: AppColor.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Reverse',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary)),
                Text(supplierName,
                    style: TextStyle(fontSize: 12,
                        color: AppColor.textSecondary)),
              ],
            ),
          ),
          InkWell(
            onTap:        onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:        AppColor.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close_rounded,
                  size: 16, color: AppColor.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREVIEW ROW — "label:  from → to"
// ─────────────────────────────────────────────────────────────

class _PreviewRow extends StatelessWidget {
  final String label;
  final double from;
  final double to;

  const _PreviewRow({required this.label, required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
        ),
        Text('Rs ${from.pkrFormat}',
            style: TextStyle(fontSize: 13, color: AppColor.textSecondary)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded,
              size: 14, color: AppColor.grey400),
        ),
        Text('Rs ${to.pkrFormat}',
            style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary)),
      ],
    );
  }
}
