import 'package:flutter/material.dart';

import '../../../../../../core/widget/app_icon.dart';

/// Branch dashboard ke SummaryCard jaisa card — white, shadow, rangeen
/// icon badge — plus ek optional [subtitle] line (e.g. Sale − Return).
class DashboardStatCard extends StatelessWidget {
  final String   title;
  final String   value;
  final String?  subtitle;
  final IconData? icon;
  final String?  iconAsset;
  final Color    color;
  final Color?   bgColor;
  final Color?   valueColor;

  /// Chhota padding/fonts — mobile grids aur tang rows ke liye.
  final bool          compact;
  final bool          selected;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.icon,
    this.bgColor,
    this.subtitle,
    this.iconAsset,
    this.valueColor,
    this.compact  = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 16.0 : 20.0;
    final badge    = bgColor ?? color.withOpacity(0.12);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: selected ? Border.all(color: color, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 6 : 8),
                decoration: BoxDecoration(
                  color:        badge,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: iconAsset != null
                    ? AppIcon(iconAsset!, color: color, size: iconSize)
                    : Icon(icon ?? Icons.analytics_outlined,
                        color: color, size: iconSize),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize:   12,
                        color:      Color(0xFF6B7280),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          FittedBox(
            fit:       BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize:   compact ? 15 : 18,
                    fontWeight: FontWeight.w700,
                    color:      valueColor ?? const Color(0xFF1A1D23))),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize:   10.5,
                    color:      Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
    return onTap == null ? card : GestureDetector(onTap: onTap, child: card);
  }
}
