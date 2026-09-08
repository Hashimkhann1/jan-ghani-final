import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';

class CustomerActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  /// Diya jaye to Material [icon] ki jagah `assets/branch_icons/<iconAsset>.svg`.
  final String? iconAsset;

  const CustomerActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: iconAsset != null
              ? AppIcon(iconAsset!, size: 16, color: color)
              : Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
