// Updated on 2026-10-05 03:15 PM
// =============================================================
// purchase_order_widgets.dart
// PO screen ke reusable widgets — Stitch "Purchase Orders v2" design
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../domain/purchase_order_model.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';

// ─────────────────────────────────────────────────────────────
// TABLE COLUMN FLEX — header + row dono yahi use karte hain
// ─────────────────────────────────────────────────────────────

const int    kPoColPo       = 3;
const int    kPoColSupplier = 3;
const int    kPoColItems    = 2;
const int    kPoColStatus   = 2;
const int    kPoColTotal    = 2;
const double kPoColActions  = 120;

// ─────────────────────────────────────────────────────────────
// PO STAT CARD — label + bara value + rangeen sub-line
// ─────────────────────────────────────────────────────────────

class PoStatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final String   subtitle;
  final IconData icon;
  final Color    color;
  final Color?   subtitleColor;

  const PoStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color:        AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: AppColor.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize:      11,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 0.6,
                          color:         AppColor.textSecondary)),
                ),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit:       BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w700,
                      color:      AppColor.textPrimary)),
            ),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w500,
                    color:      subtitleColor ?? color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PO STATUS TAB — segmented tab + count pill
// ─────────────────────────────────────────────────────────────

class PoStatusTab extends StatelessWidget {
  final String   label;
  final String   value;
  final int      count;
  final String   selectedValue;
  final ValueChanged<String> onTap;

