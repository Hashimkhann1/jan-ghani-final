// =============================================================
// purchase_order_detail_dialog.dart
// Purchase Order detail dialog — screenshot UI match
// Usage:
//   showDialog(
//     context: context,
//     builder: (_) => POdetailDialogWidget(order: order),
//   );
// =============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/domain/purchase_order_model.dart';

// ─────────────────────────────────────────────────────────────
// ENTRY POINT — static helper
// ─────────────────────────────────────────────────────────────

class POdetailDialogWidget extends StatelessWidget {
  final PurchaseOrderModel order;

  const POdetailDialogWidget({super.key, required this.order});

  static Future<void> show(
      BuildContext context,
      PurchaseOrderModel order,
      ) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => POdetailDialogWidget(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: _DialogContent(order: order),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DIALOG CONTENT
// ─────────────────────────────────────────────────────────────

class _DialogContent extends StatelessWidget {
  final PurchaseOrderModel order;

  const _DialogContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 700),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────
            _DialogHeader(order: order),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // ── Scrollable body ───────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date cards row
                    _DateCardsRow(order: order),
                    const SizedBox(height: 20),

                    // Financial summary
                    _SectionLabel(label: 'Financial Summary'),
                    const SizedBox(height: 10),
                    _FinancialSummaryRow(order: order),
                    const SizedBox(height: 20),

                    // Products table
                    _SectionLabel(
                      label: 'Products (${order.items.length} items)',
                    ),
                    const SizedBox(height: 10),
                    _ItemsTable(items: order.items),

                    // Notes (if any)
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionLabel(label: 'Notes'),
                      const SizedBox(height: 8),
                      _NotesBox(notes: order.notes!),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            _DialogFooter(order: order),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final PurchaseOrderModel order;
  const _DialogHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Color(0xFF4B73FF), size: 22),
          ),
          const SizedBox(width: 14),

          // PO number + status + supplier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.poNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatusBadge(status: order.status),
                    const SizedBox(width: 10),
                    Text(
                      '${order.supplierName ?? order.supplierCompany ?? '—'}'
                          '  •  '
                          '${_fmtDate(order.orderDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              backgroundColor: const Color(0xFFF5F5F5),
              // padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: cfg.$2,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            cfg.$3,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cfg.$2,
            ),
          ),
        ],
      ),
    );
  }

  // (bg, fg, label)
  (Color, Color, String) _statusConfig(String s) {
    switch (s) {
      case 'received':
        return (const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Received');
      case 'ordered':
        return (const Color(0xFFDBEAFE), const Color(0xFF2563EB), 'Ordered');
      case 'partial':
        return (const Color(0xFFFEF9C3), const Color(0xFFCA8A04), 'Partial');
      case 'cancelled':
        return (const Color(0xFFFFE4E6), const Color(0xFFDC2626), 'Cancelled');
      default: // draft
        return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), 'Draft');
    }
  }
}

// ─────────────────────────────────────────────────────────────
// DATE CARDS ROW
// ─────────────────────────────────────────────────────────────

