import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/color/app_color.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';

class ProductListPanel extends ConsumerWidget {
  const ProductListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleInvoiceProvider);
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final products = state.filteredProducts;

    return Container(
      decoration: const BoxDecoration(
        color: AppColor.white,
        border: Border(right: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(
        children: [
          _SearchBar(onChanged: notifier.updateSearch),
          Expanded(
            child: products.isEmpty ? const _EmptyProducts() : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductListItem(
                  product: product,
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

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColor.white,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
        cursorHeight: 14,
        decoration: InputDecoration(
          hintText: 'Search by name or barcode...',    // ← updated hint
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
    );
  }
}

// ─── Product List Item ────────────────────────────────────────────────────────

class _ProductListItem extends StatefulWidget {
  final Product product;
  final VoidCallback onDoubleTap;

  // ─── inCart REMOVED — ab selected indicator nahi dikhana ───
  const _ProductListItem({required this.product, required this.onDoubleTap});

  @override
  State<_ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<_ProductListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColor.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColor.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(widget.product.id,style: TextStyle(fontSize: 12),)),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // ── Stock badge ──────────────────────────────────────────
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: inStock ? AppColor.success.withOpacity(0.10) : AppColor.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inStock ? '${product.stock}' : 'Out',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: inStock ? AppColor.success : AppColor.error,
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
          Text('No products found', style: TextStyle(fontSize: 13, color: AppColor.textHint)),
        ],
      ),
    );
  }
}