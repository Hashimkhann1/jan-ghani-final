// Updated on 2026-11-16 10:35 AM

// =============================================================
// po_product_list_panel.dart  — UPDATED (barcodes list support)
// Left panel — products list with search
//   • Double tap → cart mein add (pehle jaisa, search text wahi)
//   • Keyboard (S27):
//       Search mein Enter → barcode / SKU exact match ya sirf EK
//         product mile to seedha cart; warna list ka pehla highlight
//       Search mein ↓ → list
//       List mein ↑/↓ highlight (auto-scroll) · Enter = cart ·
//         Esc / sab se upar ↑ = wapas search
//       Keyboard se add ke baad search text saaf + search focus
//   • Single click = highlight
//   • S28: screen khulte hi search focus · F1 / Ctrl+F (Mac: Cmd+F)
//     screen par kahin se bhi → search focus + text select
//     (dialog khula ho to nahi)
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/data/purchase_invoice_model.dart';
import 'package:jan_ghani_final/features/warehouse/purchase_invoice/presentation/provider/purchase_invoice_provider/purchase_invoice_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/provider/product_provider.dart';


class PoProductListPanel extends ConsumerStatefulWidget {
  const PoProductListPanel({super.key});

  @override
  ConsumerState<PoProductListPanel> createState() => _PoProductListPanelState();
}

