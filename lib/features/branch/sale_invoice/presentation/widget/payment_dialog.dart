// lib/features/branch/sale_invoice/presentation/widget/payment_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/service/print/print_service.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';

String _fmtNum(double v) =>
    v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

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
  final _cashFocus  = FocusNode();

  bool _printReceipt = false;
  bool _saving       = false;

  // ✅ FIX 1: Previous text track karo taake selection change pe
  // listener fire na kare (sirf actual text change pe recalculate ho)
  String _prevCardText   = '';
  String _prevCreditText = '';

  double get _cash   => double.tryParse(_cashCtrl.text.trim()) ?? 0;
  double get _card   => double.tryParse(_cardCtrl.text.trim()) ?? 0;
  double get _credit => double.tryParse(_creditCtrl.text.trim()) ?? 0;
  double get _paid   => _cash + _card + _credit;

  double get _grandTotal  => ref.read(saleInvoiceProvider).grandTotal;
  double get _remaining   => _grandTotal - _paid;
  bool   get _isValid     => _remaining.abs() < 0.01;
  bool   get _hasCustomer => ref.read(saleInvoiceProvider).selectedCustomer != null;

  @override
  void initState() {
    super.initState();

    _cardCtrl.addListener(_autoAdjustCash);
    _creditCtrl.addListener(_autoAdjustCash);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Cash field initialize
      _cashCtrl.text = _fmtNum(_grandTotal);
      _cashFocus.requestFocus();
      _cashCtrl.selection = TextSelection(
        baseOffset: 0, extentOffset: _cashCtrl.text.length,
      );
      setState(() {});

      HardwareKeyboard.instance.addHandler(_handleKey);
    });
  }

  bool _handleKey(KeyEvent event) {
    if (!mounted) return false;
    if (event is! KeyDownEvent) return false;

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrl = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);

    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      _confirm();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return true;
    }
    return false;
  }

  void _autoAdjustCash() {
    // ✅ FIX 1: Sirf tab recalculate karo jab text WAQAI change hua ho
    // Selection change (focus aana) pe listener fire hota tha — yeh isko rokta hai
    final newCardText   = _cardCtrl.text.trim();
    final newCreditText = _creditCtrl.text.trim();

    if (newCardText == _prevCardText && newCreditText == _prevCreditText) return;

    _prevCardText   = newCardText;
    _prevCreditText = newCreditText;

    final card      = double.tryParse(newCardText) ?? 0;
    final credit    = double.tryParse(newCreditText) ?? 0;
    final remaining = _grandTotal - card - credit;
    final newCash   = remaining > 0 ? remaining : 0.0;
    final newText   = newCash == 0 ? '0' : _fmtNum(newCash);
    if (_cashCtrl.text != newText) _cashCtrl.text = newText;
    setState(() {});
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _cashCtrl.dispose();
    _cardCtrl.dispose();
    _creditCtrl.dispose();
    _cashFocus.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);

    final state         = ref.read(saleInvoiceProvider);
    final invoiceNo     = state.invoiceNo;
    final date          = state.date;
    final customerName  = state.selectedCustomer?.name;
    final items         = [...state.cartItems];
    final totalAmount   = state.totalBeforeTax;
    final totalDiscount = state.totalDiscount;
    final grandTotal    = state.grandTotal;
    final payments      = <PaymentEntry>[
      if (_cash   > 0) PaymentEntry(method: 'cash',   amount: _cash),
      if (_card   > 0) PaymentEntry(method: 'card',   amount: _card),
      if (_hasCustomer && _credit > 0)
        PaymentEntry(method: 'credit', amount: _credit),
    ];

    final notifier = ref.read(saleInvoiceProvider.notifier);
    await notifier.updatePayment('cash',   _cash);
    await notifier.updatePayment('card',   _card);
    if (_hasCustomer) await notifier.updatePayment('credit', _credit);

    // ✅ FIX 2: Navigator aur ScaffoldMessenger ko await se PEHLE capture karo
    // Async gap ke baad context stale ho sakta hai — yeh Flutter ka standard pattern hai
    final navigator        = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final ok = await notifier.saveInvoice();

    if (!mounted) return;

    // ✅ Ab captured navigator use karo — context ki zaroorat nahi
    navigator.pop();

    setState(() => _saving = false);

    if (ok) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content:         const Text('Invoice saved!',
            style: TextStyle(fontSize: 14)),
        backgroundColor: AppColor.success,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
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
    final isSaving   = state.isSaving || _saving;
    final rc         = _remaining > 0.01 ? AppColor.error : AppColor.success;

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
              // ── Header ──────────────────────────────────────
              Row(children: [
                const Icon(Icons.payments_outlined,
                    color: AppColor.primary, size: 22),
                const SizedBox(width: 10),
                const Text('Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color:        AppColor.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Ctrl+S to Save',
                      style: TextStyle(
                          fontSize: 10, color: AppColor.primary,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: AppColor.textSecondary),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Grand Total ──────────────────────────────────
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:        AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: AppColor.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColor.textSecondary)),
                    Text('Rs ${_fmtNum(grandTotal)}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900,
                            color: AppColor.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Cash ─────────────────────────────────────────
              _SmartPayField(
                label:      'Cash (Rs)',
                icon:       Icons.money_rounded,
                controller: _cashCtrl,
                focusNode:  _cashFocus,
                hint:       'Auto-calculated',
                onChanged:  (_) => setState(() {}),
              ),
              const SizedBox(height: 10),

              // ── Card ─────────────────────────────────────────
              _SmartPayField(
                label:      'Card (Rs)',
                icon:       Icons.credit_card_rounded,
                controller: _cardCtrl,
                hint:       '0',
                onChanged:  (_) {},
              ),
              const SizedBox(height: 10),

              // ── Credit ───────────────────────────────────────
              if (_hasCustomer) ...[
                _SmartPayField(
                  label:      'Credit / Udhar (Rs)',
                  icon:       Icons.account_balance_wallet_outlined,
                  color:      AppColor.warning,
                  controller: _creditCtrl,
                  hint:       '0',
                  onChanged:  (_) {},
                ),
                const SizedBox(height: 10),
              ],

              // ── Remaining / Change ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _remaining > 0.01
                        ? 'Remaining:'
                        : _remaining < -0.01
                        ? 'Change (wapas karo):'
                        : '✓ Payment Complete',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: rc),
                  ),
                  if (_remaining.abs() > 0.01)
                    Text('Rs ${_fmtNum(_remaining.abs())}',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: rc)),
                ],
              ),
              const SizedBox(height: 10),

              // ── Print Receipt ────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color:        AppColor.grey100,
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: AppColor.grey200),
                ),
                child: Row(children: [
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
                  const Text('Print Receipt (Thermal)', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: AppColor.textSecondary)),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Buttons ──────────────────────────────────────
              Row(children: [
                SizedBox(
                  width: 80,
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _cardCtrl.clear();
                      _creditCtrl.clear();
                      _prevCardText   = '';
                      _prevCreditText = '';
                      _cashCtrl.text = _fmtNum(_grandTotal);
                    }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.textSecondary,
                      side:    const BorderSide(color: AppColor.grey300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape:   RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isValid && !isSaving) ? _confirm : null,
                    icon: isSaving ?
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) :
                    const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save Invoice  (Ctrl+S)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColor.grey300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

class _SmartPayField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color                 color;
  final TextEditingController controller;
  final String?               hint;
  final FocusNode?            focusNode;
  final ValueChanged<String>  onChanged;

  const _SmartPayField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.onChanged,
    this.color     = AppColor.primary,
    this.hint,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    onChanged: onChanged,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
    ],
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
    cursorHeight: 14,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(fontSize: 13, color: color),
      hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
      prefixIcon: Icon(icon, size: 20, color: color),
      filled: true,
      fillColor: color.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide:   BorderSide(color: color.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide:   BorderSide(color: color.withOpacity(0.25))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide:   BorderSide(color: color, width: 1.5)),
    ),
  );
}