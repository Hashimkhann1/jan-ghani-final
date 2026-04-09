// =============================================================
// po_product_list_panel.dart
// Left panel — products list with search
// Sale Invoice ke ProductListPanel ki tarah
// Double tap → cart mein add
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';


class PoProductListPanel extends ConsumerWidget {
  const PoProductListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(purchaseInvoiceProvider);
    final notifier = ref.read(purchaseInvoiceProvider.notifier);
    final products = state.filteredProducts;

    return Container(
      decoration: const BoxDecoration(
        color:  AppColor.white,
        border: Border(right: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(
        children: [
          _SearchBar(onChanged: notifier.updateSearch),
          Expanded(
            child: products.isEmpty
                ? const _EmptyProducts()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: products.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductListItem(
                        product:     product,
                        onDoubleTap: () =>
                            notifier.addToCart(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ──────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color:  AppColor.white,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
            fontSize: 13, color: AppColor.textPrimary),
        cursorHeight: 14,
        decoration: InputDecoration(
          hintText:  'Search by name or SKU...',
          hintStyle: const TextStyle(
              fontSize: 13, color: AppColor.textHint),
          prefixIcon: const Icon(Icons.search,
              size: 18, color: AppColor.grey500),
          filled:    true,
          fillColor: AppColor.grey100,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 14),
          border:        InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// ─── Product List Item ────────────────────────────────────────

class _ProductListItem extends StatefulWidget {
  final PoProduct    product;
  final VoidCallback onDoubleTap;

  const _ProductListItem({
    required this.product,
    required this.onDoubleTap,
  });

  @override
  State<_ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<_ProductListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onDoubleTap();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool inStock = product.stock > 0;

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:        AppColor.white,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: AppColor.grey200),
          ),
          child: Row(
            children: [
              // Product ID box
              Container(
                width:  38,
                height: 38,
                decoration: BoxDecoration(
                  color:        AppColor.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(product.id,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textSecondary)),
              ),
              const SizedBox(width: 10),

              // Name + category + cost
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary),
                        maxLines:  1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${product.category}  •  '
                      'Cost: Rs ${product.purchasePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppColor.textHint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Stock badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: inStock
                      ? AppColor.success.withOpacity(0.10)
                      : AppColor.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inStock ? '${product.stock.toInt()}' : 'Out',
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.w600,
                    color: inStock
                        ? AppColor.success : AppColor.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty ───────────────────────────────────────────────────

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 40, color: AppColor.grey300),
          SizedBox(height: 8),
          Text('No products found',
              style: TextStyle(
                  fontSize: 13, color: AppColor.textHint)),
        ],
      ),
    );
  }
}
