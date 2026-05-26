import 'package:flutter/material.dart';

class ChipWidget extends StatelessWidget {
  final String label;
  final Color  color;
  final Color  bg;
  const ChipWidget(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize:   10,
              fontWeight: FontWeight.w500,
              color:      color)),
    );
  }
}