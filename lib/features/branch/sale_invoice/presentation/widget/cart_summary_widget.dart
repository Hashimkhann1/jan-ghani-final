import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/features/branch/sale_invoice/presentation/screen/payment_dialog.dart';
import '../../../../../core/color/app_color.dart';
import '../provider/sale_invoice_provider.dart';
import '../screen/sale_invoice_screen.dart' show payNowTriggerProvider;

class CartSummaryWidget extends ConsumerWidget {
  const CartSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(saleInvoiceProvider);
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final hasItems = state.cartItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color:  AppColor.white,
        border: Border(top: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(children: [
        _SummaryRow(label: 'Items',          value: '${state.totalItems}', isCount: true),
        const SizedBox(height: 5),
        _SummaryRow(label: 'Sub Total',      value: _fmt(state.totalBeforeTax)),
        _SummaryRow(label: 'Total Tax',      value: _fmt(state.totalTax),       color: AppColor.warning),
        _SummaryRow(label: 'Total Discount', value: '-${_fmt(state.totalDiscount)}', color: AppColor.success),
        const Divider(color: AppColor.grey200, height: 16),

        // ── Grand Total ─────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Grand Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColor.primary)),
            Text('Rs ${_fmt(state.grandTotal)}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: AppColor.primary, letterSpacing: -0.5)),
          ],
        ),

        const SizedBox(height: 14),

        // ── Action Buttons Row ──────────────────────────────
        Row(children: [

          // ── Clear ──────────────────────────────────────────
          _CompactButton(
            icon:    Icons.clear_all_rounded,
            label:   'Clear',
            enabled: hasItems,
            color:   AppColor.error,
            filled:  false,
            onTap:   () => _showClearConfirmDialog(context, ref),   // ← dialog
          ),

          const SizedBox(width: 6),

          // ── Hold ───────────────────────────────────────────
          _CompactButton(
            icon:    Icons.pause_circle_outline_rounded,
            label:   'Hold',
            enabled: hasItems,
            color:   const Color(0xFFF5A623),
            filled:  false,
            onTap:   () => _showHoldDialog(context, ref),
          ),

          const SizedBox(width: 6),

          // ── Pay Now ────────────────────────────────────────
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: hasItems ? () => showPaymentDialog(context, ref) : null,
                icon:  const Icon(Icons.payments_outlined, size: 17),
                label: const Text('Pay Now',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:         AppColor.primary,
                  foregroundColor:         Colors.white,
                  disabledBackgroundColor: AppColor.grey300,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ── Print ──────────────────────────────────────────
          // Payment dialog kholo — wahan "Print Thermal Receipt" checkbox select karo
          _CompactButton(
            icon:    Icons.print_outlined,
            label:   'Print',
            enabled: hasItems,
            color:   const Color(0xFF6366F1),
            filled:  false,
            onTap:   () => showPaymentDialog(context, ref),        // ← payment dialog
          ),

        ]),
      ]),
    );
  }

  // ── Clear Confirmation Dialog ──────────────────────────────────
  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    final hasItems = ref.read(saleInvoiceProvider).cartItems.isNotEmpty;
    if (!hasItems) return;

    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColor.warning, size: 22),
          SizedBox(width: 10),
          Text('Clear Invoice?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: const Text(
          'Are you sure you want to clear this invoice?\nAll items will be removed.',
          style: TextStyle(fontSize: 14, color: AppColor.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(d);
              ref.read(saleInvoiceProvider.notifier).clearCart();
            },
            icon:  const Icon(Icons.delete_outline, size: 16),
            label: const Text('Yes, Clear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hold Dialog ────────────────────────────────────────────────
  void _showHoldDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFFF3CD), shape: BoxShape.circle),
                    child: const Icon(Icons.pause_rounded,
                        color: Color(0xFFF5A623), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hold Invoice',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('You can resume this invoice later',
                        style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
                  ]),
                ]),
                const SizedBox(height: 20),
                const Text('Label (optional)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
                        color: Color(0xFF888888))),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl,
                  autofocus:  true,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText:  'e.g. Table 3, Counter 1...',
                    hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFBBBBBB)),
                    prefixIcon: const Icon(Icons.label_outline_rounded,
                        color: Color(0xFFF5A623), size: 16),
                    filled:    true,
                    fillColor: const Color(0xFFFFFDF7),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFF5A623), width: 1.5)),
                  ),
                  onSubmitted: (_) {
                    Navigator.pop(dialogCtx);
                    ref.read(saleInvoiceProvider.notifier)
                        .holdCurrentInvoice(label: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
                  },
                ),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        foregroundColor: const Color(0xFF555555),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        ref.read(saleInvoiceProvider.notifier)
                            .holdCurrentInvoice(label: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
                      },
                      icon:  const Icon(Icons.pause_rounded, size: 16),
                      label: const Text('Hold Invoice'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A623),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── Compact Button ─────────────────────────────────────────────────
class _CompactButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         enabled;
  final Color        color;
  final bool         filled;
  final VoidCallback onTap;

  const _CompactButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : AppColor.grey400;
    return SizedBox(
      height: 44,
      width:  62,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor:         effectiveColor,
          disabledForegroundColor: AppColor.grey400,
          side: BorderSide(
              color: enabled ? color.withOpacity(0.55) : AppColor.grey200, width: 1.2),
          backgroundColor: enabled ? color.withOpacity(0.06) : Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: enabled ? color : AppColor.grey400),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: enabled ? color : AppColor.grey400, letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }
}

// ── Summary Row ───────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool   isCount;
  final Color? color;

  const _SummaryRow({required this.label, required this.value,
    this.isCount = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColor.textSecondary)),
        Text(isCount ? value : 'Rs $value',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: color ?? AppColor.textPrimary)),
      ],
    ),
  );
}