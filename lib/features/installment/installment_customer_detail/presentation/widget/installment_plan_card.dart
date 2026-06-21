import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/installment/installment_customer_detail/domain/customer_detail_helpers.dart';
import 'package:jan_ghani_final/features/installment/installment_dashboard/domain/installment_customer.dart';

/// Customer Detail screen par ek product plan ka card.
/// Tap par (baad mein) Plan Detail screen khulegi.
class InstallmentPlanCard extends StatelessWidget {
  final InstallmentPlan plan;
  final VoidCallback? onTap;

  const InstallmentPlanCard({
    super.key,
    required this.plan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = plan.status;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColor.grey300),
        ),
        child: Column(
          children: [
            // Top status accent.
            // Container(
            //   height: 4,
            //   decoration: BoxDecoration(
            //     color: status.color,
            //     borderRadius:
            //         const BorderRadius.vertical(top: Radius.circular(13)),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          plan.product,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                      8.wBox,
                      _StatusBadge(status: status),
                    ],
                  ),
                  4.hBox,
                  Text(
                    'Started ${formatDmy(plan.startDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  12.hBox,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: plan.progress,
                      minHeight: 6,
                      backgroundColor: AppColor.grey200,
                      valueColor: AlwaysStoppedAnimation<Color>(status.color),
                    ),
                  ),
                  10.hBox,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs ${plan.remaining.pkrFormat} remaining',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      Text(
                        plan.paidLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: status.color,
                        ),
                      ),
                    ],
                  ),
                  10.hBox,
                  Container(height: 1, color: AppColor.grey100),
                  10.hBox,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'View installments',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primary,
                        ),
                      ),
                      2.wBox,
                      const Icon(Icons.arrow_forward,
                          size: 14, color: AppColor.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final InstallmentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: status.color,
        ),
      ),
    );
  }
}
