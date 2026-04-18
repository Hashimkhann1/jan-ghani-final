import 'package:flutter/material.dart';

class MiniTag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const MiniTag(
      {required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
