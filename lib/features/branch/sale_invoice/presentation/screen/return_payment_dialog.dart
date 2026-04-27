// lib/features/branch/sale_invoice/presentation/screen/return_payment_dialog.dart
// ── Smart cash auto-fill + Ctrl+S save ──

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/service/print/print_service.dart';
import '../../data/model/sale_invoice_model.dart' show PaymentEntry;
import '../provider/sale_return_provider.dart';

// ── Smart format: whole number → integer, decimal → 2 places ──────
String _fmtNum(double v) =>
    v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

Future<void> showReturnPaymentDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context:            context,
    barrierDismissible: false,
    builder:            (_) => const _ReturnPaymentDialog(),
  );
}

class _ReturnPaymentDialog extends ConsumerStatefulWidget {
  const _ReturnPaymentDialog();
  @override
  ConsumerState<_ReturnPaymentDialog> createState() => _ReturnPaymentDialogState();
}

class _ReturnPaymentDialogState extends ConsumerState<_ReturnPaymentDialog> {
  final _cashCtrl   = TextEditingController();
  final _cardCtrl   = TextEditingController();
  final _creditCtrl = TextEditingController();
  final _cashFocus  = FocusNode();

  bool _printReceipt = true;
  bool _saving       = false;

  // ✅ FIX 2: Previous text track karo — selection change pe
  // listener fire hota tha aur cash recalculate ho ke grandTotal ban jaata tha
  String _prevCardText   = '';
  String _prevCreditText = '';

  double get _cash   => double.tryParse(_cashCtrl.text.trim())   ?? 0;
  double get _card   => double.tryParse(_cardCtrl.text.trim())   ?? 0;
  double get _credit => double.tryParse(_creditCtrl.text.trim()) ?? 0;
  double get _paid   => _cash + _card + _credit;

  double get _grandTotal  => ref.read(saleReturnProvider).grandTotal;
  double get _remaining   => _grandTotal - _paid;
  bool   get _isValid     => _remaining.abs() < 0.01;
  bool   get _hasCustomer =>
      ref.read(saleReturnProvider).selectedCustomer != null;

