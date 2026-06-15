import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class CounterEmptyStateWidget extends StatelessWidget {
  const CounterEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.point_of_sale_outlined, size: 64, color: AppColor.grey300),
          SizedBox(height: 16),
          Text(
            'No counters found',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Use the New Counter button to add one',
            style: TextStyle(fontSize: 13, color: AppColor.textHint),
          ),
        ],
      ),
    );
  }
}