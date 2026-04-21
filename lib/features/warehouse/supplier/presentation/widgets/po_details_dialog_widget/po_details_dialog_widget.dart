

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_detail_models.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/screens/po_invoice_screen/po_invoice_screen.dart';

class PurchaseOrderDetailDialog extends StatelessWidget {
  final SupplierPurchaseOrder order;
  final String supplierName;
  final SupplierModel? supplierModel; // ← ADD

  const PurchaseOrderDetailDialog({
    super.key,
    required this.order,
    required this.supplierName,
    this.supplierModel, // ← ADD
  });

  // ── Static helper — easily open karo ─────────────────────
  static void show(BuildContext context, SupplierPurchaseOrder order,
      String supplierName, {SupplierModel? supplierModel}) { // ← ADD
    showDialog(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => PurchaseOrderDetailDialog(
          order:         order,
          supplierName:  supplierName,
          supplierModel: supplierModel), // ← ADD
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = order;

    final Color statusColor;
    switch (o.status) {
      case 'received':  statusColor = AppColor.success; break;
      case 'ordered':   statusColor = AppColor.info;    break;
      case 'partial':   statusColor = AppColor.warning; break;
      case 'cancelled': statusColor = AppColor.error;   break;
      default:          statusColor = AppColor.grey500;
    }

    return Dialog(
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColor.surface,
      child: SizedBox(
        width: 1020,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────
            _PoDialogHeader(
              order:        o,
              supplierName: supplierName,
              statusColor:  statusColor,
              onClose:      () => Navigator.of(context).pop(),
            ),

            // ── Scrollable body ──────────────────────────────
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta cards — dates + payment terms
                    _MetaCards(order: o),
                    const SizedBox(height: 16),

                    // Financial summary row
                    _PoFinancialRow(order: o),
                    const SizedBox(height: 16),

                    // Products table
                    _PoProductsTable(order: o),

                    // Notes — agar ho to
                    if (o.notes != null) ...[
                      const SizedBox(height: 16),
                      _PoNotes(notes: o.notes!),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColor.grey200))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap:        () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 9),
                      decoration: BoxDecoration(
                        color:        AppColor.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Close',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColor.primary)),
                    ),
                  ),
                  SizedBox(width: 10,),

                  if (supplierModel != null) ...[
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        PoInvoiceScreen.show(context, order, supplierModel!);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color:        AppColor.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.print_rounded, size: 15, color: AppColor.primary),
                            const SizedBox(width: 6),
                            Text('Print Invoice',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PO Dialog Header ─────────────────────────────────────────

class _PoDialogHeader extends StatelessWidget {
  final SupplierPurchaseOrder order;
  final String                supplierName;
  final Color                 statusColor;
  final VoidCallback          onClose;

  const _PoDialogHeader({
    required this.order,
    required this.supplierName,
    required this.statusColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColor.grey200))),
      child: Row(
        children: [
          // PO icon box
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        AppColor.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_long_outlined,
                size: 18, color: AppColor.info),
          ),
          const SizedBox(width: 12),

          // PO number + supplier + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.poNumber,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: statusColor),
                          ),
                          const SizedBox(width: 4),
                          Text(order.statusLabel,
                              style: TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$supplierName  •  ${_fmtDate(order.orderDate)}',
                        style: TextStyle(fontSize: 12,
                            color: AppColor.textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          // Close button
          InkWell(
            onTap:        onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:        AppColor.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close_rounded, size: 16,
                  color: AppColor.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}';
}

// ── Meta Cards — dates + payment terms ───────────────────────

class _MetaCards extends StatelessWidget {
  final SupplierPurchaseOrder order;
  const _MetaCards({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetaCard(label: 'Order date',    value: _fmtDate(order.orderDate)),
        const SizedBox(width: 10),
        _MetaCard(
          label: 'Expected date',
          value: order.expectedDate != null
              ? _fmtDate(order.expectedDate!) : '—',
        ),
        const SizedBox(width: 10),
        _MetaCard(
          label:      'Received date',
          value:      order.receivedDate != null
              ? _fmtDate(order.receivedDate!) : '—',
          valueColor: order.receivedDate != null
              ? AppColor.success : AppColor.textSecondary,
        ),
        const SizedBox(width: 10),
        _MetaCard(
          label:      'Total items',
          value:      '${order.items.length} products',
          valueColor: AppColor.info,
        ),
      ],
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}';
}

class _MetaCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaCard({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        AppColor.grey100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                    color: AppColor.textSecondary, letterSpacing: 0.3)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColor.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Financial Summary Row — 5 cards ──────────────────────────

class _PoFinancialRow extends StatelessWidget {
  final SupplierPurchaseOrder order;
  const _PoFinancialRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Financial Summary',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColor.textSecondary, letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Row(
          children: [
            _FinCard(label: 'Subtotal',     value: order.subtotal.toString(),
                color: AppColor.info,
                icon: Icons.receipt_outlined),
            const SizedBox(width: 8),
            _FinCard(label: 'Discount',     value: '- ${_fmt(order.discountAmount)}',
                color: AppColor.success,
                icon: Icons.local_offer_outlined),
            const SizedBox(width: 8),
            _FinCard(label: 'Total amount', value: order.totalAmount.toString(),
                color: AppColor.warning,
                icon: Icons.calculate_outlined),
            const SizedBox(width: 8),
            _FinCard(label: 'Paid',         value: order.paidAmount.toString(),
                color: AppColor.success,
                icon: Icons.payments_outlined),
            const SizedBox(width: 8),
            _FinCard(
              label: 'Remaining',
              value: order.isFullyPaid ? 'Clear' : order.remainingAmount.toString(),
              color: order.isFullyPaid ? AppColor.success : AppColor.error,
              icon:  order.isFullyPaid
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

class _FinCard extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;

  const _FinCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 14, color: color),
              alignment: Alignment.center,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  Text(label,
                      style: TextStyle(fontSize: 10,
                          color: AppColor.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Products Table ────────────────────────────────────────────

class _PoProductsTable extends StatelessWidget {
  final SupplierPurchaseOrder order;
  const _PoProductsTable({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Products  (${order.items.length} items)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColor.textSecondary, letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border:       Border.all(color: AppColor.grey200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  color: AppColor.grey100,
                  child: Row(
                    children: [
                      _ph('Product',   3),
                      _ph('Ordered',   1),
                      // _ph('Received',  1),
                      _ph('Purchase Price', 1),
                      _ph('Sale Price', 1),
                      _ph('Total',     1),
                      // _ph('Progress',  2),
                    ],
                  ),
                ),
                // Item rows
                if (order.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('Koi item nahi',
                          style: TextStyle(color: AppColor.textSecondary)),
                    ),
                  )
                else
                  ...order.items.asMap().entries.map((e) => _ProductItemRow(
                    item:    e.value,
                    isLast:  e.key == order.items.length - 1,
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _ph(String label, int flex) => Expanded(
    flex: flex,
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            color: AppColor.textSecondary, letterSpacing: 0.3)),
  );
}

class _ProductItemRow extends StatelessWidget {
  final PurchaseOrderItem item;
  final bool              isLast;

  const _ProductItemRow({required this.item, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final double pct        = item.receivedPercent;
    final Color  pctColor   = pct >= 1.0 ? AppColor.success
        : pct > 0 ? AppColor.warning : AppColor.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null
            : Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        children: [
          // Product name + SKU
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                        color: AppColor.textPrimary)),
                if (item.sku != null)
                  Text(item.sku!,
                      style: TextStyle(fontSize: 11,
                          color: AppColor.textSecondary)),
              ],
            ),
          ),

          // Ordered qty
          Expanded(
            flex: 1,
            child: Text('${item.quantityOrdered.toInt()}',
                style: TextStyle(fontSize: 13,
                    color: AppColor.textPrimary)),
          ),

          // // Received qty — colored
          // Expanded(
          //   flex: 1,
          //   child: Text(
          //     '${item.quantityReceived.toInt()}',
          //     style: TextStyle(fontSize: 13,
          //         fontWeight: FontWeight.w500, color: pctColor),
          //   ),
          // ),

          // Unit cost
          Expanded(
            flex: 1,
            child: Text(
              'Rs ${item.unitCost.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 13,
                  color: AppColor.textSecondary),
            ),
          ),

          // Sale Price
          Expanded(
            flex: 1,
            child: Text(
              '${item.salePrice.toString()}',
              style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w500, color: pctColor),
            ),
          ),

          // Total cost
          Expanded(
            flex: 1,
            child: Text(
              'Rs ${item.totalCost.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColor.textPrimary),
            ),
          ),

          // Progress bar + %
          // Expanded(
          //   flex: 2,
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: ClipRRect(
          //           borderRadius: BorderRadius.circular(4),
          //           child: LinearProgressIndicator(
          //             value:            pct,
          //             minHeight:        5,
          //             backgroundColor:  pctColor.withOpacity(0.12),
          //             valueColor:       AlwaysStoppedAnimation<Color>(pctColor),
          //           ),
          //         ),
          //       ),
          //       const SizedBox(width: 8),
          //       SizedBox(
          //         width: 36,
          //         child: Text(
          //           '${(pct * 100).toInt()}%',
          //           style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          //               color: pctColor),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

// ── Notes ─────────────────────────────────────────────────────

class _PoNotes extends StatelessWidget {
  final String notes;
  const _PoNotes({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColor.textSecondary, letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Container(
          width:   double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        AppColor.grey100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(notes,
              style: TextStyle(fontSize: 13, color: AppColor.textSecondary,
                  height: 1.6)),
        ),
      ],
    );
  }
}