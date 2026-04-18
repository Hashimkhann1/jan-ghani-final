import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/customer_model.dart';

class CustomerBalanceBadge extends StatelessWidget {
  final CustomerModel customer;
  const CustomerBalanceBadge({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final color =
    customer.hasBalance ? AppColor.error : AppColor.grey500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(customer.balanceLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}