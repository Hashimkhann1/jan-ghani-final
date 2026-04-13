// =============================================================
// po_product_list_panel.dart  — UPDATED (real products from DB)
// Left panel — products list with search
// Double tap → cart mein add
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:jan_ghani_final/features/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';
import 'package:jan_ghani_final/features/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:jan_ghani_final/features/warehouse_stock_inventory/presentation/provider/product_provider.dart';

class PoProductListPanel extends ConsumerWidget {
  const PoProductListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poState      = ref.watch(purchaseInvoiceProvider);
    final poNotifier   = ref.read(purchaseInvoiceProvider.notifier);
    final productState = ref.watch(productProvider);

    // Search query poState se leke products ko filter karo
    final allProducts = productState.allProducts
        .where((p) => p.isActive && p.deletedAt == null)
        .toList();

    final query = poState.searchQuery.toLowerCase();
    final filtered = query.isEmpty
        ? allProducts
        : allProducts.where((p) =>
    p.name.toLowerCase().contains(query) ||
        p.sku.toLowerCase().contains(query) ||
        (p.barcode?.toLowerCase().contains(query) ?? false)).toList();

    return Container(
      decoration: const BoxDecoration(
        color:  AppColor.white,
        border: Border(right: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(
        children: [
          _SearchBar(onChanged: poNotifier.updateSearch),

          // Loading indicator
          if (productState.isLoading)
            const LinearProgressIndicator(minHeight: 2),

          Expanded(
            child: productState.isLoading
                ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2))
                : filtered.isEmpty
                ? const _EmptyProducts()
                : ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final product = filtered[index];
                return _ProductListItem(
                  product: product,
                  onDoubleTap: () {
                    // ProductModel → PoProduct convert
                    final poProduct = PoProduct(
                      id:            product.id,
                      name:          product.name,
                      category:      product.categoryName ?? '-',
                      sku:           product.sku,
                      purchasePrice: product.costPrice,
                      salePrice:     product.sellingPrice,
                      stock:         product.quantity,
                    );
                    poNotifier.addToCart(poProduct);
                  },
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
          hintText:  'Name, SKU ya barcode se search...',
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
  final ProductModel product;
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
    final p       = widget.product;
    final inStock = p.quantity > 0;

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
              // SKU badge
              // Container(
              //   constraints: const BoxConstraints(
              //       minWidth: 48, maxWidth: 70),
              //   height: 38,
              //   padding: const EdgeInsets.symmetric(horizontal: 4),
              //   decoration: BoxDecoration(
              //     color:        AppColor.grey100,
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   alignment: Alignment.center,
              //   child: Text(
              //     "Rs ${p.sellingPrice.toString()}",
              //     style: const TextStyle(
              //         fontSize: 12,
              //         fontWeight: FontWeight.w700,
              //         color: AppColor.textSecondary),
              //     textAlign: TextAlign.center,
              //     maxLines:  2,
              //     overflow:  TextOverflow.ellipsis,
              //   ),
              // ),
              // const SizedBox(width: 10),

              // Name + category + cost
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                          fontSize:14,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.categoryName ?? '-'}  •  '
                          ' Rs ${p.costPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13,fontWeight: FontWeight.w500, color: AppColor.textSecondary),
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
                  inStock
                      ? '${p.quantity.toStringAsFixed(2)} ${p.unitOfMeasure}'
                      : 'Out',
                  style: TextStyle(
                    fontSize:   13,
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
          Text('Koi product nahi mila',
              style: TextStyle(
                  fontSize: 13, color: AppColor.textHint)),
        ],
      ),
    );
  }
}