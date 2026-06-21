import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';

/// Dashboard ke top horizontal-scroll stat cards.
class InstallmentStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final IconData badgeIcon;
  final Color badgeColor;

  const InstallmentStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeIcon,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColor.textSecondary,
            ),
          ),
          6.hBox,
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          6.hBox,
          Row(
            children: [
              Icon(badgeIcon, size: 13, color: badgeColor),
              3.wBox,
              Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