  const PoStatusTab({
    super.key,
    required this.label,
    required this.value,
    required this.count,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap:        () => onTap(value),
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:        isSelected ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize:   12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColor.white : AppColor.textSecondary,
                )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.white.withOpacity(0.22)
                    : AppColor.grey200,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text('$count',
                  style: TextStyle(
                    fontSize:   10.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColor.white : AppColor.textSecondary,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PO STATUS BADGE — dot + label pill
// ─────────────────────────────────────────────────────────────

class PoStatusBadge extends StatelessWidget {
  final String status;
  const PoStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg, fg;

    switch (status) {
      case 'ordered':
        bg = AppColor.infoLight;    fg = AppColor.info;
        break;
      case 'partial':
        bg = AppColor.warningLight; fg = AppColor.warningDark;
        break;
      case 'received':
        bg = AppColor.successLight; fg = AppColor.success;
        break;
      case 'return': // purchase return — status ki jagah "Return" dikhta hai
        bg = AppColor.errorLight;   fg = AppColor.error;
        break;
      case 'cancelled':
        bg = AppColor.errorLight;   fg = AppColor.error;
        break;
      default: // draft
        bg = AppColor.grey100;      fg = AppColor.grey600;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: fg.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: fg)),
            const SizedBox(width: 5),
            Text(status[0].toUpperCase() + status.substring(1),
                style: TextStyle(fontSize: 11.5,
                    fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
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
    final canEdit     = widget.onEdit != null && o.canEdit && !isCancelled;

    final rowBg = _isHovered
        ? AppColor.primary.withOpacity(0.03)
        : (o.isReturn
            ? AppColor.errorLight.withOpacity(0.35)
            : Colors.transparent);

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      cursor:          SystemMouseCursors.click,
      onEnter: (_) { if (mounted) setState(() => _isHovered = true);  },
      onExit:  (_) { if (mounted) setState(() => _isHovered = false); },
      child: GestureDetector(
        onTap: widget.onView,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color:    rowBg,
          padding:  const EdgeInsets.symmetric(horizontal: 20),
          child: Opacity(
            opacity: isCancelled ? 0.55 : 1.0,
            child: Row(
              children: [
                // ── PO Number + date ──────────────────────
                Expanded(
                  flex: kPoColPo,
                  child: Column(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(o.poNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize:   14,
                                    fontWeight: FontWeight.w600,
                                    color: isCancelled
                                        ? AppColor.textSecondary
                                        : (o.isReturn
                                            ? AppColor.error
                                            : AppColor.primary),
                                    decoration: isCancelled
                                        ? TextDecoration.lineThrough
                                        : null)),
                          ),
                          if (o.isReturn) ...[
                            const SizedBox(width: 8),
                            const _ReturnBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${_fmtDate(o.orderDate)} · ${_fmtTime(o.createdAt)}',
                          style: TextStyle(fontSize: 11.5,
                              color: AppColor.textSecondary)),
                    ],
                  ),
                ),

                // ── Supplier ──────────────────────────────
                Expanded(
                  flex: kPoColSupplier,
                  child: Row(
                    children: [
                      _SupplierAvatar(order: o),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          mainAxisAlignment:  MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                (o.supplierCompany?.isNotEmpty ?? false)
                                    ? o.supplierCompany!
                                    : (o.supplierName ?? '—'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.textPrimary)),
                            if (o.supplierCompany?.isNotEmpty ?? false)
                              Text(o.supplierName ?? '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11.5,
                                      color: AppColor.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Items ─────────────────────────────────
                Expanded(
                  flex: kPoColItems,
                  child: Column(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${o.items.length} items',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColor.textPrimary)),
                      Text('${_fmtQty(_totalQty(o))} qty',
                          style: TextStyle(fontSize: 11.5,
                              color: o.isReturn
                                  ? AppColor.error
                                  : AppColor.textSecondary)),
                    ],
                  ),
                ),

                // ── Status ────────────────────────────────
                Expanded(
                  flex: kPoColStatus,
                  child: PoStatusBadge(
                      status: o.isReturn ? 'return' : o.status),
                ),

                // ── Total (right aligned) ─────────────────
                Expanded(
                  flex: kPoColTotal,
                  child: Text(
                    o.isReturn
                        ? '−Rs ${o.totalAmount.abs().pkrFormat}'
                        : 'Rs ${o.totalAmount.pkrFormat}',
                    textAlign: TextAlign.right,
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w600,
                        color: o.isReturn
                            ? AppColor.error
                            : AppColor.textPrimary,
                        decoration: isCancelled
                            ? TextDecoration.lineThrough
                            : null),
                  ),
                ),

                // ── Actions ───────────────────────────────
                SizedBox(
                  width: kPoColActions,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionBtn(
                        icon:    Icons.visibility_outlined,
                        tooltip: 'Detail',
                        onTap:   widget.onView,
                      ),
                      if (canEdit)
                        _ActionBtn(
                          icon:    Icons.edit_outlined,
                          tooltip: 'Edit',
                          onTap:   widget.onEdit!,
                        ),
                      _MoreMenu(
                        order:  o,
                        onView: widget.onView,
                        onEdit: canEdit ? widget.onEdit : null,
                      ),
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

  static double _totalQty(PurchaseOrderModel o) =>
      o.items.fold(0.0, (sum, i) => sum + i.quantityOrdered);

  static String _fmtQty(double q) => q == q.roundToDouble()
      ? q.toInt().toString()
      : q.toStringAsFixed(2);

  String _fmtDate(DateTime dt) {
    final local  = dt.toLocal();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${local.day.toString().padLeft(2, '0')} '
        '${months[local.month - 1]} ${local.year}';
  }

  String _fmtTime(DateTime dt) {
    // ✅ toLocal() — UTC se PST (+5) mein convert karega
    final local  = dt.toLocal();
    final h      = local.hour;
    final m      = local.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }
}

// ─────────────────────────────────────────────────────────────
// RETURN BADGE
// ─────────────────────────────────────────────────────────────

class _ReturnBadge extends StatelessWidget {
  const _ReturnBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        AppColor.errorLight,
        borderRadius: BorderRadius.circular(4),
        border:       Border.all(color: AppColor.error.withOpacity(0.4)),
      ),
      child: Text('RETURN',
          style: TextStyle(fontSize: 9.5,
              fontWeight:    FontWeight.w700,
              letterSpacing: 0.5,
              color:         AppColor.error)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPLIER AVATAR — gol initials
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
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: _avatarColor(initials),
        shape: BoxShape.circle,
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
// ACTION BUTTON — ghost icon
// ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final String       tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 32, height: 32,
          child: Icon(icon, size: 18, color: AppColor.grey600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MORE (⋯) MENU
// ─────────────────────────────────────────────────────────────

class _MoreMenu extends StatelessWidget {
  final PurchaseOrderModel order;
  final VoidCallback       onView;
  final VoidCallback?      onEdit;

  const _MoreMenu({
    required this.order,
    required this.onView,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32, height: 32,
      child: PopupMenuButton<String>(
        tooltip:   'More',
        padding:   EdgeInsets.zero,
        iconSize:  18,
        icon:      Icon(Icons.more_vert_rounded, color: AppColor.grey600),
        color:     AppColor.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColor.grey200)),
        onSelected: (v) {
          switch (v) {
            case 'view': onView(); break;
            case 'edit': onEdit?.call(); break;
            case 'copy':
              Clipboard.setData(ClipboardData(text: order.poNumber));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:  Text('${order.poNumber} copy ho gaya'),
                duration: const Duration(seconds: 2),
              ));
              break;
          }
        },
        itemBuilder: (_) => [
          _item('view', Icons.visibility_outlined, 'Detail dekhein'),
          if (onEdit != null)
            _item('edit', Icons.edit_outlined, 'Edit karein'),
          _item('copy', Icons.copy_rounded, 'PO number copy'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _item(String v, IconData icon, String label) =>
      PopupMenuItem<String>(
        value:  v,
        height: 38,
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColor.textSecondary),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(fontSize: 13, color: AppColor.textPrimary)),
          ],
        ),
      );
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
