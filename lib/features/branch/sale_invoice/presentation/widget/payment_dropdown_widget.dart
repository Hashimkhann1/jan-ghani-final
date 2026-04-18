

import 'package:flutter/material.dart';

import '../../../../../core/color/app_color.dart';

class DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColor.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      DropdownButtonFormField<T>(
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        style:
        const TextStyle(fontSize: 12, color: AppColor.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 16, color: AppColor.grey500),
          filled: true,
          fillColor: AppColor.grey100,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColor.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item),
              style: const TextStyle(
                  fontSize: 12, color: AppColor.textPrimary),
              overflow: TextOverflow.ellipsis),
        ))
            .toList(),
      ),
    ]);
  }
}
