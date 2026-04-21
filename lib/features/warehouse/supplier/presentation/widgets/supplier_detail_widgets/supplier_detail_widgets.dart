// =============================================================
// supplier_detail_widgets.dart
// Detail screen ke reusable widgets:
//   - DetailStatCard  — financial summary cards
//   - DetailTabButton — Ledger/Orders tab switch
//   - LedgerEntryRow  — ledger table row
//   - PurchaseOrderRow — PO table row
//   - TableHeaderRow  — table column headers
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_detail_models.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/domian/supplier_model.dart';
import 'package:jan_ghani_final/features/warehouse/supplier/presentation/screens/po_invoice_screen/po_invoice_screen.dart';

// ─────────────────────────────────────────────────────────────
// DETAIL STAT CARD — top pe 3 financial summary cards
// ─────────────────────────────────────────────────────────────

class DetailStatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final String?  subtitle;
  final IconData icon;
  final Color    color;

  const DetailStatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary)),
                  Text(label,
                      style: TextStyle(fontSize: 12,
                          color: AppColor.textSecondary)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(fontSize: 11, color: color,
                            fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DETAIL TAB BUTTON — Ledger History / Purchase Orders
// ─────────────────────────────────────────────────────────────

class DetailTabButton extends StatelessWidget {
  final String       label;
  final String       value;
  final String       activeTab;
  final int          count;
  final VoidCallback onTap;

  const DetailTabButton({
    super.key,
    required this.label,
    required this.value,
    required this.activeTab,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == activeTab;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color:        isActive ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColor.white : AppColor.textSecondary,
                )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColor.white.withOpacity(0.25)
                    : AppColor.grey200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColor.white : AppColor.textSecondary,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LEDGER ENTRY ROW
// ─────────────────────────────────────────────────────────────

class LedgerEntryRow extends StatefulWidget {
  final SupplierLedgerEntry entry;

  const LedgerEntryRow({required super.key, required this.entry});

  @override
  State<LedgerEntryRow> createState() => _LedgerEntryRowState();
}

class _LedgerEntryRowState extends State<LedgerEntryRow> {
  bool _isHovered = false;

  @override
  void deactivate() {
    _isHovered = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;

    // Entry type ke hisaab se color + icon
    final Color    typeColor;
    final IconData typeIcon;
    switch (e.entryType) {
      case 'purchase':
        typeColor = AppColor.error;
        typeIcon  = Icons.shopping_cart_outlined;
        break;
      case 'payment':
        typeColor = AppColor.success;
        typeIcon  = Icons.payments_outlined;
        break;
      case 'return':
        typeColor = AppColor.info;
        typeIcon  = Icons.keyboard_return_rounded;
        break;
      default: // adjustment
        typeColor = AppColor.warning;
        typeIcon  = Icons.tune_rounded;
    }

    final bool   isCredit   = e.amount < 0;
    final String amountStr  = isCredit
        ? '- Rs ${e.amount.abs().toStringAsFixed(0)}'
        : '+ Rs ${e.amount.toStringAsFixed(0)}';
    final Color  amountColor = isCredit ? AppColor.success : AppColor.error;

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (_) { if (mounted) setState(() => _isHovered = true);  },
      onExit:  (_) { if (mounted) setState(() => _isHovered = false); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color:    _isHovered
            ? AppColor.primary.withOpacity(0.03) : Colors.transparent,
        padding:  const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            // Type icon box
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color:        typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(typeIcon, size: 15, color: typeColor),
            ),
            const SizedBox(width: 12),

            // Type badge + date
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(e.entryTypeLabel,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600, color: typeColor)),
                  ),
                  const SizedBox(height: 3),
                  Text(_fmtDate(e.createdAt),
                      style: TextStyle(fontSize: 11,
                          color: AppColor.textSecondary)),
                ],
              ),
            ),

            // Notes
            Expanded(
              flex: 3,
              child: Text(e.notes ?? '—',
                  style: TextStyle(fontSize: 13,
                      color: AppColor.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ),

            // Amount
            Expanded(
              flex: 2,
              child: Text(amountStr,
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w700, color: amountColor)),
            ),

            // Balance after
            Expanded(
              flex: 2,
              child: Text(
                'Rs ${e.balanceAfter.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w500, color: AppColor.textPrimary),
              ),
            ),

            // Created by
            Expanded(
              flex: 2,
              child: Text(e.createdByName ?? '—',
                  style: TextStyle(fontSize: 12,
                      color: AppColor.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}';
}

// ─────────────────────────────────────────────────────────────
// PURCHASE ORDER ROW
// ─────────────────────────────────────────────────────────────

class PurchaseOrderRow extends StatefulWidget {
  final SupplierPurchaseOrder order;
  final VoidCallback? onTap; // click → dialog open

  const PurchaseOrderRow({
    required super.key,
    required this.order,
    this.onTap,
  });

  @override
  State<PurchaseOrderRow> createState() => _PurchaseOrderRowState();
}

class _PurchaseOrderRowState extends State<PurchaseOrderRow> {
  bool _isHovered = false;

  @override
  void deactivate() {
    _isHovered = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;

    final Color statusColor;
    switch (o.status) {
      case 'received':  statusColor = AppColor.success; break;
      case 'ordered':   statusColor = AppColor.info;    break;
      case 'partial':   statusColor = AppColor.warning; break;
      case 'cancelled': statusColor = AppColor.error;   break;
      default:          statusColor = AppColor.grey500; // draft
    }

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      cursor: widget.onTap != null
          ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) { if (mounted) setState(() => _isHovered = true);  },
      onExit:  (_) { if (mounted) setState(() => _isHovered = false); },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color:    _isHovered
              ? AppColor.primary.withOpacity(0.05) : Colors.transparent,
          padding:  const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              // PO Number — click karo detail dialog ke liye
              Expanded(
                flex: 2,
                child: Text(o.poNumber,
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: AppColor.primary)),
              ),

              // Order date
              Expanded(
                flex: 2,
                child: Text(_fmtDate(o.orderDate),
                    style: TextStyle(fontSize: 13,
                        color: AppColor.textSecondary)),
              ),

              // Expected date
              Expanded(
                flex: 2,
                child: Text(
                  o.expectedDate != null ? _fmtDate(o.expectedDate!) : '—',
                  style: TextStyle(fontSize: 13,
                      color: AppColor.textSecondary),
                ),
              ),

              // Status badge
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:        statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: statusColor),
                          ),
                          const SizedBox(width: 5),
                          Text(o.statusLabel,
                              style: TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 40,),

              // Total
              Expanded(
                flex: 2,
                child: Text(o.totalAmount.toString(),
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary)),
              ),

              // Paid
              Expanded(
                flex: 2,
                child: Text(o.paidAmount.toString(),
                    style: TextStyle(fontSize: 13,
                        color: AppColor.success,
                        fontWeight: FontWeight.w500)),
              ),

              // Remaining
              Expanded(
                flex: 2,
                child: Text(
                  o.isFullyPaid ? 'Clear' : o.remainingAmount.toString(),
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color: o.isFullyPaid ? AppColor.success : AppColor.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}';

  String _fmt(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────
// TABLE HEADER ROW — column labels
// ─────────────────────────────────────────────────────────────

class TableHeaderRow extends StatelessWidget {
  final List<TableHeaderCell> columns;

  const TableHeaderRow({super.key, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        color:  AppColor.grey100,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: columns.map((col) => Expanded(
          flex: col.flex,
          child: Text(col.label,
              style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textSecondary,
                  letterSpacing: 0.4)),
        )).toList(),
      ),
    );
  }
}

class TableHeaderCell {
  final String label;
  final int    flex;
  const TableHeaderCell(this.label, this.flex);
}

// Ledger table headers — icon column has no label
const kLedgerHeaders = [
  TableHeaderCell('',              1),
  TableHeaderCell('Type / Date',   2),
  TableHeaderCell('Notes',         3),
  TableHeaderCell('Amount',        2),
  TableHeaderCell('Balance After', 2),
  TableHeaderCell('By',            2),
];

// Purchase orders table headers
const kOrderHeaders = [
  TableHeaderCell('PO Number',   2),
  TableHeaderCell('Order Date',  2),
  TableHeaderCell('Expected',    2),
  TableHeaderCell('Status',      2),
  TableHeaderCell('Total',       2),
  TableHeaderCell('Paid',        2),
  TableHeaderCell('Remaining',   2),
];