import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/provider/product_provider.dart';

class AssignStockProductListPanel extends ConsumerWidget {
  const AssignStockProductListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignStockProvider);
    final notifier = ref.read(assignStockProvider.notifier);
    final productState = ref.watch(productProvider);

    final allProducts = productState.allProducts
        .where((p) => p.isActive && p.deletedAt == null)
        .toList();

    final query = state.searchQuery.toLowerCase();
    final filtered = query.isEmpty
        ? allProducts
        : allProducts.where((p) =>
    p.name.toLowerCase().contains(query) ||
        p.sku.toLowerCase().contains(query) ||
        p.barcodes.any((b) => b.toLowerCase().contains(query))).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColor.white,
        border: Border(right: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColor.white,
              border: Border(bottom: BorderSide(color: AppColor.grey200)),
            ),
            child: TextField(
              onChanged: notifier.updateSearch,
              style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
              cursorHeight: 14,
              decoration: InputDecoration(
                hintText: 'Name, SKU ya barcode se search...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColor.grey500),
                filled: true,
                fillColor: AppColor.grey100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),

          if (productState.isLoading)
            const LinearProgressIndicator(minHeight: 2),

          Expanded(
            child: productState.isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : filtered.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 40, color: AppColor.grey300),
                  SizedBox(height: 8),
                  Text('Koi product nahi mila',
                      style: TextStyle(fontSize: 13, color: AppColor.textHint)),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final product = filtered[index];
                final inCart = state.cartItems
                    .any((i) => i.productId == product.id);
                return _ProductItem(
                  product: product,
                  inCart: inCart,
                  onDoubleTap: () => notifier.addToCart(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductItem extends StatefulWidget {
  final ProductModel product;
  final bool inCart;
  final VoidCallback onDoubleTap;

  const _ProductItem({
    required this.product,
    required this.inCart,
    required this.onDoubleTap,
  });

  @override
  State<_ProductItem> createState() => _ProductItemState();
}

class _ProductItemState extends State<_ProductItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final inStock = p.quantity > 0;

    return GestureDetector(
      onDoubleTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onDoubleTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.inCart
                ? AppColor.primary.withOpacity(0.05)
                : AppColor.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.inCart
                  ? AppColor.primary.withOpacity(0.4)
                  : AppColor.grey200,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${p.categoryName ?? '-'}  •  Rs ${p.purchasePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColor.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.inCart)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Added',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primary)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: inStock
                        ? AppColor.success.withOpacity(0.10)
                        : AppColor.error.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    inStock
                        ? '${p.quantity.toStringAsFixed(2)} ${p.unitOfMeasure}'
                        : 'Out',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: inStock ? AppColor.success : AppColor.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}