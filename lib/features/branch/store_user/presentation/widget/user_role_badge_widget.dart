import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class UserRoleBadge extends StatelessWidget {
  final String role;
  const UserRoleBadge({super.key, required this.role});

  Color get _color {
    switch (role) {
      case 'store_owner':   return AppColor.error;
      case 'store_manager': return AppColor.primary;
      case 'stock_officer': return AppColor.info;
      default:              return AppColor.grey500;
    }
  }

  String get _label {
    switch (role) {
      case 'store_owner':   return 'Owner';
      case 'store_manager': return 'Manager';
      case 'stock_officer': return 'Stock Officer';
      default:              return 'Cashier';
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
      child: Text(_label,
          style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      _color)),
    );
  }
}