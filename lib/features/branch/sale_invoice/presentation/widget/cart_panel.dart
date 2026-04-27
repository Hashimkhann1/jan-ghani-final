// lib/features/branch/sale_invoice/presentation/widget/cart_panel.dart
// ── MODIFIED: Hold button + F2 Pay Now trigger + shortcut hints ──

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/features/branch/customer/data/model/customer_model.dart';
import 'package:jan_ghani_final/features/branch/customer/presentation/provider/customer_provider.dart';
import 'package:jan_ghani_final/features/branch/sale_invoice/presentation/widget/sale_type_dropdown.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/sale_invoice_model.dart';
import '../../data/model/sale_return_model.dart';
import '../provider/sale_invoice_provider.dart';
import '../provider/sale_return_provider.dart';
import '../screen/sale_invoice_screen.dart' show payNowTriggerProvider, posCustomerFocusProvider, customerDropdownKeyProvider, saleTypeFocusProvider;
import '../screen/return_payment_dialog.dart';
import 'cart_row_widget.dart';
import 'cart_summary_widget.dart';
import 'cart_table_header_widget.dart';
import 'disable_text_field_widget.dart';
import 'held_invoices_sheet.dart';
import '../widget/payment_dialog.dart';

String _fmtD(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(saleInvoiceProvider);
    final isReturn = state.saleType == SaleType.saleReturn;

    // ── F2 shortcut — Pay Now trigger ─────────────────────────
    ref.listen<bool>(payNowTriggerProvider, (_, trigger) {
      if (trigger) {
        ref.read(payNowTriggerProvider.notifier).state = false;
        if (state.cartItems.isNotEmpty && !isReturn) {
          showPaymentDialog(context, ref);
        }
      }
    });

    // ── Error listener ────────────────────────────────────────
    ref.listen<SaleInvoiceState>(saleInvoiceProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!,
              style: const TextStyle(fontSize: 14)),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label:     'OK',
            textColor: Colors.white,
            onPressed: () =>
                ref.read(saleInvoiceProvider.notifier).clearError(),
          ),
        ));
      }
    });

    ref.listen<SaleReturnState>(saleReturnProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!,
              style: const TextStyle(fontSize: 14)),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label:     'OK',
            textColor: Colors.white,
            onPressed: () =>
                ref.read(saleReturnProvider.notifier).clearError(),
          ),
        ));
      }
    });

    return Container(
      color: AppColor.background,
      child: Column(children: [
        const InvoiceHeaderWidget(),
        Expanded(
          child: isReturn
              ? const _ReturnBody()
              : (state.cartItems.isEmpty
              ? const _EmptyCart()
              : Column(children: [
            const CartTableHeader(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                itemCount: state.cartItems.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 5),
                itemBuilder: (context, index) =>
                    CartItemRow(cartItem: state.cartItems[index], rowIndex: index),
              ),
            ),
          ])),
        ),
        isReturn
            ? const _ReturnSummary()
            : const CartSummaryWidget(),
      ]),
    );
  }
}

// ── Invoice Header ────────────────────────────────────────────────
class InvoiceHeaderWidget extends ConsumerWidget {
  const InvoiceHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state          = ref.watch(saleInvoiceProvider);
    final notifier       = ref.read(saleInvoiceProvider.notifier);
    final returnState    = ref.watch(saleReturnProvider);
    final returnNotifier = ref.read(saleReturnProvider.notifier);
    final isReturn       = state.saleType == SaleType.saleReturn;

    final customers = ref.watch(customerProvider).allCustomers
        .where((c) => c.deletedAt == null && c.isActive)
        .toList();

