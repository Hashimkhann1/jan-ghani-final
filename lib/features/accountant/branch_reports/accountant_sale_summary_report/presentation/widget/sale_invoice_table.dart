import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/sale_summary_model.dart';

/// Wide screen par invoices ka table — har row par "View" button.
class SaleInvoiceTable extends StatelessWidget {
  final List<SummaryInvoice>        invoices;
  final int                         startIndex;
  final DateFormat                  dateFmt;
  final DateFormat                  timeFmt;
  final String Function(double)     fmtAmt;
  final ValueChanged<SummaryInvoice> onView;

  const SaleInvoiceTable({
    super.key,
    required this.invoices,
    required this.startIndex,
    required this.dateFmt,
    required this.timeFmt,
    required this.fmtAmt,
    required this.onView,
  });

  static const _gap = SizedBox(width: 14);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFEEEEEE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color:   const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(children: [
              _H('#', flex: 1),
              _gap,
              _H('Invoice', flex: 3),
              _gap,
              _H('Date', flex: 4),
              _gap,
              _H('Customer', flex: 4),
              _gap,
              _H('Payment', flex: 3),
              _gap,
              _H('Items', flex: 2, center: true),
              _gap,
              _H('Discount', flex: 3, right: true),
              _gap,
              _H('Total', flex: 3, right: true),
              _gap,
              _H('', flex: 1),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          for (var i = 0; i < invoices.length; i++) ...[
            _Row(
              index:   startIndex + i + 1,
              invoice: invoices[i],
              dateFmt: dateFmt,
              timeFmt: timeFmt,
              fmtAmt:  fmtAmt,
              onView:  () => onView(invoices[i]),
            ),
            if (i != invoices.length - 1)
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ],
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String label;
  final int    flex;
  final bool   right;
  final bool   center;
  const _H(this.label, {required this.flex, this.right = false, this.center = false});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: right
              ? TextAlign.right
              : center ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize:      11,
            fontWeight:    FontWeight.w700,
            color:         AppColor.textHint,
            letterSpacing: 0.3,
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  final int                     index;
  final SummaryInvoice          invoice;
  final DateFormat              dateFmt;
  final DateFormat              timeFmt;
  final String Function(double) fmtAmt;
  final VoidCallback            onView;

  const _Row({
    required this.index,
    required this.invoice,
    required this.dateFmt,
    required this.timeFmt,
    required this.fmtAmt,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final inv = invoice;
    const cell = TextStyle(fontSize: 12.5, color: AppColor.textSecondary);
    return InkWell(
      onTap: onView,
      hoverColor: const Color(0xFFFAFAFB),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(children: [
          Expanded(
              flex: 1,
              child: Text('$index',
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textHint))),
          SaleInvoiceTable._gap,
          Expanded(
            flex: 3,
            child: Text(inv.invoiceNo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      AppColor.primary)),
          ),
          SaleInvoiceTable._gap,
          Expanded(
            flex: 4,
            child: Text(
                '${dateFmt.format(inv.invoiceDate)}, ${timeFmt.format(inv.invoiceDate)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: cell),
          ),
          SaleInvoiceTable._gap,
          Expanded(
            flex: 4,
            child: Text(inv.customerLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      Color(0xFF1A1D23))),
          ),
          SaleInvoiceTable._gap,
          Expanded(
            flex: 3,
            child: Text(inv.paymentLabel,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: cell),
          ),
          SaleInvoiceTable._gap,
          Expanded(
            flex: 2,
            child: Text('${inv.items.length}',
                textAlign: TextAlign.center, style: cell),
          ),
          SaleInvoiceTable._gap,
          Expanded(
            flex: 3,
            child: Text(inv.totalDiscount > 0 ? fmtAmt(inv.totalDiscount) : '-',
                textAlign: TextAlign.right, style: cell),
          ),
          SaleInvoiceTable._gap,
          Expanded(
            flex: 3,
            child: Text(fmtAmt(inv.grandTotal),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w800,
                    color:      Color(0xFF1A1D23))),
          ),
          SaleInvoiceTable._gap,
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onView,
                tooltip:   'View',
                icon: const Icon(Icons.visibility_outlined, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  backgroundColor: AppColor.primary.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
