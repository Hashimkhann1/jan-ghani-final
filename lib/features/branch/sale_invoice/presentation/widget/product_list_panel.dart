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

  int  _hoveredIndex = -1;

  final Map<int, GlobalKey> _itemKeys = {};

  final _qtyCtrl  = TextEditingController();
  final _qtyFocus = FocusNode();
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
    _feedbackOverlay?.remove();
    super.dispose();
  }

  void _onSearchChanged() {
    final isReturn = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;
    final query    = _searchCtrl.text;

    if (isReturn) {
      ref.read(saleReturnProvider.notifier).updateSearch(query);
    } else {
      ref.read(saleInvoiceProvider.notifier).updateSearch(query);
    }

    setState(() => _hoveredIndex = -1);
  }

  // ── ✅ FIX: Barcode direct add — pehle exact match try karo ─────
  // Returns true if product found and added to cart
  bool _tryDirectAdd(String query) {
    final isReturn = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;

    if (isReturn) {
      return _addByBarcodeReturn(query);
    } else {
      final found = ref
          .read(saleInvoiceProvider.notifier)
          .addToCartByBarcode(query);
      if (found) {
        _searchCtrl.clear();
        ref.read(saleInvoiceProvider.notifier).updateSearch('');
        _showAddedFeedback(query, 1);
        setState(() => _hoveredIndex = -1);
      }
      return found;
    }
  }

  // ── Arrow key + Enter handler ─────────────────────────────
  bool _handleSearchKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final products = _currentProducts();
    final key      = event.logicalKey;

    // ── ESC — search field clear karo ────────────────────────
    if (key == LogicalKeyboardKey.escape) {
      if (_searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
        final isReturn = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;
        if (isReturn) {
          ref.read(saleReturnProvider.notifier).updateSearch('');
        } else {
          ref.read(saleInvoiceProvider.notifier).updateSearch('');
        }
        setState(() => _hoveredIndex = -1);
        return true; // ESC consume karo — cart clear na ho
      }
      return false; // search already empty hai — screen ka ESC handle kare
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (products.isEmpty) return false;
      setState(() {
        _hoveredIndex = (_hoveredIndex + 1).clamp(0, products.length - 1);
      });
      _scrollToHovered();
      return true;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      if (products.isEmpty) return false;
      setState(() {
        _hoveredIndex = (_hoveredIndex - 1).clamp(0, products.length - 1);
      });
      _scrollToHovered();
      return true;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final query = _searchCtrl.text.trim();

      // ── ✅ FIX: PEHLE exact barcode/SKU match try karo ─────────
      // Scanner ka Enter yahan handle hoga — qty dialog nahi ayega
      if (query.isNotEmpty) {
        final added = _tryDirectAdd(query);
        if (added) return true; // barcode match mila — done
      }

      // ── Barcode match nahi mila — agar hovered item hai to qty dialog ──
      if (_hoveredIndex >= 0 && _hoveredIndex < products.length) {
        _showQtyDialog(products[_hoveredIndex]);
        return true;
      }

      return true;
    }

    return false;
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
    final searchQuery  = isReturn
        ? ref.read(saleReturnProvider).searchQuery
        : invoiceState.searchQuery;

    if (searchQuery.isEmpty) return allProducts;
    return allProducts.where((p) =>
    p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        p.sku.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (p.barcode?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false))
        .toList();
  }

  // ── Quantity Dialog ──────────────────────────────────────
  void _showQtyDialog(BranchStockModel product) {
    final isReturn = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;
    _qtyCtrl.text = '1';

    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_shopping_cart_outlined,
                size: 18, color: AppColor.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                'Rs ${product.sellingPrice.toStringAsFixed(0)} | Stock: ${product.quantity.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColor.textSecondary,
                    fontWeight: FontWeight.w400),
              ),
            ]),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            TextField(
              controller:   _qtyCtrl,
              focusNode:    _qtyFocus,
              autofocus:    true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColor.primary),
              decoration: InputDecoration(
                labelText:  'Quantity',
                labelStyle: const TextStyle(fontSize: 13, color: AppColor.textSecondary),
                filled:    true,
                fillColor: AppColor.primary.withOpacity(0.06),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColor.primary, width: 1.5)),
              ),
              onSubmitted: (_) {
                Navigator.pop(d);
                _addWithQty(product, isReturn);
              },
            ),
            const SizedBox(height: 4),
            const Text('Enter dabao ya "Add" press karo',
                style: TextStyle(fontSize: 10, color: AppColor.textHint)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(d);
              _addWithQty(product, isReturn);
            },
            icon:  const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    ).then((_) {
      _searchFocusFromProvider?.requestFocus();
    });
  }

  void _addWithQty(BranchStockModel product, bool isReturn) {
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1;
    if (qty <= 0) return;

    if (isReturn) {
      final notifier = ref.read(saleReturnProvider.notifier);
      notifier.addToCart(product);
      if (qty > 1) notifier.updateQuantity(product.productId, qty);
    } else {
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

    _showAddedFeedback(product.name, qty);
    _searchCtrl.clear();
    if (isReturn) {
      ref.read(saleReturnProvider.notifier).updateSearch('');
    } else {
      ref.read(saleInvoiceProvider.notifier).updateSearch('');
    }
    setState(() => _hoveredIndex = -1);
  }

  // ── ✅ FIX: onSubmitted — sirf tab karo jab _handleSearchKey ne handle na kiya ho ──
  // (jab text already clear hua ho, trimmed empty hoga — kuch nahi hoga)
  void _onSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return; // _handleSearchKey already clear kar chuka hai
    // Extra safety: dobara try karo (edge case jab handler na fire kare)
    _tryDirectAdd(trimmed);
  }

  // ── ✅ FIX: Return mode barcode add — bool return karta hai ─────
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
      _searchCtrl.clear();
      ref.read(saleReturnProvider.notifier).updateSearch('');
      _showAddedFeedback(found.name, 1);
      setState(() => _hoveredIndex = -1);
      return true;
    }
    return false;
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
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 1)} × $name',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
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
        : allProducts
        .where((p) =>
    p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        p.sku.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (p.barcode?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false))
        .toList();

    if (_hoveredIndex >= products.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(
              () => _hoveredIndex = products.isEmpty ? -1 : products.length - 1));
    }

    final accent = isReturn ? AppColor.error : AppColor.primary;

    return Container(
      decoration: BoxDecoration(
        color:  const Color(0xFFF8F9FC),
        border: Border(right: BorderSide(color: AppColor.grey200)),
      ),
      child: Column(children: [
        // ── Header + Search ──────────────────────────────────
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
                        fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${products.length}',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                ),
              ]),
              const SizedBox(height: 8),

              // ── Search TextField ────────────────────────────
              KeyboardListener(
                focusNode:  FocusNode(skipTraversal: true),
                onKeyEvent: _handleSearchKey,
                child: TextField(
                  controller:  _searchCtrl,
                  focusNode:   _searchFocusFromProvider,
                  onSubmitted: _onSubmitted,
                  onChanged:   (_) {},
                  style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
                  cursorHeight: 14,
                  // ── ✅ FIX: inputFormatters hataya — barcode ke sab characters allow ──
                  // Pehle wala regex `[a-zA-Z0-9\-_. ]` barcode ke special chars
                  // strip kar deta tha jis se exact match fail hoti thi
                  decoration: InputDecoration(
                    hintText:  'Barcode scan karo ya naam type karo',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColor.textHint),
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
                        setState(() => _hoveredIndex = -1);
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
              ),

              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.info_outline_rounded, size: 10, color: AppColor.textHint),
                const SizedBox(width: 4),
                const Text(
                  'Barcode scan → auto add | ↑↓ select → Enter = qty dialog',
                  style: TextStyle(fontSize: 9, color: AppColor.textHint),
                ),
              ]),
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
              final product  = products[index];
              final isHovered = index == _hoveredIndex;
              final itemKey  = _itemKeys.putIfAbsent(index, () => GlobalKey());

              return _ProductCard(
                key:         itemKey,
                index:       index + 1,
                product:     product,
                isReturn:    isReturn,
                isHovered:   isHovered,
                onDoubleTap: () => isReturn
                    ? retNotifier.addToCart(product)
                    : notifier.addToCart(product),
                onTap: () => _showQtyDialog(product),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────
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
    final qty = p.quantity.toStringAsFixed(p.quantity % 1 == 0 ? 0 : 1);

    return GestureDetector(
      onTap:       widget.onTap,
      onDoubleTap: _onDoubleTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin:  const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isHovered ? accent.withOpacity(0.07) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isHovered
                  ? accent
                  : inStock
                  ? AppColor.grey200
                  : AppColor.error.withOpacity(0.25),
              width: widget.isHovered ? 1.5 : 1.0,
            ),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                p.name,
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color: widget.isHovered
                        ? accent
                        : inStock
                        ? AppColor.textPrimary
                        : AppColor.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        stockColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(qty,
                  style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                      color:      stockColor)),
            ),
            if (widget.isHovered) ...[
              const SizedBox(width: 6),
              Icon(Icons.keyboard_return_rounded, size: 13, color: accent),
            ],
          ]),
        ),
      ),
    );
  }
}

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