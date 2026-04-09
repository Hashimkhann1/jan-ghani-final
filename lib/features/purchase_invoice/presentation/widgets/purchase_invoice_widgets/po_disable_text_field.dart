// =============================================================
// po_disable_text_field.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class PoDisabledTextField extends StatelessWidget {
  final String   label, value;
  final IconData icon;

  const PoDisabledTextField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize:   10,
                fontWeight: FontWeight.w600,
                color:      AppColor.textSecondary)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          enabled:      false,
          style: const TextStyle(
              fontSize: 12, color: AppColor.textSecondary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                size: 16, color: AppColor.grey400),
            filled:    true,
            fillColor: AppColor.grey100,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 10),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColor.grey200),
            ),
          ),
        ),
      ],
    );
  }
}
