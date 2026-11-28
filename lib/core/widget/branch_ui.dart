// Branch screens ke mushtarka UI hisse: heading, stat card, table box,
// raqam ka format. Sab screens ek jaisi dikhein is liye yahan se lein.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/color/branch_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';

final _money = NumberFormat('#,##0.##');

/// 4499301.64 → "Rs 4,499,301.64", 3390.0 → "Rs 3,390".
String branchMoney(num value) => 'Rs ${_money.format(value)}';

/// Screen ki AppBar: title + neeche chhoti line, left par.
class BranchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String       title;
  final String       subtitle;
  final List<Widget> actions;

  const BranchAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
        centerTitle:   false,
        toolbarHeight: 64,
        titleSpacing:  16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w400,
                    color:      AppColor.textSecondary)),
          ],
        ),
        actions: [...actions, const SizedBox(width: 16)],
      );
}

/// AppBar ka refresh button.
class BranchRefreshButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String       tooltip;
  const BranchRefreshButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Refresh',
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          onPressed: onPressed,
          tooltip:   tooltip,
          icon: const AppIcon('ic_refresh',
              size: 20, color: AppColor.textSecondary),
        ),
      );
}

/// AppBar ka bada action button.
class BranchActionButton extends StatelessWidget {
  final String        label;
  final String        iconAsset;
  final VoidCallback? onPressed;
  final Color         color;
  final Color         iconColor;

  const BranchActionButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onPressed,
    this.color     = BranchColor.navy,
    this.iconColor = BranchColor.accent,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation:       0,
            minimumSize:     const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          icon: AppIcon(iconAsset,
              size: 18,
              color: onPressed == null ? Colors.white : iconColor),
          label: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
}

/// Upar wala summary card. `Row` ke andar istemal karein.
class BranchStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String iconAsset;
  final Color  color;

  const BranchStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.iconAsset,
    this.color = BranchColor.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: BranchColor.line),
        ),
        child: Row(
          children: [
            Container(
              width:  42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(iconAsset, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w500,
                          color:      AppColor.textSecondary)),
                  const SizedBox(height: 3),
                  // Badi raqam chhoti screen par kat'ne ke bajaye sikur jaye.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: const TextStyle(
                            fontSize:   20,
                            fontWeight: FontWeight.w800,
                            color:      BranchColor.navy)),
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

/// Table ka safed, gol corners wala box.
class BranchTableCard extends StatelessWidget {
  final Widget child;
  const BranchTableCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        // Border upar, warna navy header usay dhak deta hai.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: BranchColor.line),
        ),
        child: child,
      );
}

/// Table ki raqam. Zero halka grey, taake asal raqam nazar mein aaye.
class BranchAmount extends StatelessWidget {
  final num    amount;
  final Color  color;
  final bool   isBold;
  const BranchAmount(
    this.amount, {
    super.key,
    this.color  = BranchColor.navy,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = amount == 0;
    return Text(branchMoney(amount),
        style: TextStyle(
            fontSize:   13,
            fontWeight: isBold && !isZero ? FontWeight.w700 : FontWeight.w500,
            color:      isZero ? AppColor.grey400 : color,
            fontFeatures: const [FontFeature.tabularFigures()]));
  }
}
