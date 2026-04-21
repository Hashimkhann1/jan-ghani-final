// lib/features/branch/sale_invoice/presentation/widget/disable_text_field_widget.dart
// ── FIX: initialValue ki jagah controller use karo takay value update ho ──

import 'package:flutter/material.dart';
import '../../../../../core/color/app_color.dart';

class DisabledTextField extends StatefulWidget {
  final String   label;
  final String   value;
  final IconData icon;

  const DisabledTextField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  State<DisabledTextField> createState() => _DisabledTextFieldState();
}

class _DisabledTextFieldState extends State<DisabledTextField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(DisabledTextField old) {
    super.didUpdateWidget(old);
    // Value change hone pe controller update karo
    if (old.value != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.label,
        style: const TextStyle(
            fontSize:   10,
            fontWeight: FontWeight.w600,
            color:      AppColor.textSecondary),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: _ctrl,
        enabled:    false,
        style: const TextStyle(
            fontSize: 12, color: AppColor.textSecondary),
        decoration: InputDecoration(
          prefixIcon:
          Icon(widget.icon, size: 16, color: AppColor.grey400),
          filled:     true,
          fillColor:  AppColor.grey100,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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