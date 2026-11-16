// Updated on 2026-11-16 09:59 AM
// =============================================================
// branch_return_parts.dart — Branch Returns ke chhote shared parts:
// date/qty format, status pill, result snackbar
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';

import '../../domain/branch_return_model.dart';

const _kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// `16 Nov 2026, 9:05 AM` — DateTime pehle se local (model `.toLocal()`).
String fmtReturnDate(DateTime d) {
  final l  = d.toLocal();
  final h  = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final mm = l.minute.toString().padLeft(2, '0');
  final ap = l.hour < 12 ? 'AM' : 'PM';
  return '${l.day.toString().padLeft(2, '0')} ${_kMonths[l.month - 1]} '
      '${l.year}, $h:$mm $ap';
}

/// Poori qty bina decimal, fractional (kg) 2 decimal tak.
String fmtReturnQty(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

class ReturnStatusPill extends StatelessWidget {
  final String status;
  const ReturnStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      'accepted' => ('Accepted', WarehouseAppColor.success, WarehouseAppColor.successLight),
      'rejected' => ('Rejected', WarehouseAppColor.error,   WarehouseAppColor.errorLight),
      _          => ('Pending',  WarehouseAppColor.warningDark, WarehouseAppColor.warningLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Right-bottom card snackbar (app ka pattern).
void showReturnSnack(BuildContext context, ReturnActionResult r) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final width = MediaQuery.of(context).size.width;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor:
          r.ok ? WarehouseAppColor.success : WarehouseAppColor.error,
      margin: EdgeInsets.only(
          left: width > 460 ? width - 440 : 16, right: 20, bottom: 20),
      duration: Duration(seconds: r.ok ? 3 : 6),
      content: Text(r.message,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: WarehouseAppColor.white)),
    ));
}
