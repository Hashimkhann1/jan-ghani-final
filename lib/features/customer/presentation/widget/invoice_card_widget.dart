import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';


class DocumentItem {
  final String productName;
  final double unitPrice;
  final double discountAmount;
  final double taxAmount;
  final int    qty;
  final double subtotal;
  final Color? subtotalColor; // invoice: null (black) | return: error (red)
  final Color? qtyColor;      // invoice: null         | return: error (red)

  const DocumentItem({
    required this.productName,
    required this.unitPrice,
    required this.discountAmount,
    required this.taxAmount,
    required this.qty,
    required this.subtotal,
    this.subtotalColor,
    this.qtyColor,
  });
}

class DocumentTotal {
  final String label;
  final String value;
  final Color  color;
  final bool   isBold;

  const DocumentTotal({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });
}

// ─────────────────────────────────────────────────────────────
//  Main shared card widget
// ─────────────────────────────────────────────────────────────

class InvoiceDocumentCard extends StatelessWidget {
  final String        headerLabel;    // 'Invoice No:' | 'Return No:'
  final String        documentNumber; // 'INV-0041'    | 'RET-0012'
  final Color         numberColor;    // primary       | error
  final String?       refNumber;      // null           | 'INV-0039'
  final DateTime      date;
  final String        customerName;
  final List<DocumentItem>  items;
  final List<DocumentTotal> totals;
  final Color         borderColor;

  const InvoiceDocumentCard({
    super.key,
    required this.headerLabel,
    required this.documentNumber,
    required this.numberColor,
    this.refNumber,
    required this.date,
    required this.customerName,
    required this.items,
    required this.totals,
    this.borderColor = AppColor.grey200,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Left: Doc number + optional ref + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(headerLabel,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color:    AppColor.textSecondary)),
                          Text(documentNumber,
                              style: TextStyle(
                                  fontSize:   14,
                                  fontWeight: FontWeight.w700,
                                  color:      numberColor)),
                        ],
                      ),
                      if (refNumber != null) ...[
                        const SizedBox(height: 3),
                        Text('Ref: $refNumber',
                            style: const TextStyle(
                                fontSize: 12,
                                color:    AppColor.textSecondary)),
                      ],
                      const SizedBox(height: 3),
                      Text(fmt.format(date),
                          style: const TextStyle(
                              fontSize: 12,
                              color:    AppColor.textSecondary)),
                    ],
                  ),
                ),

                // Right: Customer name
                Text(customerName,
                    style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.textPrimary)),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColor.grey100),

          // ── Items Table ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _DocumentTable(items: items),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child:   Divider(height: 1, thickness: 1, color: AppColor.grey200),
          ),

          // ── Totals ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: totals.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: _TotalRow(total: t),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared Items Table
// ─────────────────────────────────────────────────────────────

class _DocumentTable extends StatelessWidget {
  final List<DocumentItem> items;
  const _DocumentTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(350), // Description
        1: FixedColumnWidth(200),  // Price
        2: FixedColumnWidth(200),  // Dis
        3: FixedColumnWidth(200),  // Tax
        4: FixedColumnWidth(200),  // Qty
        5: FixedColumnWidth(200), // Subtotal / Return Amt
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: AppColor.grey100, width: 1),
        bottom:           BorderSide(color: AppColor.grey200, width: 1),
      ),
      children: [

        // Header
        TableRow(
          decoration: const BoxDecoration(color: AppColor.grey100),
          children: const [
            _TH('Description'),
            _TH('Price'),
            _TH('Dis'),
            _TH('Tax'),
            _TH('Qty'),
            _TH('Subtotal'),
          ],
        ),

        // Data rows
        ...items.map((item) => TableRow(
          children: [
            _TD(item.productName),
            _TD('Rs ${item.unitPrice.toStringAsFixed(0)}'),
            _TD(
              item.discountAmount > 0
                  ? 'Rs ${item.discountAmount.toStringAsFixed(0)}'
                  : '—',
              color: item.discountAmount > 0 ? AppColor.warning : null,
            ),
            _TD(
              item.taxAmount > 0
                  ? 'Rs ${item.taxAmount.toStringAsFixed(0)}'
                  : '—',
              color: item.taxAmount > 0 ? AppColor.primary : null,
            ),
            _TD('${item.qty}',               color: item.qtyColor),
            _TD('Rs ${item.subtotal.toStringAsFixed(0)}',
                isBold: true, color: item.subtotalColor),
          ],
        )),
      ],
    );
  }
}


class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    child: Text(text,
        style: const TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w700,
            color:      AppColor.textSecondary)),
  );
}

class _TD extends StatelessWidget {
  final String text;
  final bool   isBold;
  final Color? color;
  const _TD(this.text, {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    child: Text(text,
        style: TextStyle(
            fontSize:   12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color:      color ?? AppColor.textPrimary)),
  );
}

class _TotalRow extends StatelessWidget {
  final DocumentTotal total;
  const _TotalRow({required this.total});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(total.label,
          style: const TextStyle(
              fontSize: 12, color: AppColor.textSecondary)),
      const SizedBox(width: 20),
      SizedBox(
        width: 110,
        child: Text(total.value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize:   13,
                fontWeight: total.isBold ? FontWeight.w700 : FontWeight.w500,
                color:      total.color)),
      ),
    ],
  );
}