import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_provider.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';

class AssignStockCartSummary extends ConsumerWidget {
  const AssignStockCartSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignStockProvider);
    final notifier = ref.read(assignStockProvider.notifier);
    final auth = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border(top: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          // Summary stats
          Expanded(
            child: Row(
              children: [
                _StatChip(
                  label: 'Items',
                  value: '${state.totalItems}',
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Total Qty',
                  value: state.totalQty.toStringAsFixed(2),
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Grand Total',
                  value: 'Rs ${state.grandTotal.toStringAsFixed(0)}',
                  color: AppColor.success,
                ),
              ],
            ),
          ),

          // Error message
          if (state.errorMessage != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColor.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: AppColor.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.error),
                      ),
                    ),
                    GestureDetector(
                      onTap: notifier.clearError,
                      child: const Icon(Icons.close,
                          size: 14, color: AppColor.error),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(width: 12),

          // Assign Stock button
          Flexible(
            
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140),
              child: ElevatedButton.icon(
                onPressed: state.canSave && !state.isSaving
                    ? () async {
                  final success = await notifier.assignStock(
                    assignedById: auth.user?.id ?? '',
                    assignedByName:
                    auth.user?.fullName ?? 'Warehouse',
                  );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('Stock assign ho gaya!'),
                          ],
                        ),
                        backgroundColor: AppColor.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                }
                    : null,
                icon: state.isSaving
                    ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  state.isSaving ? 'Saving...' : 'Assign Stock',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.canSave
                      ? AppColor.primary
                      : AppColor.grey300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}