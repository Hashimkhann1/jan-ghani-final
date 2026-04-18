

import 'package:flutter/material.dart';

class AmountBadge extends StatelessWidget {
  final double amount;
  final Color  color;
  const AmountBadge({required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Rs ${amount.toStringAsFixed(0)}',
        style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w700,
            color:      color),
      ),
    );
  }
}