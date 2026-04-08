import 'package:flutter/material.dart';

class TabBadge extends StatelessWidget {
  final int count;
  final bool active;
  const TabBadge({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : const Color(0xFF6C7280))),
    );
  }
}
