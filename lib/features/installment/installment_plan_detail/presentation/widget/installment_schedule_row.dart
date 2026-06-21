import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/installment/installment_plan_detail/domain/installment_schedule_item.dart';

/// Plan Detail ki schedule list ka ek row.
class InstallmentScheduleRow extends StatelessWidget {
  final InstallmentScheduleItem item;
  final bool isLast;

  const InstallmentScheduleRow({
    super.key,
    required this.item,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDue = item.status == ScheduleStatus.due;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        // Due row halki amber highlight + left accent.
        color: isDue ? AppColor.warningLight : AppColor.surface,
        border: Border(
          left: BorderSide(
            color: isDue ? AppColor.warningDark : AppColor.transparent,
            width: 3,
          ),
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColor.grey100),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Installment #${item.number}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isDue ? FontWeight.w700 : FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                ),
                2.hBox,
                Text(
                  planDetailDmy(item.dueDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${item.amount.pkrFormat}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              6.hBox,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: item.status.bgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: item.status.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
