// Updated on 2026-10-15 10:24 AM

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';

class UserEmptyStateWidget extends StatelessWidget {
  final bool isSearching;
  const UserEmptyStateWidget({super.key, this.isSearching = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            size:  64,
            color: WarehouseAppColor.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Koi user nahi mila' : 'Koi user nahi hai',
            style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      WarehouseAppColor.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Search query change karein'
                : 'New User button se user add karein',
            style: const TextStyle(
                fontSize: 13, color: WarehouseAppColor.textHint),
          ),
        ],
      ),
    );
  }
}