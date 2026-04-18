import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/service/print/print_service.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';

Future<void> showPaymentDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context:            context,
    barrierDismissible: false,
    builder:            (_) => const _PaymentDialog(),
  );
}

class _PaymentDialog extends ConsumerStatefulWidget {
  const _PaymentDialog();

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  final _cashCtrl   = TextEditingController();
  final _cardCtrl   = TextEditingController();
  final _creditCtrl = TextEditingController();

  bool _printReceipt = true; // default ON

  double get _cash   => double.tryParse(_cashCtrl.text.trim())   ?? 0;
  double get _card   => double.tryParse(_cardCtrl.text.trim())   ?? 0;
  double get _credit => double.tryParse(_creditCtrl.text.trim()) ?? 0;
  double get _paid   => _cash + _card + _credit;

  double get _grandTotal  => ref.read(saleInvoiceProvider).grandTotal;
  double get _remaining   => _grandTotal - _paid;
  bool   get _isValid     => _remaining.abs() < 0.01;
  bool   get _hasCustomer => ref.read(saleInvoiceProvider).selectedCustomer != null;

  @override
  void dispose() {
    _cashCtrl.dispose();
    _cardCtrl.dispose();
    _creditCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_isValid) return;

    // ── Capture state BEFORE save (state resets after save) ──────────────────
    final state        = ref.read(saleInvoiceProvider);
    final invoiceNo    = state.invoiceNo;
    final date         = state.date;
    final customerName = state.selectedCustomer?.name;
    final items        = [...state.cartItems];
    final totalAmount  = state.totalBeforeTax;
    final totalDiscount = state.totalDiscount;
    final grandTotal   = state.grandTotal;
    final payments     = <PaymentEntry>[
      if (_cash   > 0) PaymentEntry(method: 'cash',   amount: _cash),
      if (_card   > 0) PaymentEntry(method: 'card',   amount: _card),
      if (_hasCustomer && _credit > 0)
        PaymentEntry(method: 'credit', amount: _credit),
    ];
    // ─────────────────────────────────────────────────────────────────────────

    final notifier = ref.read(saleInvoiceProvider.notifier);
    await notifier.updatePayment('cash',   _cash);
    await notifier.updatePayment('card',   _card);
    if (_hasCustomer) await notifier.updatePayment('credit', _credit);

    final ok = await notifier.saveInvoice();
    if (!mounted) return;
    Navigator.of(context).pop();

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         const Text('Invoice saved!',
            style: TextStyle(fontSize: 14)),
        backgroundColor: AppColor.success,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));

      // ── Print receipt if checkbox is ON ───────────────────────────────────
      if (_printReceipt) {
        await ThermalPrintService.printSaleInvoice(
          storeName:     'Jan Ghani Store',
          invoiceNo:     invoiceNo,
          date:          date,
          customerName:  customerName,
          items:         items,
          totalAmount:   totalAmount,
          totalDiscount: totalDiscount,
          grandTotal:    grandTotal,
          payments:      payments,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state      = ref.watch(saleInvoiceProvider);
    final grandTotal = state.grandTotal;
    final isSaving   = state.isSaving;
    final remainingColor =
    _remaining > 0.01 ? AppColor.error : AppColor.success;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ────────────────────────────────────────
              Row(children: [
                const Icon(Icons.payments_outlined,
                    color: AppColor.primary, size: 22),
                const SizedBox(width: 10),
                const Text('Payment',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: AppColor.textSecondary),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Grand Total ───────────────────────────────────
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color:  AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColor.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total',
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w600,
                            color:      AppColor.textSecondary)),
                    Text('Rs ${grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize:   22,
                            fontWeight: FontWeight.w900,
                            color:      AppColor.primary)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Cash ──────────────────────────────────────────
              _SimplePayField(
                label:      'Cash (Rs)',
                icon:       Icons.money_rounded,
                controller: _cashCtrl,
                onChanged:  (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // ── Card ──────────────────────────────────────────
              _SimplePayField(
                label:      'Card (Rs)',
                icon:       Icons.credit_card_rounded,
                controller: _cardCtrl,
                onChanged:  (_) => setState(() {}),
              ),

              // ── Credit — sirf customer hone par ───────────────
              if (_hasCustomer) ...[
                const SizedBox(height: 12),
                _SimplePayField(
                  label:      'Credit / Udhar (Rs)',
                  icon:       Icons.account_balance_wallet_outlined,
                  color:      AppColor.warning,
                  controller: _creditCtrl,
                  onChanged:  (_) => setState(() {}),
                ),
              ],

              const SizedBox(height: 16),

              // ── Remaining / Change ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _remaining > 0.01
                        ? 'Remaining:'
                        : _remaining < -0.01
                        ? 'Change:'
                        : '✓ Payment Complete',
                    style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      remainingColor),
                  ),
                  if (_remaining.abs() > 0.01)
                    Text(
                      'Rs ${_remaining.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.w800,
                          color:      remainingColor),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Print Receipt Checkbox ────────────────────────
              Container(
                decoration: BoxDecoration(
                  color:        AppColor.grey100,
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: AppColor.grey200),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value:       _printReceipt,
                      activeColor: AppColor.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) =>
                          setState(() => _printReceipt = v ?? true),
                    ),
                    const Icon(Icons.print_outlined,
                        size: 16, color: AppColor.textSecondary),
                    const SizedBox(width: 6),
                    const Text(
                      'Print Receipt (Thermal)',
                      style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w500,
                          color:      AppColor.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Buttons ───────────────────────────────────────
              Row(children: [
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _cashCtrl.clear();
                      _cardCtrl.clear();
                      _creditCtrl.clear();
                    }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.textSecondary,
                      side: const BorderSide(color: AppColor.grey300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isValid && !isSaving) ? _confirm : null,
                    icon: isSaving
                        ? const SizedBox(
                        width:  16,
                        height: 16,
                        child:  CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save Invoice',
                      style: const TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:         AppColor.primary,
                      foregroundColor:         Colors.white,
                      disabledBackgroundColor: AppColor.grey300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Simple Pay Field ───────────────────────────────────────────────────────────
class _SimplePayField extends StatelessWidget {
  final String                label;
  final IconData              icon;
  final Color                 color;
  final TextEditingController controller;
  final ValueChanged<String>  onChanged;

  const _SimplePayField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.onChanged,
    this.color = AppColor.primary,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller:   controller,
    onChanged:    onChanged,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
    ],
    style: TextStyle(
        fontSize:   16,
        fontWeight: FontWeight.w700,
        color:      color),
    cursorHeight: 14,
    decoration: InputDecoration(
      labelText:  label,
      labelStyle: TextStyle(fontSize: 13, color: color),
      prefixIcon: Icon(icon, size: 20, color: color),
      filled:     true,
      fillColor:  color.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide(color: color.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide(color: color.withOpacity(0.25))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide(color: color, width: 1.5)),
    ),
  );
}