// =============================================================
// pay_outstanding_dialog.dart
// Supplier ka outstanding balance pay karne ka dialog
// "Pay Amount" button se khulta hai
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/auth/local/auth_local_storage.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/provider/supplier_detail_provider/supplier_detail_provider.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';


class PayOutstandingDialog extends ConsumerStatefulWidget {
  final SupplierModel supplier;

  const PayOutstandingDialog({super.key, required this.supplier});

  // ── Static helper — easily open karo ─────────────────────
  static void show(BuildContext context, SupplierModel supplier) {
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => PayOutstandingDialog(supplier: supplier),
    );
  }

  @override
  ConsumerState<PayOutstandingDialog> createState() => _PayOutstandingDialogState();
}

class _PayOutstandingDialogState extends ConsumerState<PayOutstandingDialog> {
  final _amountController = TextEditingController();
  final _notesController  = TextEditingController();
  bool _isSaving          = false;

  // ── Live calculations ─────────────────────────────────────
  double get _outstanding    => widget.supplier.outstandingBalance;
  double get _enteredAmount {
    // Commas hata ke parse karo (live formatting ki wajah se commas ho sakti hain)
    final text = _amountController.text.trim().replaceAll(',', '');
    return double.tryParse(text) ?? 0.0;
  }
  double get _balanceAfterPay => (_outstanding - _enteredAmount).clamp(0, double.infinity);
  bool   get _isOverpaying    => _enteredAmount > _outstanding;
  bool   get _hasValidAmount  => _enteredAmount > 0 && !_isOverpaying;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;

