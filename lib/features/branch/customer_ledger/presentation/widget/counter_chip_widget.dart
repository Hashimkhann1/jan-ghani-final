import 'package:flutter/material.dart';

import '../../../../../core/color/app_color.dart';

class CounterChip extends StatelessWidget {
  final String? counterName;
  const CounterChip({this.counterName});

  @override
  Widget build(BuildContext context) {
    final isAssigned = counterName != null;
    final color      = isAssigned ? AppColor.primary : AppColor.grey400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.point_of_sale_outlined, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            counterName ?? '—',
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      color),
          ),
        ],
      ),
    );
  }
}
