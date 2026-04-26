// =============================================================
// po_cart_summary_widget.dart
// Clean + Beautiful summary
// Save Invoice button disabled when:
//   1. cart empty
//   2. koi bhi item ki salePrice == 0
//   3. supplier select nahi kiya
//   4. delivery date set nahi ki
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';

class PoCartSummaryWidget extends ConsumerWidget {
  const PoCartSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(purchaseInvoiceProvider);
    final notifier = ref.read(purchaseInvoiceProvider.notifier);
    final isReturn = state.poType == PoType.purchaseReturn;

    // ── Validation conditions ──────────────────────────────
    final bool hasItems        = state.cartItems.isNotEmpty;
    final bool allHavePrice    = state.cartItems.isNotEmpty &&
        state.cartItems.every((i) => i.salePrice > 0);
    final bool hasSupplier     = state.selectedSupplier != null;
    final bool hasDeliveryDate = state.deliveryDate != null;

    final hasPriceError = state.hasPriceError;
    final bool canSave =
        hasItems && allHavePrice && hasSupplier && hasDeliveryDate && !hasPriceError;

    // Missing info counts for warnings
    final int missingPriceCount = state.cartItems
        .where((i) => i.salePrice <= 0)
        .length;

    // ── Which warnings to show ─────────────────────────────
    // Only show warnings when cart has items (otherwise empty cart msg is enough)
    final bool showPriceWarning    = hasItems && !allHavePrice;
    final bool showSupplierWarning = hasItems && !hasSupplier;
    final bool showDateWarning     = hasItems && !hasDeliveryDate;

