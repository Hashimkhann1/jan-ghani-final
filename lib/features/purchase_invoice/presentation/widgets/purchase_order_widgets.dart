// =============================================================
// purchase_order_widgets.dart
// PO screen ke reusable widgets
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../domain/purchase_order_model.dart';

// ─────────────────────────────────────────────────────────────
// PO STAT CARD
// ─────────────────────────────────────────────────────────────

class PoStatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const PoStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColor.surface,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppColor.grey200),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary)),
                  Text(label,
                      style: TextStyle(fontSize: 11,
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

// ─────────────────────────────────────────────────────────────
// PO FILTER CHIP
// ─────────────────────────────────────────────────────────────

class PoFilterChip extends StatelessWidget {
  final String   label;
  final String   value;
  final String   selectedValue;
  final ValueChanged<String> onTap;

  const PoFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap:        () => onTap(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary : AppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColor.primary : AppColor.grey300,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? AppColor.white : AppColor.textSecondary,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PO STATUS BADGE — user ne width:130 add ki hai, rakhi hai
// ─────────────────────────────────────────────────────────────

class PoStatusBadge extends StatelessWidget {
  final String status;
  const PoStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg, fg, dot;
    switch (status) {
      case 'ordered':
        bg = AppColor.infoLight;    fg = AppColor.info;
        dot = AppColor.info;
        break;
      case 'partial':
        bg = AppColor.warningLight; fg = AppColor.warning;
        dot = AppColor.warning;
        break;
      case 'received':
        bg = AppColor.successLight; fg = AppColor.success;
        dot = AppColor.success;
        break;
      case 'cancelled':
        bg = AppColor.errorLight;   fg = AppColor.error;
        dot = AppColor.error;
        break;
      default: // draft
        bg = AppColor.grey100; fg = AppColor.grey500;
        dot = AppColor.grey400;
    }

    return Row(
      children: [
        Container(
          width: 130, // user ka change — rakha hai
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 5, height: 5,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: dot)),
              const SizedBox(width: 4),
              Text(status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PO TABLE ROW
// ─────────────────────────────────────────────────────────────

class PoTableRow extends StatefulWidget {
  final PurchaseOrderModel order;
  final VoidCallback       onView;
  final VoidCallback?      onEdit;

  const PoTableRow({
    required super.key,
    required this.order,
    required this.onView,
    this.onEdit,
  });

  @override
  State<PoTableRow> createState() => _PoTableRowState();
}

class _PoTableRowState extends State<PoTableRow> {
  bool _isHovered = false;

  @override
  void deactivate() {
    _isHovered = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final o           = widget.order;
    final isCancelled = o.status == 'cancelled';

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      cursor:          SystemMouseCursors.click,
      onEnter: (_) { if (mounted) setState(() => _isHovered = true);  },
      onExit:  (_) { if (mounted) setState(() => _isHovered = false); },
      child: GestureDetector(
        onTap: widget.onView,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _isHovered
              ? AppColor.primary.withOpacity(0.03)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 13),
          child: Opacity(
            opacity: isCancelled ? 0.55 : 1.0,
            child: Row(
              children: [
                // PO Number + date
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.poNumber,
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCancelled
                                  ? AppColor.textSecondary
                                  : AppColor.primary,
                              decoration: isCancelled
                                  ? TextDecoration.lineThrough : null)),
                      Text(_fmtDate(o.orderDate),
                          style: TextStyle(fontSize: 11,
                              color: AppColor.textSecondary)),
                    ],
                  ),
                ),

                // Supplier
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      _SupplierAvatar(order: o),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.supplierName ?? '—',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.textPrimary),
                                overflow: TextOverflow.ellipsis),
                            if (o.supplierCompany != null)
                              Text(o.supplierCompany!,
                                  style: TextStyle(fontSize: 11,
                                      color: AppColor.textSecondary),
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Destination — user ne width:140 add ki hai
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 140, // user ka change — rakha hai
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:        AppColor.grey100,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warehouse_outlined,
                                size: 11, color: AppColor.grey500),
                            const SizedBox(width: 4),
                            Text(o.destinationName ?? 'WH-MAIN',
                                style: TextStyle(fontSize: 11,
                                    color: AppColor.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status
                Expanded(
                  flex: 2,
                  child: PoStatusBadge(status: o.status),
                ),

                // Total + paid
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fmt(o.totalAmount),
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textPrimary)),
                      if (!isCancelled)
                        Text('Paid ${_fmt(o.paidAmount)}',
                            style: TextStyle(fontSize: 11,
                                color: o.paidAmount > 0
                                    ? AppColor.success
                                    : AppColor.textSecondary)),
                    ],
                  ),
                ),

                // Remaining + progress
                Expanded(
                  flex: 2,
                  child: isCancelled
                      ? Text('—', style: TextStyle(
                      color: AppColor.textSecondary, fontSize: 13))
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.isFullyPaid
                            ? 'Clear'
                            : _fmt(o.remainingAmount),
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: o.isFullyPaid
                                ? AppColor.success
                                : AppColor.error),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value:           o.paidPercent,
                                minHeight:       4,
                                backgroundColor: AppColor.grey200,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                  o.isFullyPaid
                                      ? AppColor.success
                                      : AppColor.warning,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${(o.paidPercent * 100).toInt()}%',
                            style: TextStyle(fontSize: 10,
                                color: AppColor.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionBtn(
                        icon:  Icons.remove_red_eye_outlined,
                        color: AppColor.info,
                        onTap: widget.onView,
                      ),
                      if (widget.onEdit != null && o.canEdit) ...[
                        const SizedBox(width: 4),
                        _ActionBtn(
                          icon:  Icons.edit_outlined,
                          color: AppColor.primary,
                          onTap: widget.onEdit!,
                        ),
                      ],
                      if (o.status == 'received') ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color:        AppColor.successLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 14, color: AppColor.success),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _fmt(double v) {
    if (v >= 100000) return 'Rs ${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPLIER AVATAR
// ─────────────────────────────────────────────────────────────

class _SupplierAvatar extends StatelessWidget {
  final PurchaseOrderModel order;
  const _SupplierAvatar({required this.order});

  Color _avatarColor(String initials) {
    const colors = [
      Color(0xFFEEEDFE), Color(0xFFE6F1FB),
      Color(0xFFEAF3DE), Color(0xFFFAEEDA),
      Color(0xFFFCEBEB),
    ];
    return colors[initials.codeUnitAt(0) % colors.length];
  }

  Color _textColor(String initials) {
    const colors = [
      Color(0xFF534AB7), Color(0xFF185FA5),
      Color(0xFF3B6D11), Color(0xFF633806),
      Color(0xFFA32D2D),
    ];
    return colors[initials.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final initials = order.supplierInitials;
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color:        _avatarColor(initials),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textColor(initials))),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color:        color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────

class PoEmptyState extends StatelessWidget {
  final bool isSearching;
  const PoEmptyState({super.key, required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching
                ? Icons.search_off_rounded
                : Icons.receipt_long_outlined,
            size: 52, color: AppColor.grey300,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'Koi PO nahi mila'
                : 'Abhi tak koi purchase order nahi',
            style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColor.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            isSearching
                ? 'Search ya filter change karein'
                : 'New PO button se pehla order banao',
            style: TextStyle(fontSize: 13,
                color: AppColor.textHint),
          ),
        ],
      ),
    );
  }
}