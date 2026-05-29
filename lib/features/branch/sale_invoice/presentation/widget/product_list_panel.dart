import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/color/app_color.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';
import '../provider/sale_return_provider.dart';
import '../screen/sale_invoice_screen.dart';

class ProductListPanel extends ConsumerStatefulWidget {
  const ProductListPanel({super.key});

  @override
  ConsumerState<ProductListPanel> createState() => _ProductListPanelState();
}

class _ProductListPanelState extends ConsumerState<ProductListPanel> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  FocusNode? _searchFocusFromProvider;

  int _hoveredIndex = -1;
  final Map<int, GlobalKey> _itemKeys = {};

  final _qtyCtrl  = TextEditingController(text: '1');
  final _qtyFocus = FocusNode();

  // ✅ KeyboardListener ke liye — fields mein store karo, har build pe naya mat banao
  final _searchKbFocus = FocusNode(skipTraversal: true);
  final _qtyKbFocus    = FocusNode(skipTraversal: true);

  OverlayEntry? _feedbackOverlay;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _qtyCtrl.dispose();
    _qtyFocus.dispose();
    _searchKbFocus.dispose();
    _qtyKbFocus.dispose();
    _feedbackOverlay?.remove();
    super.dispose();
  }

  void _onSearchChanged() {
    final isReturn = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;
    if (isReturn) {
      ref.read(saleReturnProvider.notifier).updateSearch(_searchCtrl.text);
    } else {
      ref.read(saleInvoiceProvider.notifier).updateSearch(_searchCtrl.text);
    }
    setState(() => _hoveredIndex = -1);
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ FIX: Search KeyboardListener — SIRF arrows + ESC
  // Enter yahan NAHI handle hoga — TextField.onSubmitted handle karega
  // ─────────────────────────────────────────────────────────────
  void _handleSearchKey(KeyEvent event) {
    // ✅ KeyDownEvent + KeyRepeatEvent dono handle karo
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final key = event.logicalKey;

    // ESC — sirf KeyDownEvent pe
    if (key == LogicalKeyboardKey.escape && event is KeyDownEvent) {
      if (_searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
        final isReturn =
            ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;
        if (isReturn) ref.read(saleReturnProvider.notifier).updateSearch('');
        else ref.read(saleInvoiceProvider.notifier).updateSearch('');
        setState(() => _hoveredIndex = -1);
      }
      return;
    }

    // Arrow Down
    if (key == LogicalKeyboardKey.arrowDown) {
      final products = _currentProducts();
      if (products.isEmpty) return;
      setState(() =>
      _hoveredIndex = (_hoveredIndex + 1).clamp(0, products.length - 1));
      _scrollToHovered();
      return;
    }

    // Arrow Up
    if (key == LogicalKeyboardKey.arrowUp) {
      final products = _currentProducts();
      if (products.isEmpty) return;
      setState(() =>
      _hoveredIndex = (_hoveredIndex - 1).clamp(0, products.length - 1));
      _scrollToHovered();
      return;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ Search TextField.onSubmitted — Enter key (most reliable)
  // ─────────────────────────────────────────────────────────────
  void _onSearchSubmitted(String value) {
    final query    = value.trim();
    final products = _currentProducts();

    // Step 1: Exact barcode/SKU match → direct add
    if (query.isNotEmpty) {
      final added = _tryBarcodeAdd(query);
      if (added) return;
    }

    // ✅ Step 2: Sirf 1 product filtered list mein → seedha add karo
    if (products.length == 1) {
      setState(() => _hoveredIndex = 0);
      _addWithQty(products.first);
      return;
    }

    // Step 3: Product hovered hai → qty field focus karo
    if (_hoveredIndex >= 0 && _hoveredIndex < products.length) {
      _focusQty();
      return;
    }

    // Step 4: Koi hover nahi → pehla product hover karo
    if (products.isNotEmpty) {
      setState(() => _hoveredIndex = 0);
      _scrollToHovered();
      _focusQty(); // ✅ qty field bhi focus karo
    }
  }

  // ──────────_onSearchSubmitted───────────────────────────────────────────────────
  // ✅ FIX: Qty KeyboardListener — SIRF ESC
  // Enter yahan NAHI — TextField.onSubmitted handle karega
  // ─────────────────────────────────────────────────────────────
  void _handleQtyKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    // ESC → search pe wapas jao
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _searchFocusFromProvider?.requestFocus();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ Qty TextField.onSubmitted — Enter key (most reliable)
  // ─────────────────────────────────────────────────────────────
  void _onQtySubmitted(String _) {
    final products = _currentProducts();
    if (_hoveredIndex >= 0 && _hoveredIndex < products.length) {
      _addWithQty(products[_hoveredIndex]);
    }
  }

  void _focusQty() {
    _qtyFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _qtyCtrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _qtyCtrl.text.length);
    });
  }

  void _scrollToHovered() {
    if (_hoveredIndex < 0) return;
    final key = _itemKeys[_hoveredIndex];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration:  const Duration(milliseconds: 150),
      curve:     Curves.easeOut,
      alignment: 0.3,
    );
  }

  List<BranchStockModel> _currentProducts() {
    final allProducts  = ref.read(branchStockProvider).allProducts;
    final invoiceState = ref.read(saleInvoiceProvider);
    final isReturn     = invoiceState.saleType == SaleType.saleReturn;
    final q = isReturn
        ? ref.read(saleReturnProvider).searchQuery
        : invoiceState.searchQuery;
    if (q.isEmpty) return allProducts;
    return allProducts.where((p) =>
    p.name.toLowerCase().contains(q.toLowerCase()) ||
        p.sku.toLowerCase().contains(q.toLowerCase()) ||
        (p.barcode?.toLowerCase().contains(q.toLowerCase()) ?? false))
        .toList();
  }

  // ─────────────────────────────────────────────────────────────
  // Barcode add — exact match + fallback
  // ─────────────────────────────────────────────────────────────
  bool _tryBarcodeAdd(String query) {
    if (query.isEmpty) return false;
    final isReturn    = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;
    final allProducts = ref.read(branchStockProvider).allProducts;

    // ✅ Direct allProducts mein exact match dhundo — barcode OR sku
    BranchStockModel? match = allProducts.cast<BranchStockModel?>().firstWhere(
          (p) =>
      (p!.barcode != null &&
          p.barcode!.toLowerCase().trim() == query.toLowerCase().trim()) ||
          p.sku.toLowerCase().trim() == query.toLowerCase().trim(),
      orElse: () => null,
    );

    // ✅ Agar exact match nahi mila — filtered list mein sirf 1 result hai to use add karo
    if (match == null) {
      final filtered = allProducts.where((p) =>
      p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.sku.toLowerCase().contains(query.toLowerCase()) ||
          (p.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
      if (filtered.length == 1) match = filtered.first;
    }

    if (match == null) return false;

    // ✅ Found — cart mein add karo
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1;

    if (isReturn) {
      ref.read(saleReturnProvider.notifier).addToCart(match);
      _onProductAdded(match.name, qty, isReturn: true);
    } else {
      _doAddToCart(match, qty);
      _onProductAdded(match.name, qty);
    }

    return true;
  }

  bool _addByBarcodeReturn(String query) {
    final allProducts = ref.read(branchStockProvider).allProducts;
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
      _onProductAdded(found.name, 1, isReturn: true);
      return true;
    }
    return false;
  }

  void _doAddToCart(BranchStockModel product, double qty) {
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final state    = ref.read(saleInvoiceProvider);
    final existing = state.cartItems
        .where((i) => i.product.productId == product.productId)
        .firstOrNull;

    if (existing != null) {
      notifier.updateQuantity(existing.cartId, existing.quantity + qty);
    } else {
      notifier.addToCart(product);
      if (qty > 1) {
        final newState = ref.read(saleInvoiceProvider);
        final newItem  = newState.cartItems
            .where((i) => i.product.productId == product.productId)
            .firstOrNull;
        if (newItem != null) notifier.updateQuantity(newItem.cartId, qty);
      }
    }
  }

  void _onProductAdded(String name, double qty, {bool isReturn = false}) {
    // _searchCtrl.clear();
    _qtyCtrl.text = '1';
    // if (isReturn) {
    //   ref.read(saleReturnProvider.notifier).updateSearch('');
    // } else {
    //   ref.read(saleInvoiceProvider.notifier).updateSearch('');
    // }
    setState(() => _hoveredIndex = -1);
    _showAddedFeedback(name, qty);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusFromProvider?.requestFocus();
    });
  }

  void _addWithQty(BranchStockModel product) {
    final isReturn = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;
    final qty      = double.tryParse(_qtyCtrl.text.trim()) ?? 1;
    if (qty <= 0) return;

    if (isReturn) {
      final n = ref.read(saleReturnProvider.notifier);
      n.addToCart(product);
      if (qty > 1) n.updateQuantity(product.productId, qty);
      _onProductAdded(product.name, qty, isReturn: true);
    } else {
      _doAddToCart(product, qty);
      _onProductAdded(product.name, qty);
    }
  }

  void _showAddedFeedback(String name, double qty) {
    _feedbackOverlay?.remove();
    _feedbackOverlay = OverlayEntry(
      builder: (_) => Positioned(
        top: 80, right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:        AppColor.success,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15), blurRadius: 8)
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 1)} × $name',
                style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   13,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_feedbackOverlay!);
    Future.delayed(const Duration(milliseconds: 1400), () {
      _feedbackOverlay?.remove();
      _feedbackOverlay = null;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
        (p.barcode
            ?.toLowerCase()
            .contains(searchQuery.toLowerCase()) ??
            false))
        .toList();

    if (_hoveredIndex >= products.length && products.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
              (_) => setState(() => _hoveredIndex = products.length - 1));
    }

    final accent = isReturn ? AppColor.error : AppColor.primary;

    return Container(
      decoration: BoxDecoration(
        color:  const Color(0xFFF8F9FC),
        border: Border(right: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(children: [

        // ── Header ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: const BoxDecoration(
            color:  Colors.white,
            border: Border(bottom: BorderSide(color: AppColor.grey200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Label + count
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

              // ── Search + Qty Row ─────────────────────────
              Row(children: [

                // ── Search field ──────────────────────────
                Expanded(
                  child: KeyboardListener(
                    focusNode:  _searchKbFocus,
                    // ✅ Sirf arrows + ESC — Enter TextField.onSubmitted se handle hoga
                    onKeyEvent: _handleSearchKey,
                    child: TextField(
                      controller:  _searchCtrl,
                      focusNode:   _searchFocusFromProvider,
                      // ✅ onSubmitted — Enter key ka reliable handler
                      onSubmitted: _onSearchSubmitted,
                      style: const TextStyle(
                          fontSize: 13, color: AppColor.textPrimary),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText:  'Search ya barcode scan karo...',
                        hintStyle: const TextStyle(
                            fontSize: 11, color: AppColor.textHint),
                        prefixIcon: Icon(Icons.qr_code_scanner_rounded,
                            size: 16, color: AppColor.grey400),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            if (isReturn) retNotifier.updateSearch('');
                            else notifier.updateSearch('');
                            setState(() => _hoveredIndex = -1);
                            _searchFocusFromProvider?.requestFocus();
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
                            borderSide:   BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: accent, width: 1.2)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ── Qty field ─────────────────────────────
                SizedBox(
                  width: 68,
                  child: KeyboardListener(
                    focusNode:  _qtyKbFocus,
                    // ✅ Sirf ESC — Enter TextField.onSubmitted se handle hoga
                    onKeyEvent: _handleQtyKey,
                    child: TextField(
                      controller:   _qtyCtrl,
                      focusNode:    _qtyFocus,
                      // ✅ onSubmitted — Enter ka reliable handler
                      onSubmitted:  _onQtySubmitted,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'))
                      ],
                      textAlign:    TextAlign.center,
                      cursorHeight: 14,
                      style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w800,
                          color:      accent),
                      decoration: InputDecoration(
                        labelText:  'Qty',
                        labelStyle: TextStyle(
                            fontSize:   10,
                            color:      accent,
                            fontWeight: FontWeight.w600),
                        filled:    true,
                        fillColor: accent.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: accent.withOpacity(0.3))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: accent.withOpacity(0.25))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: accent, width: 1.5)),
                      ),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 5),

              Row(children: [
                Icon(Icons.info_outline_rounded,
                    size: 10, color: AppColor.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Barcode → auto add  |  ↑↓ select → Enter → Qty type → Enter add',
                    style: const TextStyle(
                        fontSize: 9, color: AppColor.textHint),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),

              const SizedBox(height: 6),

              // Table header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(children: [
                  const SizedBox(width: 24),
                  const Expanded(
                    flex: 5,
                    child: Text('Product Name',
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textSecondary)),
                  ),
                  const SizedBox(
                    width: 50,
                    child: Text('Stock',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textSecondary)),
                  ),
                  const SizedBox(width: 4),
                  const SizedBox(
                    width: 58,
                    child: Text('Price',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      AppColor.textSecondary)),
                  ),
                ]),
              ),
            ],
          ),
        ),

        // ── Product List ─────────────────────────────────────
        Expanded(
          child: products.isEmpty
              ? const _EmptyProducts()
              : ListView.builder(
            controller: _scrollCtrl,
            padding:    const EdgeInsets.all(8),
            itemCount:  products.length,
            itemBuilder: (context, index) {
              final product   = products[index];
              final isHovered = index == _hoveredIndex;
              final itemKey   =
              _itemKeys.putIfAbsent(index, () => GlobalKey());

              return _ProductCard(
                key:       itemKey,
                index:     index + 1,
                product:   product,
                isReturn:  isReturn,
                isHovered: isHovered,

                // Single tap = hover + qty focus
                onTap: () {
                  setState(() => _hoveredIndex = index);
                  _focusQty();
                },

                // Double tap = add with current qty
                onDoubleTap: () {
                  setState(() => _hoveredIndex = index);
                  _addWithQty(product);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Product Card
// ══════════════════════════════════════════════════════════════════
class _ProductCard extends StatefulWidget {
  final BranchStockModel product;
  final VoidCallback     onDoubleTap;
  final VoidCallback     onTap;
  final bool             isReturn;
  final bool             isHovered;
  final int              index;

  const _ProductCard({
    super.key,
    required this.product,
    required this.onDoubleTap,
    required this.onTap,
    required this.isReturn,
    required this.isHovered,
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

  @override
  Widget build(BuildContext context) {
    final p       = widget.product;
    final inStock = p.quantity > 0;
    final accent  = widget.isReturn ? AppColor.error : AppColor.primary;

    final stockStr =
    p.quantity.toStringAsFixed(p.quantity % 1 == 0 ? 0 : 1);
    final priceStr =
    p.sellingPrice.toStringAsFixed(p.sellingPrice % 1 == 0 ? 0 : 1);

    return GestureDetector(
      onTap:       widget.onTap,
      onDoubleTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onDoubleTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin:   const EdgeInsets.only(bottom: 4),
          padding:  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isHovered
                ? accent.withOpacity(0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [

            SizedBox(
              width: 22,
              child: Text('${widget.index}',
                  style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                      color: widget.isHovered ? accent : AppColor.textHint)),
            ),

            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color: widget.isHovered
                              ? accent
                              : inStock
                              ? AppColor.textPrimary
                              : AppColor.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            SizedBox(
              width: 50,
              child: Text(stockStr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color: widget.isHovered
                          ? accent
                          : inStock
                          ? Colors.black87
                          : AppColor.error)),
            ),

            const SizedBox(width: 4),

            SizedBox(
              width: 58,
              child: Text(priceStr,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color: widget.isHovered ? accent : Colors.black87)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────
class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

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