  @override
  void initState() {
    super.initState();

    _cardCtrl.addListener(_autoAdjustCash);
    _creditCtrl.addListener(_autoAdjustCash);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final gt = _grandTotal;
      _cashCtrl.text = _fmtNum(gt);
      _cashFocus.requestFocus();
      _cashCtrl.selection = TextSelection(
        baseOffset: 0, extentOffset: _cashCtrl.text.length,
      );
      setState(() {});

      // ✅ FIX 1: HardwareKeyboard handler postFrameCallback ke BAAD add karo
      // LIFO order mein fire hota hai — return true se parent screen tak event
      // nahi jaata, isliye saveReturn() SIRF EK BAAR call hogi
      // (KeyboardListener event consume nahi karta tha — woh double-save ka cause tha)
      HardwareKeyboard.instance.addHandler(_handleKey);
    });
  }

  // ✅ FIX 1: Yeh handler event consume karta hai (return true)
  // Parent screen ka Ctrl+S handler is ke baad fire nahi hoga
  bool _handleKey(KeyEvent event) {
    if (!mounted) return false;
    if (event is! KeyDownEvent) return false;

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrl = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);

    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      _confirm();
      return true; // ← event consume — parent screen tak nahi jaayega
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return true;
    }
    return false;
  }

  // ✅ FIX 2: Sirf tab recalculate karo jab text WAQAI change hua ho
  // TextEditingController listener selection change pe bhi fire hota tha
  // (jab card field pe focus aata) — yeh isko rokta hai
  void _autoAdjustCash() {
    final newCardText   = _cardCtrl.text.trim();
    final newCreditText = _creditCtrl.text.trim();

    if (newCardText == _prevCardText && newCreditText == _prevCreditText) return;

    _prevCardText   = newCardText;
    _prevCreditText = newCreditText;

    final card      = double.tryParse(newCardText)   ?? 0;
    final credit    = double.tryParse(newCreditText) ?? 0;
    final remaining = _grandTotal - card - credit;
    final newCash   = remaining > 0 ? remaining : 0.0;
    final newText   = newCash == 0 ? '0' : _fmtNum(newCash);
    if (_cashCtrl.text != newText) _cashCtrl.text = newText;
    setState(() {});
  }

  @override
  void dispose() {
    // ✅ FIX 1: Handler zaroor remove karo warna memory leak hoga
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

    final state         = ref.read(saleReturnProvider);
    final returnNo      = state.returnNo;
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

    final notifier = ref.read(saleReturnProvider.notifier);
    notifier.updatePayment('cash',   _cash);
    notifier.updatePayment('card',   _card);
    if (_hasCustomer) notifier.updatePayment('credit', _credit);

    // ✅ FIX 3: Navigator aur ScaffoldMessenger ko await se PEHLE capture karo
    // Async gap ke baad context stale ho sakta hai — yeh Flutter ka standard pattern hai
    final navigator         = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final ok = await notifier.saveReturn();
    if (!mounted) return;

    // ✅ Captured navigator use karo — dialog reliably close hoga
    navigator.pop();
    setState(() => _saving = false);

    if (ok) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content:         const Text('Sale Return saved!',
            style: TextStyle(fontSize: 14)),
        backgroundColor: AppColor.success,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (_printReceipt) {
        final dominant = payments.isEmpty
            ? 'cash'
            : payments.reduce((a, b) => a.amount >= b.amount ? a : b).method;
        await ThermalPrintService.printSaleReturn(
          storeName:     'Jan Ghani Store',
          returnNo:      returnNo,
          date:          date,
          customerName:  customerName,
          items:         items,
          totalAmount:   totalAmount,
          totalDiscount: totalDiscount,
          grandTotal:    grandTotal,
          payments:      payments,
          refundType:    dominant,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state      = ref.watch(saleReturnProvider);
    final grandTotal = state.grandTotal;
    final isSaving   = state.isSaving || _saving;
    final rc         = _remaining > 0.01 ? AppColor.error : AppColor.success;

    // ✅ FIX 1: KeyboardListener bilkul nahi — HardwareKeyboard handler use kar rahe hain
    // KeyboardListener events consume nahi karta tha jis ki wajah se double-save hoti thi
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(children: [
                const Icon(Icons.assignment_return_outlined,
                    color: AppColor.error, size: 22),
                const SizedBox(width: 10),
                const Text('Refund',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color:        AppColor.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Ctrl+S to Save',
                      style: TextStyle(
                          fontSize: 10, color: AppColor.error,
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

              // ── Refund Amount ────────────────────────────────
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:        AppColor.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: AppColor.error.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Refund Amount',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColor.textSecondary)),
                    Text('Rs ${_fmtNum(grandTotal)}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900,
                            color: AppColor.error)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _ReturnPayField(
                label:      'Cash (Rs)',
                icon:       Icons.money_rounded,
                color:      AppColor.primary,
                controller: _cashCtrl,
                focusNode:  _cashFocus,
                onChanged:  (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _ReturnPayField(
                label:      'Card (Rs)',
                icon:       Icons.credit_card_rounded,
                color:      AppColor.primary,
                controller: _cardCtrl,
                onChanged:  (_) {},
              ),
              if (_hasCustomer) ...[
                const SizedBox(height: 10),
                _ReturnPayField(
                  label:      'Credit / Udhar (Rs)',
                  icon:       Icons.account_balance_wallet_outlined,
                  color:      AppColor.warning,
                  controller: _creditCtrl,
                  onChanged:  (_) {},
                ),
              ],
              const SizedBox(height: 14),

              // ── Remaining / Change ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _remaining > 0.01
                        ? 'Remaining:'
                        : _remaining < -0.01
                        ? 'Change (wapas karo):'
                        : '✓ Refund Complete',
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

              Container(
                decoration: BoxDecoration(
                  color:        AppColor.grey100,
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: AppColor.grey200),
                ),
                child: Row(children: [
                  Checkbox(
                    value:       _printReceipt,
                    activeColor: AppColor.error,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _printReceipt = v ?? true),
                  ),
                  const Icon(Icons.print_outlined,
                      size: 16, color: AppColor.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Print Return Receipt (Thermal)',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: AppColor.textSecondary)),
                ]),
              ),
              const SizedBox(height: 14),

              Row(children: [
                SizedBox(
                  width: 80,
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _cardCtrl.clear();
                      _creditCtrl.clear();
                      // ✅ FIX 2: Reset pe prev tracking bhi clear karo
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
                    icon: isSaving
                        ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.assignment_return_outlined, size: 18),
                    label: Text(
                      isSaving ? 'Saving...' : 'Save Return  (Ctrl+S)',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:         AppColor.error,
                      foregroundColor:         Colors.white,
                      disabledBackgroundColor: AppColor.grey300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape:   RoundedRectangleBorder(
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

class _ReturnPayField extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;

  const _ReturnPayField({
    required this.label, required this.icon, required this.color,
    required this.controller, required this.onChanged, this.focusNode,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, focusNode: focusNode, onChanged: onChanged,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
    cursorHeight: 14,
    decoration: InputDecoration(
      labelText: label, labelStyle: TextStyle(fontSize: 13, color: color),
      prefixIcon: Icon(icon, size: 20, color: color),
      filled: true, fillColor: color.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border:         OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color.withOpacity(0.3))),
      enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color.withOpacity(0.25))),
      focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: 1.5)),
    ),
  );
}