    final dateFmt = DateFormat('dd-MM-yyyy');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color:  AppColor.white,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(children: [
        // Row 1: No + Date + Hold button
        Row(children: [
          Expanded(
            flex: 2,
            child: DisabledTextField(
              label: isReturn ? 'Return No' : 'Invoice No',
              value: isReturn ? returnState.returnNo : state.invoiceNo,
              icon:  isReturn
                  ? Icons.assignment_return_outlined
                  : Icons.receipt_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: DisabledTextField(
              label: 'Date',
              value: dateFmt.format(isReturn ? returnState.date : state.date),
              icon:  Icons.calendar_today_outlined,
            ),
          ),
          const SizedBox(width: 10),
          // ── Hold button (F3) ──────────────────────────────────
          if (!isReturn)
            Tooltip(
              message: 'Hold Invoice (F3)',
              child: _HoldButton(
                enabled: state.cartItems.isNotEmpty,
                onHold:  () => _showHoldDialog(context, ref),
              ),
            ),
        ]),
        const SizedBox(height: 10),

        // Row 2: Type + Customer
        Row(children: [
          Expanded(
            flex: 2,
            child: SaleTypeDropdown(
              focusNode: ref.read(saleTypeFocusProvider),
              value:     state.saleType,
              onChanged: (v) { if (v != null) notifier.setSaleType(v); },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _CustomerDropdown(
              customers:        customers,
              selectedCustomer: isReturn
                  ? returnState.selectedCustomer
                  : state.selectedCustomer,
              isReturn:         isReturn,
              onSelected:       isReturn
                  ? (c) => returnNotifier.selectCustomer(c)
                  : (c) => notifier.selectCustomer(c),
            ),
          ),
        ]),
      ]),
    );
  }