    return Container(
      decoration: BoxDecoration(
        color:  AppColor.white,
        border: Border(top: BorderSide(color: AppColor.grey200)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset:     const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Totals section ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              children: [
                // Items count pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        AppColor.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 11, color: AppColor.primary),
                          const SizedBox(width: 4),
                          Text('${state.totalItems} items',
                              style: TextStyle(
                                  fontSize:   10,
                                  fontWeight: FontWeight.w600,
                                  color:      AppColor.primary)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isReturn)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:        AppColor.errorLight,
                          borderRadius: BorderRadius.circular(20),
                          border:       Border.all(
                              color: AppColor.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_return_outlined,
                                size: 11, color: AppColor.error),
                            const SizedBox(width: 4),
                            Text('Purchase Return',
                                style: TextStyle(
                                    fontSize:   10,
                                    fontWeight: FontWeight.w600,
                                    color:      AppColor.error)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Totals rows
                _TRow(
                  label: 'Sub Total',
                  value: _fmtRs(state.totalBeforeTax,
                      isReturn: isReturn),
                ),
                if (state.totalTax > 0) ...[
                  const SizedBox(height: 3),
                  _TRow(
                    label:      'Total Tax',
                    value:      '+${_fmtRs(state.totalTax)}',
                    valueColor: AppColor.warning,
                  ),
                ],
                if (state.totalDiscount > 0) ...[
                  const SizedBox(height: 3),
                  _TRow(
                    label:      'Total Discount',
                    value:      '-${_fmtRs(state.totalDiscount)}',
                    valueColor: AppColor.success,
                  ),
                ],
                if (state.totalProfit > 0) ...[
                  const SizedBox(height: 3),
                  _TRow(
                    label:      'Expected Profit',
                    value:      _fmtRs(state.totalProfit),
                    valueColor: const Color(0xFF534AB7),
                  ),
                ],

                const SizedBox(height: 8),
                const Divider(color: AppColor.grey200, height: 1),
                const SizedBox(height: 8),

                // Grand Total — highlighted
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Grand Total',
                        style: TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                            color: isReturn
                                ? AppColor.error
                                : AppColor.primary)),
                    Text(
                      '${isReturn ? '- ' : ''}'
                          'Rs ${_fmt(state.grandTotal.abs())}',
                      style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.w800,
                          color: isReturn
                              ? AppColor.error
                              : AppColor.primary),
                    ),
                  ],
                ),
                // Paid + Remaining — sirf tab dikhao jab koi amount ho
                if (state.paidAmount > 0) ...[
                  const SizedBox(height: 4),
                  _TRow(
                    label:      'Paid Amount',
                    value:      '- Rs ${_fmt(state.paidAmount)}',
                    valueColor: AppColor.success,
                  ),
                  const SizedBox(height: 3),
                  _TRow(
                    label: 'Remaining',
                    value: 'Rs ${_fmt((state.grandTotal - state.paidAmount).clamp(0, double.infinity))}',
                    valueColor: (state.grandTotal - state.paidAmount) <= 0
                        ? AppColor.success : AppColor.error,
                  ),
                ],
              ],
            ),
          ),

          // ── Validation Warnings ───────────────────────────

         Wrap(
           alignment: WrapAlignment.start,
           children: [
             // 1. Sale price missing
             if (showPriceWarning)
               _WarningBanner(
                 icon:    Icons.warning_amber_rounded,
                 message: '$missingPriceCount item'
                     '${missingPriceCount > 1 ? 's' : ''} '
                     'ki sale price missing hai',
               ),

             if (hasPriceError)
               _WarningBanner(
                 icon: Icons.warning_amber_rounded,
                 message: 'Purchase price sale price se zyada hai',
               ),
             // 2. Supplier not selected
             if (showSupplierWarning)
               _WarningBanner(
                 icon:    Icons.person_off_outlined,
                 message: 'Supplier select karo — Save Invoice disable hai',
               ),

             // 3. Delivery date missing
             if (showDateWarning)
               _WarningBanner(
                 icon:    Icons.event_busy_outlined,
                 message: 'Delivery date set karo — Save Invoice disable hai',
               ),],
         ),

          // ── Buttons ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Row(
              children: [
                // Clear
                SizedBox(
                  width: 90,
                  child: OutlinedButton.icon(
                    onPressed: hasItems ? notifier.clearCart : null,
                    icon:  const Icon(Icons.clear_all, size: 15),
                    label: const Text('Clear',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.error,
                      side:    const BorderSide(color: AppColor.error),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Save Invoice
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canSave
                        ? () => _showConfirmDialog(
                        context, state, notifier)
                        : null,
                    icon: Icon(
                      isReturn
                          ? Icons.assignment_return_outlined
                          : Icons.save_outlined,
                      size: 15,
                    ),
                    label: Text(
                      hasPriceError
                          ? 'Price Error'
                          : isReturn ? 'Save Return' : 'Save Invoice',
                      style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasPriceError
                          ? AppColor.error
                          : isReturn
                          ? AppColor.error : AppColor.primary,
                      foregroundColor:         AppColor.white,
                      disabledBackgroundColor: AppColor.grey300,
                      disabledForegroundColor: AppColor.grey500,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // CONFIRMATION DIALOG
  // ─────────────────────────────────────────────────────────

  void _showConfirmDialog(
      BuildContext            context,
      PurchaseInvoiceState    state,
      PurchaseInvoiceNotifier notifier,
      ) {
    final isReturn = state.poType == PoType.purchaseReturn;
    final fmt      = DateFormat('dd MMM yyyy');

    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:      (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColor.white,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Dialog Header ──────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                decoration: BoxDecoration(
                  color: isReturn
                      ? AppColor.errorLight.withOpacity(0.15)
                      : AppColor.primary.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  border: Border(
                      bottom: BorderSide(color: AppColor.grey200)),
                ),
                child: Row(
                  children: [
                    Container(
                      width:  38, height: 38,
                      decoration: BoxDecoration(
                        color: isReturn
                            ? AppColor.errorLight
                            : AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isReturn
                            ? Icons.assignment_return_outlined
                            : Icons.receipt_long_outlined,
                        size:  18,
                        color: isReturn
                            ? AppColor.error
                            : AppColor.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReturn
                                ? 'Confirm Purchase Return'
                                : 'Confirm Purchase Invoice',
                            style: const TextStyle(
                                fontSize:   15,
                                fontWeight: FontWeight.w700,
                                color:      AppColor.textPrimary),
                          ),
                          Text('Please review before saving',
                              style: TextStyle(
                                  fontSize: 11,
                                  color:    AppColor.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Dialog Body ────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    // Supplier + PO side by side
                    Row(
                      children: [
                        Expanded(
                          child: _DRow(
                            icon:  Icons.person_outline,
                            label: 'Supplier',
                            value: state.selectedSupplier?.name ??
                                'Not selected',
                            sub:   state.selectedSupplier?.company,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DRow(
                            icon:  Icons.receipt_outlined,
                            label: 'PO Number',
                            value: state.poNumber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Dates side by side
                    Row(
                      children: [
                        Expanded(
                          child: _DRow(
                            icon:  Icons.calendar_today_outlined,
                            label: 'Order Date',
                            value: fmt.format(state.orderDate),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DRow(
                            icon:  Icons.local_shipping_outlined,
                            label: 'Delivery Date',
                            value: state.deliveryDate != null
                                ? fmt.format(state.deliveryDate!)
                                : 'Not set',
                            valueColor: state.deliveryDate == null
                                ? AppColor.textHint
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Divider(color: AppColor.grey200, height: 1),
                    const SizedBox(height: 12),

                    // Totals
                    _SRow(label: 'Total Items',
                        value: '${state.totalItems} items'),
                    const SizedBox(height: 5),
                    _SRow(label: 'Sub Total',
                        value: 'Rs ${_fmt(state.totalBeforeTax)}'),
                    if (state.totalTax > 0) ...[
                      const SizedBox(height: 4),
                      _SRow(
                          label: 'Total Tax',
                          value: 'Rs ${_fmt(state.totalTax)}',
                          color: AppColor.warning),
                    ],
                    if (state.totalDiscount > 0) ...[
                      const SizedBox(height: 4),
                      _SRow(
                        label: 'Total Discount',
                        value: '- Rs ${_fmt(state.totalDiscount)}',
                        color: AppColor.success,
                      ),
                    ],
                    if (state.totalProfit > 0) ...[
                      const SizedBox(height: 4),
                      _SRow(
                        label: 'Expected Profit',
                        value: 'Rs ${_fmt(state.totalProfit)}',
                        color: const Color(0xFF534AB7),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Grand Total box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isReturn
                            ? AppColor.errorLight.withOpacity(0.15)
                            : AppColor.primary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isReturn
                              ? AppColor.error.withOpacity(0.2)
                              : AppColor.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total',
                              style: TextStyle(
                                  fontSize:   14,
                                  fontWeight: FontWeight.w700,
                                  color: isReturn
                                      ? AppColor.error
                                      : AppColor.primary)),
                          Text(
                            '${isReturn ? '- ' : ''}'
                                'Rs ${_fmt(state.grandTotal.abs())}',
                            style: TextStyle(
                                fontSize:   17,
                                fontWeight: FontWeight.w800,
                                color: isReturn
                                    ? AppColor.error
                                    : AppColor.primary),
                          ),
                        ],
                      ),
                    ),
                    // Paid + Remaining in dialog
                    if (state.paidAmount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color:        AppColor.successLight,
                          borderRadius: BorderRadius.circular(10),
                          border:       Border.all(
                              color: AppColor.success.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            _SRow(
                              label: 'Paid Amount',
                              value: 'Rs ${_fmt(state.paidAmount)}',
                              color: AppColor.success,
                            ),
                            const SizedBox(height: 4),
                            _SRow(
                              label: 'Remaining',
                              value: 'Rs ${_fmt((state.grandTotal - state.paidAmount).clamp(0, double.infinity))}',
                              color: (state.grandTotal - state.paidAmount) <= 0
                                  ? AppColor.success : AppColor.error,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Dialog Buttons ─────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColor.textSecondary,
                          side:    const BorderSide(color: AppColor.grey300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape:   RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop(); // dialog band karo
                          final error = await notifier.saveInvoice();
                          if (!context.mounted) return;
                          final success = error == null;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? (isReturn
                                  ? 'Purchase Return saved!'
                                  : 'Purchase Invoice saved!')
                                  : 'Error: $error'),
                              backgroundColor: success
                                  ? (isReturn ? AppColor.error : AppColor.success)
                                  : AppColor.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                          // Save successful — PurchaseOrderScreen pe wapas jao
                          if (success && context.mounted) {
                            Navigator.of(context).pop(true); // ← true pass karo
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReturn
                              ? AppColor.error
                              : AppColor.primary,
                          foregroundColor: AppColor.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Confirm & Save',
                            style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w600)),
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

  // ── Formatters ────────────────────────────────────────────

  static String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');

  static String _fmtRs(double v, {bool isReturn = false}) =>
      '${isReturn ? '-' : ''}Rs ${_fmt(v)}';
}

// ─────────────────────────────────────────────────────────────
// WARNING BANNER
// ─────────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  final IconData icon;
  final String   message;

  const _WarningBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin:  const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:        Colors.redAccent.withOpacity(.3),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(
            color: AppColor.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  fontSize:   10,
                  fontWeight: FontWeight.w500,
                  color:      AppColor.black),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOTAL ROW — summary section
// ─────────────────────────────────────────────────────────────

class _TRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColor.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      valueColor ?? AppColor.textPrimary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DIALOG DETAIL ROW
// ─────────────────────────────────────────────────────────────

class _DRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final String?  sub;
  final Color?   valueColor;

  const _DRow({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color:        AppColor.white,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 13,
                color: AppColor.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        color:    AppColor.textSecondary)),
                Text(value,
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      valueColor ?? AppColor.textPrimary),
                    overflow: TextOverflow.ellipsis),
                if (sub != null)
                  Text(sub!,
                      style: const TextStyle(
                          fontSize: 9,
                          color:    AppColor.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DIALOG SUMMARY ROW
// ─────────────────────────────────────────────────────────────

class _SRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SRow({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColor.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      color ?? AppColor.textPrimary)),
      ],
    );
  }
}