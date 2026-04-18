import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class CustomerTypeBadge extends StatelessWidget {
  final String customerType;
  const CustomerTypeBadge({super.key, required this.customerType});

  Color get _color {
    switch (customerType) {
      case 'credit':    return AppColor.warning;
      case 'wholesale': return AppColor.info;
      default:          return AppColor.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        customerType[0].toUpperCase() + customerType.substring(1),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}