    return Dialog(
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColor.surface,
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────
            _DialogHeader(supplier: s,
                onClose: () => Navigator.of(context).pop()),

            // ── Body ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Balance summary cards ────────────────
                  Row(
                    children: [
                      _SummaryCard(
                        label: 'Outstanding Balance',
                        value: 'Rs ${_outstanding.pkrFormat}',
                        color: _outstanding > 0 ? AppColor.error : AppColor.success,
                        icon:  Icons.account_balance_wallet_outlined,
                      ),
                      const SizedBox(width: 10),
                      _SummaryCard(
                        label: 'Last Payment',
                        value: 'Rs —',         // TODO: ledger se last payment
                        color: AppColor.info,
                        icon:  Icons.history_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Amount input ─────────────────────────
                  Text('Pay Amount',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColor.textPrimary)),
                  const SizedBox(height: 6),

                  TextField(
                    controller:   _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    // Sirf numbers — commas + dot allow, baaki sab block
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        // Commas hata ke validate karo
                        final text = newValue.text.replaceAll(',', '');
                        if (text.split('.').length > 2) return oldValue;
                        if (text.contains('.')) {
                          final parts = text.split('.');
                          if (parts[1].length > 2) return oldValue;
                        }
                        return newValue;
                      }),
                    ],
                    onChanged: (val) {
                      // Commas hata ke integer + decimal parts alag karo
                      final plain = val.replaceAll(',', '');
                      final parts = plain.split('.');
                      if (parts[0].isNotEmpty) {
                        final decPart = parts.length > 1 ? '.${parts[1]}' : '';
                        final fmtInt  = _pkrInputFmt(parts[0]);
                        final newText = '$fmtInt$decPart';
                        if (newText != val) {
                          _amountController.value = TextEditingValue(
                            text:      newText,
                            selection: TextSelection.collapsed(
                                offset: newText.length),
                          );
                        }
                      }
                      setState(() {});
                    },
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary),
                    decoration: InputDecoration(
                      hintText:    'Amount darj karein',
                      hintStyle:   TextStyle(fontSize: 14,
                          color: AppColor.textHint,
                          fontWeight: FontWeight.w400),
                      prefixText:  'Rs ',
                      prefixStyle: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary),
                      filled:         true,
                      fillColor:      AppColor.grey100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColor.grey200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColor.grey200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppColor.primary, width: 1.5)),
                      // Overpaying error
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColor.error)),
                      errorText: _isOverpaying
                          ? 'Amount outstanding se zyada hai'
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Live balance preview ─────────────────
                  // Sirf tab dikhao jab user ne kuch type kiya ho
                  // ── Notes input ─────────────────────────
                  const SizedBox(height: 14),
                  Text('Notes (optional)',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColor.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    maxLines:   2,
                    style: TextStyle(fontSize: 13, color: AppColor.textPrimary),
                    decoration: InputDecoration(
                      hintText:       'Payment ki wajah ya note...',
                      hintStyle:      TextStyle(fontSize: 13, color: AppColor.textHint),
                      filled:         true,
                      fillColor:      AppColor.grey100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColor.grey200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColor.grey200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppColor.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_enteredAmount > 0) ...[
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
                            label: 'Outstanding Balance',
                            value: 'Rs ${_outstanding.pkrFormat}',
                            color: AppColor.error,
                          ),
                          const SizedBox(height: 8),
                          _PreviewRow(
                            label: 'Pay Amount',
                            value: '- Rs ${_enteredAmount.pkrFormat}',
                            color: AppColor.success,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: AppColor.grey300),
                          ),
                          _PreviewRow(
                            label:   'Balance After Payment',
                            value:   'Rs ${_balanceAfterPay.pkrFormat}',
                            color:   _balanceAfterPay == 0
                                ? AppColor.success : AppColor.warning,
                            isBold:  true,
                          ),
                          // Fully clear message
                          if (_balanceAfterPay == 0 && !_isOverpaying) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color:        AppColor.successLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded,
                                      size: 14, color: AppColor.success),
                                  const SizedBox(width: 5),
                                  Text('Account fully clear ho jayega',
                                      style: TextStyle(fontSize: 12,
                                          color: AppColor.success,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Footer — Cancel + Pay ────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColor.grey200))),
              child: Row(
                children: [
                  // Cancel button
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

                  // Pay button
                  Expanded(
                    child: InkWell(
                      // Disabled agar valid amount nahi
                      onTap: (_hasValidAmount && !_isSaving) ? _pay : null,
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _hasValidAmount
                              ? AppColor.primary
                              : AppColor.primary.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : Text('Pay ${_enteredAmount > 0 ? _fmtRs(_enteredAmount) : ''}',
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
    );
  }

  // ── Pay action ────────────────────────────────────────────
  Future<void> _pay() async {
    if (!_hasValidAmount) return;
    setState(() => _isSaving = true);

    try {
      // SharedPreferences se current user lo
      final userMap = await AuthLocalStorage.loadUser();
      final userId   = userMap?['id']?.toString();
      final userName = userMap?['full_name']?.toString();

      await ref.read(supplierDetailProvider.notifier).payOutstanding(
        supplierId: widget.supplier.id,
        amount:     _enteredAmount,
        notes:      _notesController.text.trim().isEmpty
            ? 'Manual payment'
            : _notesController.text.trim(),
        userId:     userId,
        userName: userName
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_fmtRs(_enteredAmount)} payment recorded — ${widget.supplier.name}'),
            backgroundColor: AppColor.success,
            behavior:        SnackBarBehavior.floating,
            duration:        const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Payment mein masla: $e'),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _fmtRs(double v) => 'Rs ${v.pkrFormat}';

  // Text field ke liye live lakh-comma formatter
  // (extension ko directly use nahi kar sakte kyunki ye string pe kaam karta hai)
  String _pkrInputFmt(String s) {
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rem   = s.substring(0, s.length - 3);
    final buf   = StringBuffer();
    final start = rem.length % 2;
    if (start > 0) buf.write(rem.substring(0, start));
    for (int i = start; i < rem.length; i += 2) {
      if (buf.isNotEmpty) buf.write(',');
      buf.write(rem.substring(i, i + 2));
    }
    buf.write(',');
    buf.write(last3);
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────────────
// DIALOG HEADER
// ─────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback  onClose;

  const _DialogHeader({required this.supplier, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColor.grey200))),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        AppColor.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.payments_outlined,
                size: 18, color: AppColor.success),
          ),
          const SizedBox(width: 12),

          // Title + supplier name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pay Outstanding',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary)),
                Text(supplier.name,
                    style: TextStyle(fontSize: 12,
                        color: AppColor.textSecondary)),
              ],
            ),
          ),

          // Close button
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
// SUMMARY CARD — Outstanding + Last Payment
// ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  Text(label,
                      style: TextStyle(fontSize: 11,
                          color: AppColor.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREVIEW ROW — live balance calculation
// ─────────────────────────────────────────────────────────────

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final bool   isBold;

  const _PreviewRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize:   isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color:      AppColor.textSecondary,
            )),
        Text(value,
            style: TextStyle(
              fontSize:   isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color:      color,
            )),
      ],
    );
  }
}