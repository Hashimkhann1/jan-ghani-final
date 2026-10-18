import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/sale_summary_model.dart';

/// Invoice ki poori detail right side ke panel mein (slide-in).
Future<void> showSaleInvoiceDetailPanel({
  required BuildContext          context,
  required SummaryInvoice        invoice,
  required String Function(double) fmtAmt,
}) {
  return showGeneralDialog<void>(
    context:            context,
    barrierDismissible: true,
    barrierLabel:       'Close',
    barrierColor:       Colors.black.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) {
      final width = MediaQuery.of(ctx).size.width;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.white,
          elevation: 12,
          child: SizedBox(
            width:  width < 480 ? width : 460,
            height: double.infinity,
            child: _InvoicePanel(invoice: invoice, fmtAmt: fmtAmt),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _InvoicePanel extends StatelessWidget {
  final SummaryInvoice          invoice;
  final String Function(double) fmtAmt;
  const _InvoicePanel({required this.invoice, required this.fmtAmt});

  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  String _qty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final inv       = invoice;
    final subTotal  = inv.items.fold<double>(0, (s, i) => s + i.totalAmount);
    const hint      = TextStyle(fontSize: 11, color: AppColor.textHint);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invoice Detail',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textHint)),
                    const SizedBox(height: 2),
                    Text(inv.invoiceNo,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D23))),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Meta ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(children: [
                    _meta('Customer', inv.customerLabel),
                    _meta('Date', _dateFmt.format(inv.invoiceDate)),
                    _meta('Payment', inv.paymentLabel),
                    _meta('Items', '${inv.items.length}'),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Items ────────────────────────────────────────
                const Text('Items',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23))),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Expanded(flex: 5, child: Text('Product', style: hint)),
                    Expanded(
                        flex: 2,
                        child: Text('Qty',
                            style: hint, textAlign: TextAlign.center)),
                    Expanded(
                        flex: 3,
                        child: Text('Price',
                            style: hint, textAlign: TextAlign.right)),
                    Expanded(
                        flex: 3,
                        child: Text('Total',
                            style: hint, textAlign: TextAlign.right)),
                  ]),
                ),
                for (final item in inv.items) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(item.productName,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_qty(item.quantity),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12.5)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(fmtAmt(item.salePrice),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12.5)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(fmtAmt(item.totalAmount),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                ],
                const SizedBox(height: 20),

                // ── Totals ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(children: [
                    _meta('Sub Total', fmtAmt(subTotal)),
                    if (inv.totalDiscount > 0)
                      _meta('Discount', '- ${fmtAmt(inv.totalDiscount)}'),
                    const Divider(height: 18, color: Color(0xFFE5E7EB)),
                    _meta('Grand Total', fmtAmt(inv.grandTotal), bold: true),
                    _meta('Paid', fmtAmt(inv.payAmount)),
                    const Divider(height: 18, color: Color(0xFFE5E7EB)),
                    _meta('Previous Balance', fmtAmt(inv.previousAmount)),
                    _meta('New Balance', fmtAmt(inv.newAmount), bold: true),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: bold ? 14 : 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: AppColor.textSecondary)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: bold ? 15 : 13,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      color: const Color(0xFF1A1D23))),
            ),
          ],
        ),
      );
}
