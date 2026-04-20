// lib/features/branch/sale_invoice/presentation/widget/product_list_panel.dart
// ── MODIFIED: Barcode scanner support added ────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';
import '../provider/sale_return_provider.dart';
import '../screen/sale_invoice_screen.dart' show posSearchFocusProvider, searchFocusCallbackProvider;

class ProductListPanel extends ConsumerStatefulWidget {
  const ProductListPanel({super.key});

  @override
  ConsumerState<ProductListPanel> createState() => _ProductListPanelState();
}

class _ProductListPanelState extends ConsumerState<ProductListPanel> {
  final _searchCtrl = TextEditingController();
  // _searchFocus — posSearchFocusProvider se milega (reliable shortcut support)
  FocusNode? _searchFocusFromProvider;

  // ── Barcode scanner detection ─────────────────────────────────
  // Barcode scanner characters bohot fast aate hain (<30ms gap)
  DateTime?     _lastKeyTime;
  final _buffer = StringBuffer();
  bool          _isScannerInput = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    // FocusNode provider se sync karo — post frame pe (widget attach hone ke baad)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // posSearchFocusProvider ka FocusNode seedha TextField ko assign karo
      // Yeh initState ke baad hoga jab widget tree ready ho
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    // _searchFocus is from provider — provider handles dispose
    super.dispose();
  }

  void _onSearchChanged() {
    final now    = DateTime.now();
    final isReturn = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;

    final query = _searchCtrl.text;
    if (isReturn) {
      ref.read(saleReturnProvider.notifier).updateSearch(query);
    } else {
      ref.read(saleInvoiceProvider.notifier).updateSearch(query);
    }

    // Track typing speed for barcode detection
    if (_lastKeyTime != null) {
      final gap = now.difference(_lastKeyTime!).inMilliseconds;
      if (gap < 40) {
        // Fast input — scanner ki tarah
        _isScannerInput = true;
      } else if (gap > 200) {
        // Slow gap — manual typing
        _isScannerInput = false;
      }
    }
    _lastKeyTime = now;
  }

  /// Enter press pe barcode/SKU exact match dhundo aur cart mein dalo
  void _onSubmitted(String value) {
    final trimmed  = value.trim();
    if (trimmed.isEmpty) return;

    final isReturn = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;

    if (isReturn) {
      _addByBarcodeReturn(trimmed);
    } else {
      final found = ref
          .read(saleInvoiceProvider.notifier)
          .addToCartByBarcode(trimmed);

      if (found) {
        // Cart mein add ho gaya — search clear karo
        _searchCtrl.clear();
        ref.read(saleInvoiceProvider.notifier).updateSearch('');
        // Quick flash feedback
        _showAddedFeedback();
      }
      // Agar nahi mila toh search filter rahe
    }
  }

  void _addByBarcodeReturn(String query) {
    final allProducts = ref.watch(branchStockProvider).allProducts;
    BranchStockModel? found;

    found = allProducts.cast<BranchStockModel?>().firstWhere(
          (p) =>
      p!.barcode != null &&
          p.barcode!.toLowerCase() == query.toLowerCase(),
      orElse: () => null,
    );

    found ??= allProducts.cast<BranchStockModel?>().firstWhere(
          (p) => p!.sku.toLowerCase() == query.toLowerCase(),
      orElse: () => null,
    );

    if (found != null) {
      ref.read(saleReturnProvider.notifier).addToCart(found);
      _searchCtrl.clear();
      ref.read(saleReturnProvider.notifier).updateSearch('');
      _showAddedFeedback();
    }
  }

  OverlayEntry? _overlayEntry;
  void _showAddedFeedback() {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        top:   80,
        right: 20,
        child: Material(
          color:       Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:        AppColor.success,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color:  Colors.black.withOpacity(0.15),
                    blurRadius: 8),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Cart mein add ho gaya',
                    style: TextStyle(
                        color:      Colors.white,
                        fontSize:   13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(milliseconds: 1200), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  /// Search bar focus karo — F1/Ctrl+F shortcut ke liye (public)
  void focusSearch() {
    _searchFocusFromProvider?.requestFocus();
    _searchCtrl.selection = TextSelection(
      baseOffset:  0,
      extentOffset: _searchCtrl.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider se FocusNode lo — shortcut ke liye reliable
    _searchFocusFromProvider ??= ref.read(posSearchFocusProvider);

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
        color:  const Color(0xFFF8F9FC),
        border: Border(right: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(
        children: [
          // ── Header + Search ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: const BoxDecoration(
              color:  Colors.white,
              border: Border(bottom: BorderSide(color: AppColor.grey200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.inventory_2_outlined, size: 14, color: accent),
                  const SizedBox(width: 6),
                  Text('Products',
                      style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                          color:      accent)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:        accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${products.length}',
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      accent)),
                  ),
                ]),
                const SizedBox(height: 8),

                // ── Barcode + Name Search ──────────────────────────
                TextField(
                  controller:  _searchCtrl,
                  focusNode:   _searchFocusFromProvider,
                  onSubmitted: _onSubmitted, // ← barcode Enter
                  onChanged:   (_) {},       // listener handles this
                  style: const TextStyle(
                      fontSize: 13, color: AppColor.textPrimary),
                  cursorHeight: 14,
                  inputFormatters: [
                    // Barcode input allow karo (alphanumeric + dashes)
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9\-_. ]')),
                  ],
                  decoration: InputDecoration(
                    hintText:  'Name, SKU, barcode → Enter to add',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: AppColor.textHint),
                    prefixIcon: Icon(Icons.qr_code_scanner_rounded,
                        size: 16, color: AppColor.grey400),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        if (isReturn) {
                          retNotifier.updateSearch('');
                        } else {
                          notifier.updateSearch('');
                        }
                      },
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColor.grey400),
                    )
                        : null,
                    filled:    true,
                    fillColor: AppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:   BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:   BorderSide(color: accent, width: 1.2),
                    ),
                  ),
                ),

                // ── Barcode hint ─────────────────────────────────────
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 10, color: AppColor.textHint),
                  const SizedBox(width: 4),
                  const Text('Barcode scan ya type karke Enter dabao',
                      style: TextStyle(
                          fontSize: 10, color: AppColor.textHint)),
                ]),
              ],
            ),
          ),

          // ── Product List ─────────────────────────────────────────
          Expanded(
            child: products.isEmpty
                ? _EmptyProducts()
                : ListView.builder(
              padding:   const EdgeInsets.all(8),
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

// ── Product Card (same as before) ──────────────────────────────
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
    final p          = widget.product;
    final inStock    = p.quantity > 0;
    final accent     = widget.isReturn ? AppColor.error : AppColor.primary;
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(
                color: inStock
                    ? AppColor.grey200
                    : AppColor.error.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color:      Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset:     const Offset(0, 1)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                  color:        accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Center(
                child: Text('${widget.index}',
                    style: TextStyle(
                        fontSize:   9,
                        fontWeight: FontWeight.w700,
                        color:      accent)),
              ),
            ),
            const SizedBox(width: 8),
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
                          fontSize: 10, color: AppColor.textHint)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                'Rs ${p.sellingPrice.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w800,
                    color:      accent),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:        stockColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${p.quantity.toStringAsFixed(p.quantity % 1 == 0 ? 0 : 1)}',
                  style: TextStyle(
                      fontSize:   9,
                      fontWeight: FontWeight.w700,
                      color:      stockColor),
                ),
              ),
            ]),
          ]),
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
        Icon(Icons.search_off_rounded, size: 40, color: AppColor.grey300),
        SizedBox(height: 8),
        Text('No products found',
            style: TextStyle(fontSize: 13, color: AppColor.textHint)),
      ],
    ),
  );
}