class _DateCardsRow extends StatelessWidget {
  final PurchaseOrderModel order;
  const _DateCardsRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DateCard(
          label: 'Order date',
          value: _fmtDate(order.orderDate),
        ),
        const SizedBox(width: 12),
        _DateCard(
          label: 'Expected date',
          value: order.expectedDate != null
              ? _fmtDate(order.expectedDate!)
              : '—',
        ),
        const SizedBox(width: 12),
        const SizedBox(width: 12),
        _DateCard(
          label: 'Total items',
          value: '${order.items.length} products',
          isBlue: true,
        ),
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isBlue;
  const _DateCard({
    required this.label,
    required this.value,
    this.isBlue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isBlue
                    ? const Color(0xFF4B73FF)
                    : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FINANCIAL SUMMARY ROW
// ─────────────────────────────────────────────────────────────

class _FinancialSummaryRow extends StatelessWidget {
  final PurchaseOrderModel order;
  const _FinancialSummaryRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FinCard(
          icon: Icons.receipt_outlined,
          label: 'Subtotal',
          value: order.subtotal.toString(),
          bg: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 10),
        _FinCard(
          icon: Icons.local_offer_outlined,
          label: 'Discount',
          value: order.discountAmount > 0
              ? '- ${_fmtMoney(order.discountAmount)}'
              : '- Rs 0',
          bg: const Color(0xFFF0FDF4),
          iconColor: const Color(0xFF22C55E),
        ),
        const SizedBox(width: 10),
        _FinCard(
          icon: Icons.grid_4x4_outlined,
          label: 'Total amount',
          value: order.totalAmount.toString(),
          bg: const Color(0xFFFFFBEB),
          iconColor: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 10),
        _FinCard(
          icon: Icons.payments_outlined,
          label: 'Paid',
          value: order.paidAmount.toString(),
          bg: const Color(0xFFF0FDF4),
          iconColor: const Color(0xFF10B981),
        ),
        const SizedBox(width: 10),
        _FinCard(
          icon: Icons.warning_amber_rounded,
          label: 'Remaining',
          value: order.remainingAmount.toString(),
          bg: const Color(0xFFFFF1F2),
          iconColor: const Color(0xFFEF4444),
        ),
      ],
    );
  }
}

class _FinCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color iconColor;

  const _FinCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ITEMS TABLE
// ─────────────────────────────────────────────────────────────

class _ItemsTable extends StatelessWidget {
  final List<PurchaseOrderItem> items;
  const _ItemsTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF9FAFB),
              child: const Row(
                children: [
                  _TH(label: 'Product', flex: 3),
                  _TH(label: 'Ordered', flex: 2, center: true),
                  _TH(label: 'Purchase Price', flex: 2, center: true),
                  _TH(label: 'Discount', flex: 2, center: true),
                  _TH(label: 'Sale Price', flex: 2, center: true),
                  _TH(label: 'Total', flex: 2, center: true),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Rows
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Koi item nahi',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                itemBuilder: (_, i) => _ItemRow(item: items[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  final bool center;
  const _TH({required this.label, required this.flex, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final PurchaseOrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Product name + SKU
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                if (item.sku != null && item.sku!.isNotEmpty)
                  Text(
                    item.sku!,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
              ],
            ),
          ),

          // Ordered
          Expanded(
            flex: 2,
            child: Text(
              _fmtQty(item.quantityOrdered),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),


          // Purchase Price
          Expanded(
            flex: 2,
            child: Text(
              _fmtMoney(item.unitCost),
              textAlign: TextAlign.center,
              style:
              const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),

          // Discount
          Expanded(
            flex: 2,
            child: Text(
              _fmtQty(item.discountAmount),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: item.isFullyReceived
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF374151),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              item.salePrice != null ? _fmtMoney(item.salePrice!) : '—',
              textAlign: TextAlign.center,
              style:
              const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),

          // Total cost
          Expanded(
            flex: 2,
            child: Text(
              item.totalCost.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtQty(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}


// ─────────────────────────────────────────────────────────────
// NOTES BOX
// ─────────────────────────────────────────────────────────────

class _NotesBox extends StatelessWidget {
  final String notes;
  const _NotesBox({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Text(
        notes,
        style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────

class _DialogFooter extends StatelessWidget {
  final PurchaseOrderModel order;
  const _DialogFooter({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Close button
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Close',
                style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 10),

          // Print Invoice button
          ElevatedButton.icon(
            onPressed: () {
              // TODO: connect to your existing print logic
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Print Invoice',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEEF4FF),
              foregroundColor: const Color(0xFF4B73FF),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) =>
    DateFormat('dd-MM-yyyy').format(d);

String _fmtMoney(double v) {
  if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
  return 'Rs ${v.toStringAsFixed(0)}';
}