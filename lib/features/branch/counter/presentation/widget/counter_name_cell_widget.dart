import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class CounterNameCellWidget extends StatelessWidget {
  const CounterNameCellWidget({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:        AppColor.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.point_of_sale_outlined,
            size:  15,
            color: AppColor.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}