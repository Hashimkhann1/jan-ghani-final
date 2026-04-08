import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class CustomerFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onTap;

  const CustomerFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap:        () => onTap(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        isSelected ? AppColor.primary : AppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(
              color: isSelected ? AppColor.primary : AppColor.grey300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColor.white : AppColor.textSecondary,
          ),
        ),
      ),
    );
  }
}