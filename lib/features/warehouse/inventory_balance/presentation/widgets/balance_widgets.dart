// =============================================================
// balance_widgets.dart
// Reusable small widgets for Inventory Balance feature:
//   • BalanceStatusBadge  — pill badge with status label+color
//   • HighVarianceBadge   — small red banner "High variance Rs X"
//   • FourNumberRow       — 4-number card (Sys@count, Physical, Δ, PKR)
//   • DeltaText           — colored delta text (green +, red -)
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';

import '../../domain/balance_status.dart';

class BalanceStatusBadge extends StatelessWidget {
  final BalanceStatus status;
  final double fontSize;
  const BalanceStatusBadge({super.key, required this.status, this.fontSize = 10.5});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: status.color, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(status.label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: status.color,
              )),
        ],
      ),
    );
  }
}

class HighVarianceBadge extends StatelessWidget {
  final double rupeeImpact;
  const HighVarianceBadge({super.key, required this.rupeeImpact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        AppColor.errorLight,
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: AppColor.error.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 12, color: AppColor.error),
          const SizedBox(width: 4),
          Text('High variance · Rs ${rupeeImpact.pkrFormat}',
              style: const TextStyle(
                fontSize:   10.5,
                fontWeight: FontWeight.w700,
                color:      AppColor.error,
              )),
        ],
      ),
    );
  }
}

class DeltaText extends StatelessWidget {
  final double delta;
  final double? fontSize;
  final FontWeight? weight;
  const DeltaText({super.key, required this.delta, this.fontSize, this.weight});

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    final sign = positive ? '+' : '−';
    final abs = delta.abs();
    final txt = abs % 1 == 0 ? abs.toInt().toString() : abs.toStringAsFixed(2);
    return Text(
      '$sign$txt',
      style: TextStyle(
        fontSize:   fontSize ?? 13,
        fontWeight: weight   ?? FontWeight.w700,
        color:      positive ? AppColor.success : AppColor.error,
      ),
    );
  }
}

// 4-number card — layout: 4 columns (label above value).
class FourNumberRow extends StatelessWidget {
  final double systemAtCount;
  final double physical;
  final double delta;
  final double? currentSystemNow; // optional (available in report + reviewer only)

  const FourNumberRow({
    super.key,
    required this.systemAtCount,
    required this.physical,
    required this.delta,
    this.currentSystemNow,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, Widget value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 10, color: AppColor.textSecondary,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 3),
          value,
        ],
      ),
    );

    String fmt(double v) =>
        v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

    return Row(
      children: [
        cell('SYS @ COUNT', Text(fmt(systemAtCount),
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ))),
        cell('PHYSICAL', Text(fmt(physical),
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ))),
        cell('DELTA', DeltaText(delta: delta, fontSize: 14)),
        if (currentSystemNow != null)
          cell('SYS NOW', Text(fmt(currentSystemNow!),
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ))),
      ],
    );
  }
}
