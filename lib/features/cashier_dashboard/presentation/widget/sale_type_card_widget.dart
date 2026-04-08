import 'package:flutter/material.dart';

class SaleTypeCard extends StatelessWidget {
  final String label;
  final double amount;
  final int txnCount;
  final double maxAmount;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const SaleTypeCard({
    super.key,
    required this.label,
    required this.amount,
    required this.txnCount,
    required this.maxAmount,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (amount / maxAmount).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rs ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1D23)),
          ),
          const SizedBox(height: 2),
          Text('$txnCount transactions',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}