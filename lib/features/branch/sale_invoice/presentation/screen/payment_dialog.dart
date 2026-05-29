import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../../../../core/service/print/print_service.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';

String _fmtNum(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

bool _dialogOpen = false;


Future<bool?> showPaymentDialog(BuildContext context, WidgetRef ref) async {
  if (_dialogOpen) return null;          // ← guard
  _dialogOpen = true;
  try {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PaymentDialog(),
    );
  } finally {
    _dialogOpen = false;                 // ← hamesha reset
  }
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
  final _cardFocus  = FocusNode();

  bool   _printReceipt = false;
  bool   _saving       = false;
  bool   _adjusting    = false;
  String _prevCash     = '';
  String _prevCard     = '';

  double get _cash      => double.tryParse(_cashCtrl.text.trim()) ?? 0;
  double get _card      => double.tryParse(_cardCtrl.text.trim()) ?? 0;
  double get _totalPaid => _cash + _card;

  double get _grandTotal      => ref.read(saleInvoiceProvider).grandTotal;
  bool   get _hasCustomer     => ref.read(saleInvoiceProvider).selectedCustomer != null;
  double get _existingBalance => ref.read(saleInvoiceProvider).selectedCustomer?.balance ?? 0.0;
  double get _totalDue        => _existingBalance + _grandTotal;

  double get _cashForInvoice => _cash.clamp(0.0, _grandTotal);
  double get _cardForInvoice =>
      _card.clamp(0.0, max(0.0, _grandTotal - _cashForInvoice));
  double get _creditForInvoice =>
      (_grandTotal - _cashForInvoice - _cardForInvoice).clamp(0.0, _grandTotal);

  double get _extraPayment {
    if (!_hasCustomer) return 0.0;
    return (_totalPaid - _grandTotal).clamp(0.0, _existingBalance);
  }

  double get _returnAmount {
    if (_hasCustomer) return (_totalPaid - _totalDue).clamp(0.0, double.infinity);
    return (_totalPaid - _grandTotal).clamp(0.0, double.infinity);
  }

  bool get _isReturnMode => _returnAmount > 0.01;

  // New balance after payment
  double get _newBalance =>
      (_existingBalance + _creditForInvoice - _extraPayment)
          .clamp(0.0, double.infinity);

  bool get _isValid {
    if (_hasCustomer) return true;
    return _totalPaid >= _grandTotal - 0.01;
  }

  @override
  void initState() {
    super.initState();
    _cashCtrl.addListener(_onChanged);
    _cardCtrl.addListener(_onChanged);
    HardwareKeyboard.instance.addHandler(_handleKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initFields();
    });
  }

  void _initFields() {
    _adjusting = true;
    if (_hasCustomer) {
      _cashCtrl.text   = '0';
      _creditCtrl.text = _fmtNum(_grandTotal);
    } else {
      _cashCtrl.text   = _fmtNum(_grandTotal);
      _creditCtrl.text = '0';
    }
    _prevCash  = _cashCtrl.text;
    _prevCard  = '';
    _adjusting = false;
    _cashFocus.requestFocus();
    _selectAll(_cashCtrl);
    setState(() {});
  }

  void _selectAll(TextEditingController c) =>
      c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);

  void _onChanged() {
    if (_adjusting) return;
    final cashText = _cashCtrl.text.trim();
    final cardText = _cardCtrl.text.trim();
    if (cashText == _prevCash && cardText == _prevCard) return;
    _prevCash = cashText;
    _prevCard = cardText;
    if (_hasCustomer) {
      _adjusting = true;
      _creditCtrl.text = _fmtNum(_creditForInvoice);
      _adjusting = false;
    }
    setState(() {});
  }

  bool _handleKey(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final ctrl = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyS) { _confirm(); return true; }
    if (event.logicalKey == LogicalKeyboardKey.tab) { if (_cashFocus.hasFocus) _cardFocus.requestFocus(); return true; }
    if (event.logicalKey == LogicalKeyboardKey.escape) { Navigator.of(context).pop(false); return true; }
    return false;
  }

  Future<void> _confirm() async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);

    // ✅ saveInvoice() se PEHLE — in getters ko baad mein call mat karo
    final capturedHasCustomer     = _hasCustomer;
    final capturedReturnAmount    = _isReturnMode ? _returnAmount    : null;
    final capturedExistingBalance = _hasCustomer  ? _existingBalance : null;
    final capturedTotalPaid       = _hasCustomer  ? _totalPaid       : null;
    final capturedNewBalance      = _hasCustomer  ? _newBalance      : null;

    try {
      final state    = ref.read(saleInvoiceProvider);
      final notifier = ref.read(saleInvoiceProvider.notifier);

      final customer    = state.selectedCustomer;
      final invoiceNo   = state.invoiceNo;
      final hasCustomer = customer != null;
      final extraPay    = _extraPayment;
      final payments    = <PaymentEntry>[];

      if (hasCustomer) {
        if (_cashForInvoice > 0) {
          payments.add(PaymentEntry(method: 'cash', amount: _cashForInvoice));
          await notifier.updatePayment('cash', _cashForInvoice);
        }
        if (_cardForInvoice > 0) {
          payments.add(PaymentEntry(method: 'card', amount: _cardForInvoice));
          await notifier.updatePayment('card', _cardForInvoice);
        }
        if (_creditForInvoice > 0) {
          payments.add(PaymentEntry(method: 'credit', amount: _creditForInvoice));
          await notifier.updatePayment('credit', _creditForInvoice);
        }
      } else {
        final cashAmt = _cash.clamp(0.0, _grandTotal);
        if (cashAmt > 0) {
          payments.add(PaymentEntry(method: 'cash', amount: cashAmt));
          await notifier.updatePayment('cash', cashAmt);
        }
        if (_card > 0) {
          payments.add(PaymentEntry(method: 'card', amount: _card));
          await notifier.updatePayment('card', _card);
        }
      }

      final success = await notifier.saveInvoice();
      if (!mounted) return;

      if (success) {
        if (hasCustomer && extraPay > 0.01 && customer != null) {
          await notifier.applyExtraCustomerPayment(
            customerId:   customer.id,
            customerName: customer.name,
            invoiceNo:    invoiceNo,
            extraPayment: extraPay,
          );
        }
        _showSnack('Invoice saved successfully!', AppColor.success);
        if (_printReceipt) {
          await _print(
            state,
            payments,
            returnAmount:    capturedReturnAmount,
            previousBalance: capturedExistingBalance,
            paidAmount:      capturedTotalPaid,
            currentBalance:  capturedNewBalance,
            hasCustomer:     capturedHasCustomer,   // ✅ captured
          );
        }
        Navigator.of(context).pop(true);
      } else {
        _showSnack('Failed to save invoice', AppColor.error);
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', AppColor.error);
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg, style: const TextStyle(fontSize: 14)),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _print(dynamic state, List<PaymentEntry> payments, {double? returnAmount, double? previousBalance, double? paidAmount, double? currentBalance, bool    hasCustomer = false,}) async {
    try {
      final auth = ref.read(authProvider);

      debugPrint('═══════════════ PRINT DEBUG ═══════════════');
      debugPrint('🧾 Invoice   : ${state.invoiceNo}');
      debugPrint('👤 Customer  : ${state.selectedCustomer?.name ?? 'WALK IN'}');
      debugPrint('💵 GrandTotal: ${state.grandTotal}');
      debugPrint('👨‍💼 Cashier   : ${auth.user?.fullName ?? 'Unknown'}');
      debugPrint('─── Payments ───────────────────────────────');
      for (final p in payments) {
        debugPrint('   💳 ${p.method.toUpperCase()}: ${p.amount}');
      }
      debugPrint('─── Captured Values ────────────────────────');
      debugPrint('   📊 hasCustomer   : $hasCustomer');
      debugPrint('   💱 returnAmount  : $returnAmount');
      debugPrint('   📉 prevBalance   : $previousBalance');
      debugPrint('   💸 paidAmount    : $paidAmount');
      debugPrint('   📈 currentBalance: $currentBalance');
      debugPrint('═══════════════════════════════════════════');

      await ThermalPrintService.printSaleInvoice(
        storeName:       'JAN GHANI',
        invoiceNo:       state.invoiceNo,
        date:            state.date,
        customerName:    state.selectedCustomer?.name,
        customerId:      state.selectedCustomer?.id,  // ✅ yeh add karo
        items:           state.cartItems,
        totalAmount:     state.totalBeforeTax,
        totalDiscount:   state.totalDiscount,
        grandTotal:      state.grandTotal,
        payments:        payments,
        cashierName:     auth.user?.fullName ?? 'Unknown',
        returnAmount:    returnAmount,
        previousBalance: hasCustomer ? previousBalance : null,
        paidAmount:      hasCustomer ? paidAmount      : null,
        currentBalance:  hasCustomer ? currentBalance  : null,
      );

      debugPrint('✅ Print successful');
    } catch (e) {
      debugPrint('❌ Print error: $e');
      if (mounted) _showSnack('Print failed but invoice saved', AppColor.warning);
    }
  }

  void _resetFields() {
    _adjusting = true;
    _cardCtrl.clear();
    if (_hasCustomer) {
      _cashCtrl.text   = '0';
      _creditCtrl.text = _fmtNum(_grandTotal);
    } else {
      _cashCtrl.text   = _fmtNum(_grandTotal);
      _creditCtrl.text = '0';
    }
    _prevCash  = _cashCtrl.text;
    _prevCard  = '';
    _adjusting = false;
    setState(() {});
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _cashCtrl.dispose(); _cardCtrl.dispose(); _creditCtrl.dispose();
    _cashFocus.dispose(); _cardFocus.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(saleInvoiceProvider);
    final isSaving = state.isSaving || _saving;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              _buildHeader(),
              const SizedBox(height: 20),

              // ── Customer Name (read-only) ────────────────────
              if (_hasCustomer) ...[
                CustomerForm(
                  label:    'Customer Name',
                  value:    state.selectedCustomer?.name ?? '',
                  icon:     Icons.person_outline_rounded,
                ),
                const SizedBox(height: 10),

                // ── Previous Balance ────────────────────────────
                _InfoField(
                  label:      'Previous Balance (Rs)',
                  value:      _fmtNum(_existingBalance),
                  icon:       Icons.history_rounded,
                  valueColor: _existingBalance > 0 ? Colors.red.shade700 : Colors.green.shade700,
                ),
                const SizedBox(height: 10),
              ],

              // ── Total Amount ─────────────────────────────────
              _InfoField(
                label:      'Total Amount (Rs)',
                value:      _fmtNum(_grandTotal),
                icon:       Icons.receipt_long_rounded,
                valueColor: Colors.black,
                bold:       true,
                fillColor:  AppColor.primary.withOpacity(0.06),
              ),
              const SizedBox(height: 10),

              // ── Cash ─────────────────────────────────────────
              _PaymentField(
                label:      'Cash Payment (Rs)',
                icon:       Icons.money_rounded,
                controller: _cashCtrl,
                focusNode:  _cashFocus,
              ),
              const SizedBox(height: 10),

              // ── Card ─────────────────────────────────────────
              _PaymentField(
                label:      'Card Payment (Rs)',
                icon:       Icons.credit_card_rounded,
                controller: _cardCtrl,
                focusNode:  _cardFocus,
              ),
              const SizedBox(height: 10),

              // ── Credit ───────────────────────────────────────
              if (_hasCustomer) ...[
                _PaymentField(
                  label:      'Credit (Rs)',
                  icon:       Icons.account_balance_wallet_outlined,
                  controller: _creditCtrl,
                  readOnly:   true,
                ),
                const SizedBox(height: 10),
              ],

              // ── Due Amount (sirf jab credit > 0) ─────────────
              if (_hasCustomer && (_creditForInvoice > 0.01 || _totalPaid > 0)) ...[
                _InfoField(
                  label:      'Due Amount (Rs)',
                  value:      _fmtNum(_newBalance),
                  icon:       Icons.account_balance_wallet_outlined,
                  valueColor: _newBalance > 0.01
                      ? Colors.orange.shade800
                      : Colors.green.shade700,      // ✅ balance zero ho to green
                  bold:       true,
                  fillColor:  _newBalance > 0.01
                      ? Colors.orange.withOpacity(0.06)
                      : Colors.green.withOpacity(0.06),
                  borderColor: _newBalance > 0.01
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(height: 10),
              ],

              // ── Return tile ──────────────────────────────────
              if (_isReturnMode) ...[
                _statusTile(
                  color:  AppColor.success,
                  icon:   Icons.keyboard_return_rounded,
                  label:  'Return Amount',
                  amount: _returnAmount,
                ),
                const SizedBox(height: 10),
              ],

              // ── Walk-in remaining ─────────────────────────────
              if (!_hasCustomer && !_isReturnMode) ...[
                _buildWalkInStatus(),
                const SizedBox(height: 10),
              ],

              // ── Print Option ─────────────────────────────────
              _buildPrintOption(),
              const SizedBox(height: 20),

              // ── Buttons ──────────────────────────────────────
              _buildButtons(isSaving),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    children: [
      Container(
        padding:    const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:        AppColor.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.payments_outlined, color: AppColor.primary, size: 22),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Text('Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      Container(
        padding:    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        AppColor.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Ctrl+S',
            style: TextStyle(fontSize: 11, color: AppColor.primary, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => Navigator.of(context).pop(false),
        child: Container(
          padding:    const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColor.grey100, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.close_rounded, size: 18, color: AppColor.textSecondary),
        ),
      ),
    ],
  );

  Widget _buildWalkInStatus() {
    final rem = _grandTotal - _totalPaid;
    if (rem.abs() < 0.01) {
      return _statusTile(
        color:  AppColor.success,
        icon:   Icons.check_circle_outline_rounded,
        label:  'Payment Complete',
      );
    }
    return _statusTile(
      color:  AppColor.error,
      icon:   Icons.warning_amber_rounded,
      label:  'Remaining:',
      amount: rem,
    );
  }

  Widget _statusTile({
    required Color   color,
    required IconData icon,
    required String  label,
    double?          amount,
  }) =>
      Container(
        padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ]),
            if (amount != null)
              Text('Rs ${_fmtNum(amount)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );

  Widget _buildPrintOption() => Container(
    decoration: BoxDecoration(
      color:        AppColor.grey100,
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: AppColor.grey200),
    ),
    child: Row(children: [
      Checkbox(
        value:       _printReceipt,
        activeColor: AppColor.primary,
        shape:       RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        onChanged:   (v) => setState(() => _printReceipt = v ?? false),
      ),
      const Icon(Icons.print_outlined, size: 18, color: AppColor.textSecondary),
      const SizedBox(width: 8),
      const Text('Print Thermal Receipt',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColor.textSecondary)),
    ]),
  );

  Widget _buildButtons(bool isSaving) => Row(children: [
    SizedBox(
      width: 100,
      child: OutlinedButton.icon(
        onPressed: _resetFields,
        icon:      const Icon(Icons.refresh_rounded, size: 18),
        label:     const Text('Reset'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.textSecondary,
          side:            const BorderSide(color: AppColor.grey300),
          padding:         const EdgeInsets.symmetric(vertical: 12),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: ElevatedButton.icon(
        onPressed: (_isValid && !isSaving) ? _confirm : null,
        icon: isSaving
            ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check_rounded, size: 18),
        label: Text(
          isSaving ? 'Saving...' : 'Save Invoice  (Ctrl+S)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:         AppColor.primary,
          foregroundColor:         Colors.white,
          disabledBackgroundColor: AppColor.grey300,
          padding:                 const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    ),
  ]);
}

// ── Read-only info field ──────────────────────────────────────────────────────
class _InfoField extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   valueColor;
  final bool    bold;
  final Color?  fillColor;
  final Color?  borderColor;

  const _InfoField({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor  = Colors.black,
    this.bold        = false,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bc = borderColor ?? AppColor.primary;
    final fc = fillColor   ?? AppColor.primary.withOpacity(0.04);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: fc,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bc.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColor.primary),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color:      AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize:   16,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                color:      valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Editable payment field ────────────────────────────────────────────────────
class _PaymentField extends StatelessWidget {
  final String                label;
  final IconData              icon;
  final TextEditingController controller;
  final String?               hint;
  final FocusNode?            focusNode;
  final bool                  readOnly;

  const _PaymentField({
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.focusNode,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller:     controller,
    focusNode:      focusNode,
    readOnly:       readOnly,
    keyboardType:   const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    style: TextStyle(
      fontSize:   16,
      fontWeight: FontWeight.w700,
      color:      readOnly ? Colors.black54 : Colors.black,
    ),
    decoration: InputDecoration(
      labelText:  label,
      hintText:   hint ?? '0',
      labelStyle: TextStyle(
        fontSize:   12,
        color:      AppColor.primary,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
      prefixIcon: Icon(icon, size: 20, color: AppColor.primary),
      suffixIcon: readOnly
          ? Icon(Icons.lock_outline_rounded, size: 16, color: AppColor.primary.withOpacity(0.4))
          : null,
      filled:          true,
      fillColor:       readOnly
          ? AppColor.primary.withOpacity(0.03)
          : AppColor.primary.withOpacity(0.05),
      contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   BorderSide(color: AppColor.primary.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   BorderSide(color: AppColor.primary.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   BorderSide(color: AppColor.primary, width: 1.5),
      ),
    ),
  );
}

class CustomerForm extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   valueColor;
  final bool    bold;
  final Color?  fillColor;
  final Color?  borderColor;

  const CustomerForm({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor  = Colors.black,
    this.bold        = false,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bc = borderColor ?? AppColor.primary;
    final fc = fillColor   ?? AppColor.primary.withOpacity(0.04);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: fc,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bc.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ← add
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColor.primary),
              const SizedBox(width: 12),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w500,
                  color:      AppColor.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // ← add

          Text(
            value,
            style: TextStyle(
              fontSize:   16,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color:      valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
