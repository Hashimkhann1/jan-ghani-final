import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6366F1),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ],
    );
  }
}
