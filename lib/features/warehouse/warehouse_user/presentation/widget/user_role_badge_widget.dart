// Updated on 2026-10-15 10:24 AM

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';

class UserRoleBadge extends StatelessWidget {
  final String role;
  const UserRoleBadge({super.key, required this.role});

  Color get _color {
    switch (role) {
      case 'warehouse_owner':   return WarehouseAppColor.error;
      case 'warehouse_manager': return WarehouseAppColor.primary;
      case 'warehouse_staff':   return WarehouseAppColor.info;
      case 'data_entry':        return WarehouseAppColor.grey500;
      default:                  return WarehouseAppColor.grey500;
    }
  }

  String get _label {
    switch (role) {
      case 'warehouse_owner':   return 'Owner';
      case 'warehouse_manager': return 'Manager';
      case 'warehouse_staff':   return 'Staff';
      case 'data_entry':        return 'Data Entry';
      default:                  return role;
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
