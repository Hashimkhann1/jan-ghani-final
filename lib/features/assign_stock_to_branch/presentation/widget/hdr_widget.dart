import 'package:flutter/material.dart';

class Hdr extends StatelessWidget {
  final String label;
  final bool center;
  final bool right;
  const Hdr({required this.label, this.center = false, this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: center
          ? TextAlign.center
          : right
          ? TextAlign.right
          : TextAlign.left,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6C7280),
          letterSpacing: 0.4),
    );
  }
}
