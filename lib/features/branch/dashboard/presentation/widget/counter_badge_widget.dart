import 'package:flutter/material.dart';

class CountBadge extends StatelessWidget {
  final String label;
  final Color  color;
  final Color  bg;
  const CountBadge(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize:   10,
              fontWeight: FontWeight.w700,
              color:      color)),
    );
  }
}
