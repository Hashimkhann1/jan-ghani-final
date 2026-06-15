import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class CounterDateCellWidget extends StatelessWidget {
  const CounterDateCellWidget({super.key, required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size:  13,
          color: AppColor.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          date,
          style: const TextStyle(fontSize: 13, color: AppColor.textSecondary),
        ),
      ],
    );
  }
}