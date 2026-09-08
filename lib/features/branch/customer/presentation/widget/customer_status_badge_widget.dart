import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/app_icon.dart';

class CustomerStatusBadge extends StatelessWidget {
  final bool isActive;
  const CustomerStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color   = isActive ? AppColor.success  : AppColor.grey400;
    final bgColor = isActive ? AppColor.successLight : AppColor.grey200;
    final label   = isActive ? 'Active' : 'Inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(isActive ? 'ic_active_check' : 'ic_inactive',
              size: 11, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}
