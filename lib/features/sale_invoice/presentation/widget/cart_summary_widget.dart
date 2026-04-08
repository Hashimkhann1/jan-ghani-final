import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/color/app_color.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';

class CartSummaryWidget extends ConsumerStatefulWidget {
  const CartSummaryWidget({super.key});

  @override
  ConsumerState<CartSummaryWidget> createState() =>
      _CartSummaryWidgetState();
}

class _CartSummaryWidgetState extends ConsumerState<CartSummaryWidget> {late TextEditingController _grandTotalCtrl;
  final bool _grandTotalFocused = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(saleInvoiceProvider);
    _grandTotalCtrl = TextEditingController(text: state.grandTotal.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _grandTotalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleInvoiceProvider);
    final notifier = ref.read(saleInvoiceProvider.notifier);

    final bool isReturn = state.saleType == SaleType.saleReturn;

    if (!_grandTotalFocused) {
      final newTotal = state.grandTotal.toStringAsFixed(2);
      if (_grandTotalCtrl.text != newTotal) {
        _grandTotalCtrl.text = newTotal;
      }
    }
    final sign = isReturn ? '-' : '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: AppColor.white, border: Border(top: BorderSide(color: AppColor.grey200))),
      child: Column(children: [
        _SR(label: 'Items', value: '${state.totalItems}', isCount: true),
        const SizedBox(height: 4),
        _SR(label: 'Sub Total', value: '$sign${_fmt(state.totalBeforeTax)}'),
        _SR(label: 'Total Tax', value: '$sign${_fmt(state.totalTax)}', color: AppColor.warning),
        _SR(label: 'Total Discount', value: '-${_fmt(state.totalDiscount)}', color: AppColor.success),
        const Divider(color: AppColor.grey200, height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Grand Total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isReturn ? AppColor.error : AppColor.primary,
              ),
            ),
            Text(
              '${isReturn ? '-' : ''}Rs ${_fmt(state.grandTotal.abs())}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isReturn ? AppColor.error : AppColor.primary,
              ),
            ),
          ],
        ),
        // Change 5: Sale Return badge
        if (isReturn) ...[
          const SizedBox(height: 6),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColor.errorLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border:
              Border.all(color: AppColor.error.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline,
                    size: 12, color: AppColor.error),
                SizedBox(width: 4),
                Text(
                  'Sale Return — Amounts will be reversed',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColor.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 10),

        Row(children: [
          SizedBox(
            width: 100,
            child: OutlinedButton.icon(
              onPressed:
              state.cartItems.isEmpty ? null : notifier.clearCart,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear',
                  style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.error,
                side: const BorderSide(color: AppColor.error),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: ElevatedButton.icon(
                onPressed: state.cartItems.isEmpty
                    ? null
                    : () {
                  if (notifier.saveInvoice()) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isReturn ? 'Sale Return saved successfully!' : 'Invoice saved successfully!'),
                      backgroundColor: isReturn ? AppColor.error : AppColor.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ));
                  }
                },
                icon: Icon(
                  isReturn ? Icons.assignment_return_outlined : Icons.save_outlined,
                  size: 16,
                ),
                label: Text(
                  isReturn ? 'Save Return' : 'Save Invoice',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isReturn ? AppColor.error : AppColor.primary,
                  foregroundColor: AppColor.white,
                  disabledBackgroundColor: AppColor.grey300,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              )),
        ]),
      ]),
    );
  }

  static String _fmt(double v) => v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}


class _SR extends StatelessWidget {
  final String label, value;
  final bool isBold, isCount;
  final Color? color;
  final double fontSize;

  const _SR(
      {required this.label,
        required this.value,
        this.isBold = false,
        this.isCount = false,
        this.color,
        this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  color: AppColor.textSecondary,
                  fontWeight:
                  isBold ? FontWeight.w700 : FontWeight.w400)),
          Text(isCount ? value : 'Rs $value',
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight:
                  isBold ? FontWeight.w700 : FontWeight.w600,
                  color: color ?? AppColor.textPrimary)),
        ]);
  }
}