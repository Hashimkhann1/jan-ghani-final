import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class CustomerEmptyState extends StatelessWidget {
  final bool isSearching;
  const CustomerEmptyState({super.key, required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded,
            size: 56, color: AppColor.grey300,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching ? 'Koi customer nahi mila' : 'Abhi tak koi customer nahi',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            isSearching ? 'Search ya filter change karein' : 'New Customer button se add karein',
            style: const TextStyle(
                fontSize: 13, color: AppColor.textHint),
          ),
        ],
      ),
    );
  }
}