  void _showHoldDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      // !! dialogCtx use karo — outer context stale ho sakta hai !!
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Row(children: [
          Icon(Icons.pause_circle_outline_rounded,
              color: AppColor.warning, size: 20),
          SizedBox(width: 8),
          Text('Invoice Hold Karo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: TextField(
          controller:  ctrl,
          autofocus:   true,
          decoration: const InputDecoration(
            hintText:    'Label (optional, e.g. Table 3)',
            hintStyle:   TextStyle(fontSize: 13),
            border:      OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            Navigator.pop(dialogCtx);
            ref.read(saleInvoiceProvider.notifier)
                .holdCurrentInvoice(label: ctrl.text.trim().isEmpty
                ? null : ctrl.text.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(saleInvoiceProvider.notifier)
                  .holdCurrentInvoice(label: ctrl.text.trim().isEmpty
                  ? null : ctrl.text.trim());
            },
            icon:  const Icon(Icons.pause_rounded, size: 16),
            label: const Text('Hold Karo'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.warning,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
  }
}

// ── Hold Button ────────────────────────────────────────────────────
// SizedBox(width) required — ElevatedButton.icon Row ke andar infinite
// width constraint se crash karta hai bina fixed width ke.
class _HoldButton extends StatelessWidget {
  final bool         enabled;
  final VoidCallback onHold;

  const _HoldButton({required this.enabled, required this.onHold});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(' ',   // spacer — customer dropdown label ke saath align
          style: TextStyle(fontSize: 10)),
      const SizedBox(height: 4),
      SizedBox(
        width:  76,     // ← fixed width zaroor chahiye
        height: 42,
        child: ElevatedButton.icon(
          onPressed: enabled ? onHold : null,
          icon:  const Icon(Icons.pause_circle_outline_rounded,
              size: 15),
          label: const Text('Hold',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor:         AppColor.warning,
            foregroundColor:         Colors.white,
            disabledBackgroundColor: AppColor.grey200,
            elevation:               0,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    ],
  );
}

// ── Customer Dropdown ──────────────────────────────────────────────
class _CustomerDropdown extends ConsumerWidget {
  final List<CustomerModel>      customers;
  final CustomerModel?           selectedCustomer;
  final bool                     isReturn;
  final ValueChanged<CustomerModel?> onSelected;

  const _CustomerDropdown({
    required this.customers,
    required this.selectedCustomer,
    required this.isReturn,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent       = isReturn ? AppColor.error : AppColor.primary;
    final customerFocus = ref.watch(posCustomerFocusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label row with shortcut hint ──────────────────────
        Row(children: [
          const Text('Customer',
              style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      AppColor.textSecondary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Ctrl+K',
                style: TextStyle(
                    fontSize: 9, color: AppColor.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 5),
        Focus(
          focusNode: customerFocus,
          onFocusChange: (hasFocus) {
            // Focus milne pe dropdown ka search box focus karo
            // (DropdownSearch apna popup nahi kholta automatically)
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: customerFocus.hasFocus ? BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(
                color:      AppColor.primary.withOpacity(0.25),
                blurRadius: 0, spreadRadius: 2,
              )],
            ) : null,
            child: DropdownSearch<CustomerModel?>(
              key: ref.read(customerDropdownKeyProvider),
              items:      (filter, _) => [null, ...customers],
              filterFn:   (c, filter) => c == null
                  ? 'Walk In'.toLowerCase().contains(filter.toLowerCase())
                  : c.name.toLowerCase().contains(filter.toLowerCase()),
              selectedItem: selectedCustomer,
              compareFn:  (a, b) => (a?.id ?? '') == (b?.id ?? ''),
              itemAsString: (c) =>
              c == null ? 'Walk In' : '${c.name} — ${c.code}',
              onSelected: onSelected,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  hintText:  'Customer (optional)',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColor.textHint),
                  prefixIcon: Icon(Icons.person_outline,
                      size: 18, color: AppColor.grey500),
                  filled:     true,
                  fillColor: isReturn
                      ? AppColor.error.withOpacity(0.05)
                      : AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide:   BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius:
                      const BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(
                          color: isReturn
                              ? AppColor.error
                              : AppColor.grey200,
                          width: isReturn ? 1.2 : 1.0)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius:
                      const BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: accent, width: 1.5)),
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  cursorHeight: 16,
                  decoration: InputDecoration(
                    hintText:  'Search customer...',
                    hintStyle: const TextStyle(fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border:        InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                itemBuilder:
                    (ctx, customer, isDisabled, isSelected) => ListTile(
                  leading: CircleAvatar(
                    radius:          16,
                    backgroundColor: accent.withOpacity(0.1),
                    child: Text(
                      customer == null
                          ? 'W'
                          : customer.name[0].toUpperCase(),
                      style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                          color:      accent),
                    ),
                  ),
                  title: Text(
                    customer == null ? 'Walk In' : customer.name,
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? accent
                            : AppColor.textPrimary),
                  ),
                  subtitle: customer != null
                      ? Text(customer.code,
                      style: const TextStyle(
                          fontSize: 11,
                          color:    AppColor.textSecondary))
                      : null,
                  trailing: isSelected
                      ? Icon(Icons.check_circle, size: 18, color: accent)
                      : null,
                ),
                fit:         FlexFit.loose,
                constraints: const BoxConstraints(maxHeight: 300),
              ),
            ),
          ), // AnimatedContainer
        ),   // Focus
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Return Body + Summary (unchanged from original) — kept as-is
// ─────────────────────────────────────────────────────────────────

class _ReturnBody extends ConsumerWidget {
  const _ReturnBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnState = ref.watch(saleReturnProvider);
    if (returnState.cartItems.isEmpty) return const _EmptyReturn();

    return Column(children: [
      Container(
        margin:  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:        AppColor.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(children: [
          Expanded(flex: 3, child: _RH(text: 'Product', left: true)),
          Expanded(flex: 2, child: _RH(text: 'Qty')),
          Expanded(flex: 2, child: _RH(text: 'Price')),
          Expanded(flex: 2, child: _RH(text: 'Dis (Rs)')),
          Expanded(flex: 2, child: _RH(text: 'Subtotal')),
          SizedBox(width: 32),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: returnState.cartItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 5),
          itemBuilder: (_, i) => _ReturnItemRow(item: returnState.cartItems[i]),
        ),
      ),
    ]);
  }
}

class _ReturnSummary extends ConsumerWidget {
  const _ReturnSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnState = ref.watch(saleReturnProvider);
    final notifier    = ref.read(saleReturnProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color:  AppColor.white,
        border: Border(top: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(children: [
        _RSR(label: 'Items', value: '${returnState.totalItems}', isCount: true),
        const SizedBox(height: 5),
        _RSR(label: 'Sub Total',      value: _fmt(returnState.totalBeforeTax)),
        _RSR(label: 'Total Discount', value: '-${_fmt(returnState.totalDiscount)}',
            color: AppColor.success),
        const Divider(color: AppColor.grey200, height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Grand Total',
                style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w800,
                    color:      AppColor.error)),
            Text('Rs ${_fmt(returnState.grandTotal)}',
                style: const TextStyle(
                    fontSize:     18,
                    fontWeight:   FontWeight.w900,
                    color:        AppColor.error,
                    letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 14),
        Row(children: [
          SizedBox(
            width: 90,
            child: OutlinedButton.icon(
              onPressed: returnState.cartItems.isEmpty
                  ? null
                  : notifier.clearCart,
              icon:  const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.error,
                side: const BorderSide(color: AppColor.error),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: returnState.cartItems.isEmpty
                  ? null
                  : () => showReturnPaymentDialog(context, ref),
              icon:  const Icon(Icons.payments_outlined, size: 18),
              label: const Text('Refund Now',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor:         AppColor.error,
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
      ]),
    );
  }

  static String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── Return Item Row (unchanged) ────────────────────────────────────
class _ReturnItemRow extends ConsumerStatefulWidget {
  final ReturnCartItem item;
  const _ReturnItemRow({required this.item});

  @override
  ConsumerState<_ReturnItemRow> createState() => _ReturnItemRowState();
}

class _ReturnItemRowState extends ConsumerState<_ReturnItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _disCtrl;
  bool _qtyFocused = false;

  @override
  void initState() {
    super.initState();
    _qtyCtrl   = TextEditingController(text: _fmt(widget.item.quantity));
    _priceCtrl = TextEditingController(text: _fmtD(widget.item.returnPrice));
    _disCtrl   = TextEditingController(text: _fmtD(widget.item.discountAmount));
  }

  @override
  void didUpdateWidget(_ReturnItemRow old) {
    super.didUpdateWidget(old);
    if (!_qtyFocused) {
      final q = _fmt(widget.item.quantity);
      if (_qtyCtrl.text != q) _qtyCtrl.text = q;
    }
    final p = _fmtD(widget.item.returnPrice);
    if (_priceCtrl.text != p) _priceCtrl.text = p;
    final d = _fmtD(widget.item.discountAmount);
    if (_disCtrl.text != d) _disCtrl.text = d;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose(); _priceCtrl.dispose(); _disCtrl.dispose();
    super.dispose();
  }

  String _fmt(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final item     = widget.item;
    final notifier = ref.read(saleReturnProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:        AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.name,
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      AppColor.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(item.product.sku,
                style: const TextStyle(
                    fontSize: 10, color: AppColor.textHint)),
          ]),
        ),
        Expanded(flex: 2, child: _RTF(
          controller:    _qtyCtrl,
          color:         AppColor.error,
          onFocusChange: (f) => _qtyFocused = f,
          onChanged:     (v) {
            final val = double.tryParse(v);
            if (val != null && val > 0) notifier.updateQuantity(item.cartId, val);
          },
          onSubmitted: (_) {
            final val = double.tryParse(_qtyCtrl.text.trim());
            if (val != null && val > 0) notifier.updateQuantity(item.cartId, val);
            else _qtyCtrl.text = _fmt(item.quantity);
          },
        )),
        Expanded(flex: 2, child: _RTF(
          controller:    _priceCtrl,
          onFocusChange: (_) {},
          onChanged: (v) {
            final val = double.tryParse(v);
            if (val != null && val >= 0) notifier.updateReturnPrice(item.cartId, val);
          },
          onSubmitted: (_) {
            final val = double.tryParse(_priceCtrl.text.trim());
            if (val == null) _priceCtrl.text = item.returnPrice.toStringAsFixed(0);
          },
        )),
        Expanded(flex: 2, child: _RTF(
          controller:    _disCtrl,
          prefix:        'Rs',
          onFocusChange: (_) {},
          onChanged: (v) {
            final val = double.tryParse(v);
            if (val != null && val >= 0) notifier.updateDiscount(item.cartId, val);
          },
          onSubmitted: (_) {
            final val = double.tryParse(_disCtrl.text.trim());
            if (val == null) _disCtrl.text = item.discountAmount.toStringAsFixed(0);
          },
        )),
        Expanded(
          flex: 2,
          child: Text('Rs ${_fmtD(item.subTotal)}}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      AppColor.error)),
        ),
        GestureDetector(
          onTap: () => notifier.removeFromCart(item.cartId),
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color:        AppColor.errorLight,
                borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.delete_outline,
                size: 15, color: AppColor.error),
          ),
        ),
      ]),
    );
  }
}

// ── RTF, RH, RSR, EmptyCart, EmptyReturn (same as original) ──────

class _RTF extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<bool>    onFocusChange;
  final ValueChanged<String>  onSubmitted;
  final ValueChanged<String>? onChanged;
  final String?               prefix;
  final Color                 color;

  const _RTF({
    required this.controller,
    required this.onFocusChange,
    required this.onSubmitted,
    this.onChanged,
    this.prefix,
    this.color = AppColor.textPrimary,
  });

  @override
  State<_RTF> createState() => _RTFState();
}

class _RTFState extends State<_RTF> {
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()
      ..addListener(() => widget.onFocusChange(_focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: TextField(
      controller:   widget.controller,
      focusNode:    _focus,
      onSubmitted:  widget.onSubmitted,
      onChanged:    widget.onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
      ],
      textAlign:    TextAlign.center,
      cursorHeight: 14,
      style: TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.w700,
          color:      widget.color),
      decoration: InputDecoration(
        prefixText:  widget.prefix != null ? '${widget.prefix} ' : null,
        prefixStyle: const TextStyle(
            fontSize: 10, color: AppColor.textHint),
        isDense:     true,
        filled:      true,
        fillColor:   AppColor.error.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 11),
        border:        InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:   const BorderSide(color: AppColor.error, width: 1.2),
        ),
      ),
    ),
  );
}

