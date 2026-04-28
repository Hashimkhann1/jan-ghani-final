import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/branch_stock_model.dart';
import '../provider/branch_stock_inventory_provider.dart';

class DeleteStockDialog extends ConsumerWidget {
  final BranchStockModel product;
  const DeleteStockDialog({super.key, required this.product});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(inventoryPageProvider.notifier)
        .deleteProduct(product);

    if (context.mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('${product.name} deleted successfully'),
          backgroundColor: AppColor.success,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleting =
    ref.watch(inventoryPageProvider.select((s) => s.isMutating));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Warning Icon ──────────────────────────────────
              Container(
                width:  56,
                height: 56,
                decoration: BoxDecoration(
                  color:  AppColor.error.withValues(alpha: 0.1),
                  shape:  BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 28, color: AppColor.error),
              ),

              const SizedBox(height: 16),

              const Text('Delete Product',
                  style: TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.w700,
                      color:      AppColor.textPrimary)),

              const SizedBox(height: 10),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14,
                      color:    AppColor.textSecondary,
                      height:   1.5),
                  children: [
                    const TextSpan(text: 'Are you sure you want to delete '),
                    TextSpan(
                      text: '"${product.name}"',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color:      AppColor.textPrimary),
                    ),
                    const TextSpan(
                        text: '?\n\nThis action cannot be undone.'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Product Info Card ─────────────────────────────
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color:        AppColor.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow('SKU',        product.sku.isEmpty ? '—' : product.sku),
                    _InfoRow('Stock',      product.quantityLabel),
                    _InfoRow('Sale Price', product.sellingPriceLabel),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Buttons ───────────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isDeleting
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.textSecondary,
                      side: const BorderSide(color: AppColor.grey300),
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isDeleting
                        ? null
                        : () => _delete(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.error,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: isDeleting
                        ? const SizedBox(
                        width:  16,
                        height: 16,
                        child:  CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.delete_rounded, size: 18),
                    label:
                    Text(isDeleting ? 'Deleting...' : 'Delete'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12, color: AppColor.textSecondary)),
      const SizedBox(width: 8),
      Text(value,
          style: const TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      AppColor.textPrimary)),
    ]),
  );
}