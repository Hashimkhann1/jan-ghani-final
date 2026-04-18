import 'package:flutter/material.dart';

class AmountLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const AmountLine(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style:
            const TextStyle(fontSize: 11, color: Color(0xFF6C7280))),
        const SizedBox(width: 16),
        Text(value,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1D23))),
      ],
    );
  }
}
