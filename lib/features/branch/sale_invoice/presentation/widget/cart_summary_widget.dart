import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/branch/sale_invoice/presentation/widget/payment_dialog.dart';
import '../../../../../core/color/app_color.dart';
import '../provider/sale_invoice_provider.dart';

class CartSummaryWidget extends ConsumerWidget {
  const CartSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(saleInvoiceProvider);
    final notifier = ref.read(saleInvoiceProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color:  AppColor.white,
        border: Border(top: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(children: [

        // ── Totals ──────────────────────────────────────────
        _SummaryRow(
          label:   'Items',
          value:   '${state.totalItems}',
          isCount: true,
        ),
        const SizedBox(height: 5),
        _SummaryRow(
          label: 'Sub Total',
          value: _fmt(state.totalBeforeTax),
        ),
        _SummaryRow(
          label: 'Total Tax',
          value: _fmt(state.totalTax),
          color: AppColor.warning,
        ),
        _SummaryRow(
          label: 'Total Discount',
          value: '-${_fmt(state.totalDiscount)}',
          color: AppColor.success,
        ),

        const Divider(color: AppColor.grey200, height: 16),

        // ── Grand Total ─────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Grand Total',
                style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w800,
                    color:      AppColor.primary)),
            Text(
              'Rs ${_fmt(state.grandTotal)}',
              style: const TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w900,
                  color:      AppColor.primary,
                  letterSpacing: -0.5),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Action Buttons ──────────────────────────────────
        Row(children: [
          // Clear
          SizedBox(
            width: 90,
            child: OutlinedButton.icon(
              onPressed: state.cartItems.isEmpty ? null : notifier.clearCart,
              icon:  const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear',
                  style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.error,
                side:    const BorderSide(color: AppColor.error),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                shape:   RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Pay Now → opens dialog
          Expanded(
            child: ElevatedButton.icon(
              onPressed: state.cartItems.isEmpty
                  ? null
                  : () => showPaymentDialog(context, ref),
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('Pay Now',
                  style: TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor:         AppColor.primary,
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
      ]),
    );
  }

  static String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── Summary Row ───────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool   isCount;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isCount = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color:    AppColor.textSecondary)),
        Text(
          isCount ? value : 'Rs $value',
          style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      color ?? AppColor.textPrimary),
        ),
      ],
    ),
  );
}