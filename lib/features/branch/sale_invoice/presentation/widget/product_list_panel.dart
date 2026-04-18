import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';

import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';
import '../provider/sale_return_provider.dart';

class ProductListPanel extends ConsumerWidget {
  const ProductListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceState = ref.watch(saleInvoiceProvider);
    final isReturn     = invoiceState.saleType == SaleType.saleReturn;
    final searchQuery  = isReturn
        ? ref.watch(saleReturnProvider).searchQuery
        : invoiceState.searchQuery;

    final notifier    = ref.read(saleInvoiceProvider.notifier);
    final retNotifier = ref.read(saleReturnProvider.notifier);

    final allProducts = ref.watch(branchStockProvider).allProducts;
    final products    = searchQuery.isEmpty
        ? allProducts
        : allProducts.where((p) =>
    p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        p.sku.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (p.barcode?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false))
        .toList();

    final accent = isReturn ? AppColor.error : AppColor.primary;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        border: Border(
            right: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColor.grey200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 14, color: accent),
                    const SizedBox(width: 6),
                    Text('Products',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${products.length}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search
                TextField(
                  onChanged: isReturn
                      ? retNotifier.updateSearch
                      : notifier.updateSearch,
                  style: const TextStyle(
                      fontSize: 13, color: AppColor.textPrimary),
                  cursorHeight: 14,
                  decoration: InputDecoration(
                    hintText: 'Search name, SKU, barcode...',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: AppColor.textHint),
                    prefixIcon: Icon(Icons.search,
                        size: 16, color: AppColor.grey400),
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:   BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: products.isEmpty
                ? _EmptyProducts()
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductCard(
                  index:      index + 1,
                  product:    product,
                  isReturn:   isReturn,
                  onDoubleTap: () => isReturn
                      ? retNotifier.addToCart(product)
                      : notifier.addToCart(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final BranchStockModel product;
  final VoidCallback     onDoubleTap;
  final bool             isReturn;
  final int              index;

  const _ProductCard({
    required this.product,
    required this.onDoubleTap,
    required this.isReturn,
    required this.index,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
    final accent  = widget.isReturn ? AppColor.error : AppColor.primary;
    final stockColor = p.quantity <= 0
        ? AppColor.error
        : p.quantity <= 5
        ? AppColor.warning
        : AppColor.success;

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: inStock
                    ? AppColor.grey200
                    : AppColor.error.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset:     const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Index
              Container(
                width:  22,
                height: 22,
                decoration: BoxDecoration(
                  color:        accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text('${widget.index}',
                      style: TextStyle(
                          fontSize:   9,
                          fontWeight: FontWeight.w700,
                          color:      accent)),
                ),
              ),
              const SizedBox(width: 8),

              // Name + SKU
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color: inStock
                                ? AppColor.textPrimary
                                : AppColor.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(p.sku,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColor.textHint)),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Price + Stock
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs ${p.sellingPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w800,
                        color:      accent),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: stockColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${p.quantity.toStringAsFixed(p.quantity % 1 == 0 ? 0 : 1)}',
                      style: TextStyle(
                          fontSize:   9,
                          fontWeight: FontWeight.w700,
                          color:      stockColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded,
            size: 40, color: AppColor.grey300),
        SizedBox(height: 8),
        Text('No products found',
            style: TextStyle(
                fontSize: 13, color: AppColor.textHint)),
      ],
    ),
  );
}