class _RH extends StatelessWidget {
  final String text;
  final bool   left;
  const _RH({required this.text, this.left = false});

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w700,
          color:      AppColor.error,
          letterSpacing: 0.3),
      textAlign: left ? TextAlign.left : TextAlign.center);
}

class _RSR extends StatelessWidget {
  final String label, value;
  final bool   isCount;
  final Color? color;
  const _RSR({required this.label, required this.value, this.isCount = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColor.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      color ?? AppColor.textPrimary)),
      ],
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.06),
              shape: BoxShape.circle),
          child: const Icon(Icons.shopping_cart_outlined,
              size: 48, color: AppColor.primary),
        ),
        const SizedBox(height: 14),
        const Text('Cart is empty',
            style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary)),
        const SizedBox(height: 6),
        const Text('Double tap a product to add it',
            style: TextStyle(fontSize: 13, color: AppColor.textHint)),
        const SizedBox(height: 4),
        const Text('Ya barcode scan karke Enter dabao',
            style: TextStyle(fontSize: 12, color: AppColor.textHint)),
      ],
    ),
  );
}

class _EmptyReturn extends StatelessWidget {
  const _EmptyReturn();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: AppColor.error.withOpacity(0.06),
              shape: BoxShape.circle),
          child: const Icon(Icons.assignment_return_outlined,
              size: 48, color: AppColor.error),
        ),
        const SizedBox(height: 14),
        const Text('Return cart empty hai',
            style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary)),
        const SizedBox(height: 6),
        const Text('Double tap product to add to return',
            style: TextStyle(fontSize: 13, color: AppColor.textHint)),
      ],
    ),
  );
}