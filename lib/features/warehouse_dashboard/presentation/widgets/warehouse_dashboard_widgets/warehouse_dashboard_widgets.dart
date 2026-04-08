// =============================================================
// warehouse_dashboard_widgets.dart
// Dashboard ke reusable small widgets:
//   - DashStatCard       — top 4 summary cards
//   - SectionCard        — card wrapper with header + footer
//   - PoStatusBadge      — PO status badge
//   - TransferStatusBadge
//   - StockProgressRow   — low stock item with progress bar
//   - SupplierDueRow     — supplier outstanding row
//   - MovementRow        — stock movement row
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse_dashboard/domain/warehouse_dashboard_models.dart';

// ─────────────────────────────────────────────────────────────
// DASH STAT CARD — top mein 4 cards
// ─────────────────────────────────────────────────────────────

class DashStatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final String?  badge;         // top-right badge text
  final IconData icon;
  final Color    color;
  final double   barPercent;    // 0.0 to 1.0

  const DashStatCard({
    super.key,
    required this.label,
    required this.value,
    this.badge,
    required this.icon,
    required this.color,
    this.barPercent = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColor.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 17),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(badge!,
                        style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w600, color: color)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Value
            Text(value,
                style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary)),
            const SizedBox(height: 3),

            // Label
            Text(label,
                style: TextStyle(fontSize: 12,
                    color: AppColor.textSecondary)),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value:            barPercent,
                minHeight:        3,
                backgroundColor:  AppColor.grey200,
                valueColor:       AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION CARD — card wrapper with header + optional footer
// ─────────────────────────────────────────────────────────────

class SectionCard extends StatelessWidget {
  final Widget       headerIcon;
  final String       title;
  final Widget?      headerTrailing;
  final List<Widget> children;
  final String?      footerLeft;
  final String?      footerRight;
  final VoidCallback? onFooterRightTap;

  const SectionCard({
    super.key,
    required this.headerIcon,
    required this.title,
    this.headerTrailing,
    required this.children,
    this.footerLeft,
    this.footerRight,
    this.onFooterRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColor.grey200)),
              ),
              child: Row(
                children: [
                  headerIcon,
                  const SizedBox(width: 8),
                  Text(title,
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary)),
                  const Spacer(),
                  if (headerTrailing != null) headerTrailing!,
                ],
              ),
            ),

            // Content rows
            ...children,

            // Footer
            if (footerLeft != null || footerRight != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppColor.grey100)),
                ),
                child: Row(
                  children: [
                    if (footerLeft != null)
                      Text(footerLeft!,
                          style: TextStyle(fontSize: 11,
                              color: AppColor.textSecondary)),
                    const Spacer(),
                    if (footerRight != null)
                      GestureDetector(
                        onTap: onFooterRightTap,
                        child: Text(footerRight!,
                            style: TextStyle(fontSize: 11,
                                color: AppColor.textSecondary)),
                      ),
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
// PO STATUS BADGE
// ─────────────────────────────────────────────────────────────

class PoStatusBadge extends StatelessWidget {
  final String status;
  const PoStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg, fg, dot;
    switch (status) {
      case 'ordered':
        bg = AppColor.infoLight;   fg = AppColor.info;    dot = AppColor.info;
        break;
      case 'partial':
        bg = AppColor.warningLight; fg = AppColor.warning; dot = AppColor.warning;
        break;
      case 'received':
        bg = AppColor.successLight; fg = AppColor.success; dot = AppColor.success;
        break;
      case 'cancelled':
        bg = AppColor.errorLight;  fg = AppColor.error;   dot = AppColor.error;
        break;
      default: // draft
        bg = AppColor.grey100; fg = AppColor.grey500; dot = AppColor.grey400;
    }

    final label = status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: fg)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TRANSFER STATUS BADGE
// ─────────────────────────────────────────────────────────────

class TransferStatusBadge extends StatelessWidget {
  final String status;
  const TransferStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isApproved = status == 'approved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isApproved ? AppColor.infoLight : AppColor.warningLight,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isApproved ? AppColor.info : AppColor.warning,
            ),
          ),
          const SizedBox(width: 4),
          Text(isApproved ? 'Approved' : 'Requested',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: isApproved ? AppColor.info : AppColor.warning)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STOCK PROGRESS ROW — low stock item
// ─────────────────────────────────────────────────────────────

class StockProgressRow extends StatelessWidget {
  final LowStockItem item;
  final bool         isLast;

  const StockProgressRow({
    super.key,
    required this.item,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct   = item.stockPercent;
    final color = item.isCritical ? AppColor.error : AppColor.warning;
    final fgTxt = item.isCritical ? AppColor.error : AppColor.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isLast ? null
            : Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.productName,
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary)),
                    Text(
                      '${item.currentStock.toInt()} / '
                          '${item.maxStockLevel ?? 100}',
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w600, color: fgTxt),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value:           pct,
                    minHeight:       4,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor:      AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.sku}  •  Order '
                      '${item.quantityToOrder.toInt()} units',
                  style: TextStyle(fontSize: 10,
                      color: AppColor.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              item.isCritical ? 'Critical' : 'Low',
              style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPLIER DUE ROW
// ─────────────────────────────────────────────────────────────

class SupplierDueRow extends StatelessWidget {
  final SupplierDue item;
  final bool        isLast;

  const SupplierDueRow({
    super.key,
    required this.item,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHighDue = item.outstandingAmount > 20000;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: isLast ? null
            : Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:  isHighDue
                  ? AppColor.errorLight : AppColor.warningLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(item.initials,
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isHighDue
                        ? AppColor.error : AppColor.warning)),
          ),
          const SizedBox(width: 10),

          // Name + company
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.supplierName,
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary)),
                Text(
                  '${item.paymentTerms} days  •  ${item.companyName}',
                  style: TextStyle(fontSize: 11,
                      color: AppColor.textSecondary),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt(item.outstandingAmount),
                  style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isHighDue
                          ? AppColor.error : AppColor.warning)),
              Text(isHighDue ? 'Overdue' : 'Due soon',
                  style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isHighDue
                          ? AppColor.error : AppColor.grey500)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────
// MOVEMENT ROW — stock_movements table
// ─────────────────────────────────────────────────────────────

class MovementRow extends StatelessWidget {
  final StockMovementEntry entry;
  final bool               isLast;

  const MovementRow({
    super.key,
    required this.entry,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    // Color + icon based on movement type
    final Color iconBg, iconFg;
    final IconData icon;
    if (entry.isInward) {
      if (entry.movementType == 'return_in') {
        iconBg = AppColor.errorLight;
        iconFg = AppColor.error;
        icon   = Icons.keyboard_return_rounded;
      } else {
        iconBg = AppColor.successLight;
        iconFg = AppColor.success;
        icon   = Icons.arrow_upward_rounded;
      }
    } else {
      iconBg = AppColor.infoLight;
      iconFg = AppColor.info;
      icon   = Icons.arrow_downward_rounded;
    }

    final qtyColor = entry.isInward ? AppColor.success : AppColor.info;
    final qtyStr   = entry.isInward
        ? '+${entry.quantity.toInt()}'
        : '${entry.quantity.toInt()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null
            : Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color:        iconBg,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: iconFg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.productName,
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${entry.movementLabel}'
                      '${entry.referenceNumber != null ? '  •  ${entry.referenceNumber}' : ''}',
                  style: TextStyle(fontSize: 11,
                      color: AppColor.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(qtyStr,
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w700, color: qtyColor)),
              Text(entry.timeLabel,
                  style: TextStyle(fontSize: 10,
                      color: AppColor.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}