class _PoProductListPanelState extends ConsumerState<PoProductListPanel> {
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'poProductSearch');
  final _listFocus   = FocusNode(debugLabel: 'poProductList');
  final _highlightKey = GlobalKey();
  final _scroll       = ScrollController();

  int _highlight = -1;            // -1 = koi highlight nahi
  List<ProductModel> _filtered = const [];

  @override
  void initState() {
    super.initState();
    // F1 / Ctrl+F — focus cart ke field mein ho tab bhi kaam kare
    HardwareKeyboard.instance.addHandler(_onGlobalKey);
    // Screen khulte hi search par cursor (seedha likho / scan karo)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusSearch();
    });
  }

  /// Search par focus + poora text select (naya likhte hi purana mit jaye)
  void _focusSearch() {
    if (_highlight != -1) setState(() => _highlight = -1);
    _searchFocus.requestFocus();
    _searchCtrl.selection = TextSelection(
        baseOffset: 0, extentOffset: _searchCtrl.text.length);
  }

  bool _onGlobalKey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted) return false;
    final kb = HardwareKeyboard.instance;
    final isF1 = e.logicalKey == LogicalKeyboardKey.f1 &&
        !kb.isControlPressed && !kb.isAltPressed && !kb.isMetaPressed;
    final isFind = e.logicalKey == LogicalKeyboardKey.keyF &&
        (kb.isControlPressed || kb.isMetaPressed) &&
        !kb.isAltPressed && !kb.isShiftPressed;
    if (!isF1 && !isFind) return false;
    // Dialog (supplier, date picker, confirm…) upar ho to kuch nahi
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    _focusSearch();
    return true;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onGlobalKey);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _listFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Active products jo search se match karein (name / SKU / koi barcode).
  /// Build aur Enter dono yahi use karte — scanner ka Enter rebuild se
  /// pehle aa jata hai, isliye Enter par taaza text se dobara filter.
  List<ProductModel> _filterProducts(String rawQuery) {
    final query = rawQuery.toLowerCase();
    final all = ref.read(productProvider).allProducts
        .where((p) => p.isActive && p.deletedAt == null);
    if (query.isEmpty) return all.toList();
    return all.where((p) =>
        p.name.toLowerCase().contains(query) ||
        p.sku.toLowerCase().contains(query)  ||
        p.barcodes.any((b) => b.toLowerCase().contains(query))).toList();
  }

  // ── Helpers ─────────────────────────────────────────────────
  static PoProduct _toPoProduct(ProductModel p) => PoProduct(
        id:            p.id,
        name:          p.name,
        category:      p.categoryName ?? '-',
        sku:           p.sku,
        purchasePrice: p.purchasePrice,
        salePrice:     p.sellingPrice,
        stock:         p.quantity,
        unitOfMeasure: p.unitOfMeasure,
      );

  void _onSearchChanged(String q) {
    ref.read(purchaseInvoiceProvider.notifier).updateSearch(q);
    if (_highlight != -1) setState(() => _highlight = -1);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _onSearchChanged('');
  }

  /// Keyboard se add: cart → search saaf → search par focus
  void _addByKeyboard(ProductModel p) {
    ref.read(purchaseInvoiceProvider.notifier).addToCart(_toPoProduct(p));
    _searchCtrl.clear();
    ref.read(purchaseInvoiceProvider.notifier).updateSearch('');
    setState(() => _highlight = -1);
    _searchFocus.requestFocus();
  }

  void _setHighlight(int i) {
    if (_filtered.isEmpty) return;
    setState(() => _highlight = i.clamp(0, _filtered.length - 1));
    _scrollToHighlight();
  }

  // Highlighted item nazar mein rahe. Item bana hua ho → ensureVisible;
  // na bana ho (tez ↓) → andaze se wahan jump, agle frame mein theek jagah.
  void _scrollToHighlight([int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _highlight < 0) return;
      final ctx = _highlightKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 120),
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
            alignment: 0.5);
        return;
      }
      if (attempt >= 3 || !_scroll.hasClients || _filtered.isEmpty) return;
      final pos   = _scroll.position;
      final per   = (pos.maxScrollExtent + pos.viewportDimension) /
          _filtered.length;
      final target = per * _highlight - pos.viewportDimension / 2;
      _scroll.jumpTo(target.clamp(0.0, pos.maxScrollExtent));
      _scrollToHighlight(attempt + 1);
    });
  }

  void _backToSearch() {
    setState(() => _highlight = -1);
    _searchFocus.requestFocus();
  }

  // Search mein Enter
  void _onSearchSubmit(String raw) {
    final q = raw.trim().toLowerCase();
    _filtered = _filterProducts(raw);   // taaza (scanner ka tez Enter)
    if (_filtered.isEmpty) {
      _searchFocus.requestFocus();
      return;
    }
    if (q.isNotEmpty) {
      // Barcode / SKU bilkul barabar (scanner) → seedha cart
      final exact = _filtered.where((p) =>
          p.barcodes.any((b) => b.trim().toLowerCase() == q) ||
          p.sku.trim().toLowerCase() == q).toList();
      if (exact.length == 1) return _addByKeyboard(exact.first);
      // Sirf ek product mila → seedha cart
      if (_filtered.length == 1) return _addByKeyboard(_filtered.first);
    }
    // Warna list mein jao — pehla highlight
    _listFocus.requestFocus();
    _setHighlight(0);
  }

  KeyEventResult _onSearchKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.arrowDown && _filtered.isNotEmpty) {
      _listFocus.requestFocus();
      _setHighlight(0);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _onListKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowDown) {
      _setHighlight(_highlight < 0 ? 0 : _highlight + 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      if (_highlight <= 0) {
        _backToSearch();
      } else {
        _setHighlight(_highlight - 1);
      }
      return KeyEventResult.handled;
    }
    if (e is KeyDownEvent &&
        (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter)) {
      if (_highlight >= 0 && _highlight < _filtered.length) {
        _addByKeyboard(_filtered[_highlight]);
      }
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      _backToSearch();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final poState      = ref.watch(purchaseInvoiceProvider);
    final poNotifier   = ref.read(purchaseInvoiceProvider.notifier);
    final productState = ref.watch(productProvider);

    // Cart mein already existing product IDs — highlight ke liye
    final cartProductIds =
        poState.cartItems.map((i) => i.product.id).toSet();

    // name / SKU / barcodes list mein se koi bhi match (productState watch
    // upar hai — products badlein to rebuild)
    final filtered = _filterProducts(poState.searchQuery);
    _filtered = filtered;
    final highlight = _highlight < filtered.length ? _highlight : -1;

    return Container(
      decoration: const BoxDecoration(
        color:  WarehouseAppColor.white,
        border: Border(right: BorderSide(color: WarehouseAppColor.grey200)),
      ),
      child: Column(
        children: [
          Focus(
            onKeyEvent: _onSearchKey,
            skipTraversal: true,
            child: _SearchBar(
              controller: _searchCtrl,
              focusNode:  _searchFocus,
              onChanged:  _onSearchChanged,
              onSubmitted: _onSearchSubmit,
              onClear:    _clearSearch,
            ),
          ),

          if (productState.isLoading)
            const LinearProgressIndicator(minHeight: 2),

          Expanded(
            child: productState.isLoading
                ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2))
                : filtered.isEmpty
                ? const _EmptyProducts()
                : Focus(
              focusNode:  _listFocus,
              onKeyEvent: _onListKey,
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  final isHi    = index == highlight;
                  return _ProductListItem(
                    key:         isHi ? _highlightKey : ValueKey(product.id),
                    product:     product,
                    isInCart:    cartProductIds.contains(product.id),
                    highlighted: isHi,
                    onTap: () {
                      _listFocus.requestFocus();
                      _setHighlight(index);
                    },
                    onDoubleTap: () =>
                        poNotifier.addToCart(_toPoProduct(product)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ──────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final ValueChanged<String>  onChanged;
  final ValueChanged<String>  onSubmitted;
  final VoidCallback          onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color:  WarehouseAppColor.white,
        border: Border(bottom: BorderSide(color: WarehouseAppColor.grey200)),
      ),
      child: TextField(
        controller: controller,
        focusNode:  focusNode,
        onChanged:  onChanged,
        onSubmitted: onSubmitted,
        // Enter par khud unfocus na ho — focus hum decide karte hain
        onEditingComplete: () {},
        style: const TextStyle(
            fontSize: 13, color: WarehouseAppColor.textPrimary),
        cursorHeight: 14,
        decoration: InputDecoration(
          hintText:  'Name, SKU ya barcode se search...',
          hintStyle: const TextStyle(
              fontSize: 13, color: WarehouseAppColor.textHint),
          prefixIcon: const Icon(Icons.search,
              size: 18, color: WarehouseAppColor.grey500),
          // X button — sirf tab dikhega jab text ho
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isNotEmpty
                ? GestureDetector(
                    onTap: onClear,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color:  WarehouseAppColor.grey300,
                        shape:  BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: WarehouseAppColor.white),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          filled:    true,
          fillColor: WarehouseAppColor.grey100,
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
  final bool         isInCart;
  final bool         highlighted;   // keyboard ↑/↓ wala
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _ProductListItem({
    super.key,
    required this.product,
    required this.isInCart,
    required this.onTap,
    required this.onDoubleTap,
    this.highlighted = false,
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

    final isInCart = widget.isInCart;
    final hi       = widget.highlighted;

    return GestureDetector(
      onTap:       widget.onTap,
      onDoubleTap: _onDoubleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          // Highlight border 2px, baaki 1-1.5px — padding se height same
          padding: EdgeInsets.symmetric(
              horizontal: hi ? 11 : 12, vertical: hi ? 9 : 10),
          decoration: BoxDecoration(
            color: hi
                ? WarehouseAppColor.infoLight     // keyboard highlight (neela)
                : isInCart
                    ? const Color(0xFFEEEDFE)   // light purple background
                    : WarehouseAppColor.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hi
                  ? WarehouseAppColor.info
                  : isInCart
                      ? const Color(0xFF6C63FF)  // purple border
                      : WarehouseAppColor.grey200,
              width: hi ? 2.0 : (isInCart ? 1.5 : 1.0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color:      WarehouseAppColor.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.categoryName ?? '-'}  •  '
                          ' Rs ${p.purchasePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w500,
                          color:      WarehouseAppColor.textSecondary),
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
                      ? WarehouseAppColor.success.withOpacity(0.10)
                      : WarehouseAppColor.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inStock
                      ? '${p.quantity.toStringAsFixed(2)} ${p.unitOfMeasure}'
                      : 'Out',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color: inStock ? WarehouseAppColor.success : WarehouseAppColor.error,
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
          Icon(Icons.search_off, size: 40, color: WarehouseAppColor.grey300),
          SizedBox(height: 8),
          Text('Koi product nahi mila',
              style: TextStyle(fontSize: 13, color: WarehouseAppColor.textHint)),
        ],
      ),
    );
  }
}