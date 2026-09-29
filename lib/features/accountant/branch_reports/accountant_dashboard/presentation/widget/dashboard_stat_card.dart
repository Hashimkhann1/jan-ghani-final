import 'package:flutter/material.dart';

import '../../../../../../core/widget/app_icon.dart';

/// Branch dashboard ke SummaryCard jaisa card — white, shadow, rangeen
/// icon badge — plus ek optional [subtitle] line (e.g. Sale − Return).
class DashboardStatCard extends StatelessWidget {
  final String   title;
  final String   value;
  final String?  subtitle;
  final IconData icon;
  final String?  iconAsset;
  final Color    color;
  final Color    bgColor;
  final Color?   valueColor;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.subtitle,
    this.iconAsset,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: iconAsset != null
                    ? AppIcon(iconAsset!, color: color, size: 20)
                    : Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 12),
          FittedBox(
            fit:       BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize:   18,
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
  }
}
