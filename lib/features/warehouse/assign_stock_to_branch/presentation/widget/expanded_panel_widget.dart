import 'package:flutter/material.dart';
import '../../data/model/stock_transfer_model.dart';
import 'amount_line_widget.dart';
import 'mini_tag_widget.dart';

class ExpandedPanel extends StatelessWidget {
  final StockTransfer transfer;
  final bool isPending;
  final VoidCallback onAccept;

  const ExpandedPanel({
    required this.transfer,
    required this.isPending,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = transfer.items.fold(0.0, (s, i) => s + i.subtotal);
    final totalTax = transfer.items.fold(0.0, (s, i) => s + i.taxAmount);
    final totalDiscount =
    transfer.items.fold(0.0, (s, i) => s + i.discountAmount);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E2F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── From → To ──
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warehouse_rounded,
                    size: 14, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transfer.warehouseName,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                const Icon(Icons.store_rounded,
                    size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(
                  transfer.branchName,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),

          // ── Product list header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: const [
                Expanded(
                  child: Text("PRODUCT",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.5)),
                ),
                SizedBox(
                  width: 56,
                  child: Text("QTY",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.5)),
                ),
                SizedBox(
                  width: 80,
                  child: Text("UNIT PRICE",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.5)),
                ),
                SizedBox(
                  width: 80,
                  child: Text("TOTAL",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.5)),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE0E2F0)),

          // ── Product Rows ──
          ...transfer.items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final isLast = i == transfer.items.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1D23)),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  item.barcode,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9CA3AF),
                                      fontFamily: 'monospace'),
                                ),
                                const SizedBox(width: 5),
                                MiniTag(
                                    label: item.unit,
                                    bg: const Color(0xFFE5E7EB),
                                    fg: const Color(0xFF6C7280)),
                                if (item.tax > 0) ...[
                                  const SizedBox(width: 3),
                                  MiniTag(
                                      label:
                                      "+${item.tax.toStringAsFixed(0)}%T",
                                      bg: const Color(0xFFFEF3C7),
                                      fg: const Color(0xFFD97706)),
                                ],
                                if (item.discount > 0) ...[
                                  const SizedBox(width: 3),
                                  MiniTag(
                                      label:
                                      "-${item.discount.toStringAsFixed(0)}%D",
                                      bg: const Color(0xFFD1FAE5),
                                      fg: const Color(0xFF059669)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Qty
                      SizedBox(
                        width: 56,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${item.quantity}",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1)),
                            ),
                          ),
                        ),
                      ),

                      // Unit price
                      SizedBox(
                        width: 80,
                        child: Text(
                          "Rs.${item.unitPrice.toStringAsFixed(0)}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6C7280)),
                        ),
                      ),

                      // Row total
                      SizedBox(
                        width: 80,
                        child: Text(
                          "Rs.${item.total.toStringAsFixed(0)}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1D23)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: Color(0xFFEEEFF4)),
              ],
            );
          }),

          const Divider(height: 1, color: Color(0xFFE0E2F0)),

          // ── Amount Summary + Notes ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Notes
                if (transfer.notes.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            size: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              transfer.notes,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6C7280),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (transfer.notes.isNotEmpty) const SizedBox(width: 12),

                // Amount breakdown box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0E2F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AmountLine(
                        label: "Subtotal",
                        value: "Rs. ${subtotal.toStringAsFixed(0)}",
                      ),
                      if (totalTax > 0) ...[
                        const SizedBox(height: 4),
                        AmountLine(
                          label: "Tax",
                          value: "+ Rs. ${totalTax.toStringAsFixed(0)}",
                          valueColor: const Color(0xFFF59E0B),
                        ),
                      ],
                      if (totalDiscount > 0) ...[
                        const SizedBox(height: 4),
                        AmountLine(
                          label: "Discount",
                          value: "- Rs. ${totalDiscount.toStringAsFixed(0)}",
                          valueColor: const Color(0xFF10B981),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(height: 1, color: const Color(0xFFE0E2F0)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text("Grand Total  ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1D23),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Rs. ${transfer.grandTotal.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Accept / Accepted bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: isPending ?
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text(
                  "Accept & Add to Branch Stock",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding:
                  const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ) : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "${transfer.totalItems} units accepted into branch stock",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
