// Updated on 2026-11-26 12:44 PM

// =============================================================
// assign_stock_product_list_panel.dart — Assign Stock left panel
//   • Double tap → cart mein add (pehle jaisa, search text wahi)
//   • Keyboard (New Purchase Invoice jaisa — S27/S28):
//       Search mein Enter → barcode / SKU exact match ya sirf EK
//         product mile to seedha cart; warna list ka pehla highlight
//       Search mein ↓ → list
//       List mein ↑/↓ highlight (auto-scroll) · Enter = cart ·
//         Esc / sab se upar ↑ = wapas search
//       Keyboard se add ke baad search text saaf + search focus
//   • Single click = highlight
//   • Screen khulte hi search focus · F1 / Ctrl+F (Mac: Cmd+F) screen
//     par kahin se bhi (cart qty field se bhi) → search focus + text
//     select (dialog khula ho to nahi)
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/data/model/product_model.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/provider/product_provider.dart';

class AssignStockProductListPanel extends ConsumerStatefulWidget {
  const AssignStockProductListPanel({super.key});

  @override
  ConsumerState<AssignStockProductListPanel> createState() =>
      _AssignStockProductListPanelState();
}

class _AssignStockProductListPanelState
    extends ConsumerState<AssignStockProductListPanel> {
  final _searchController = TextEditingController();
  final _searchFocus  = FocusNode(debugLabel: 'assignProductSearch');
  final _listFocus    = FocusNode(debugLabel: 'assignProductList');
  final _highlightKey = GlobalKey();
  final _scroll       = ScrollController();

  int _highlight = -1;                 // -1 = koi highlight nahi
  List<ProductModel> _filtered = const [];

  @override
  void initState() {
    super.initState();
    // F1 / Ctrl+F — focus cart ke qty field mein ho tab bhi kaam kare
    HardwareKeyboard.instance.addHandler(_onGlobalKey);
    // Screen khulte hi search par cursor (seedha likho / scan karo)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusSearch();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onGlobalKey);
    _searchController.dispose();
    _searchFocus.dispose();
    _listFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Search par focus + poora text select (naya likhte hi purana mit jaye)
  void _focusSearch() {
    if (_highlight != -1) setState(() => _highlight = -1);
    _searchFocus.requestFocus();
    _searchController.selection = TextSelection(
        baseOffset: 0, extentOffset: _searchController.text.length);
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
    // Dialog (assign confirm, zero-qty warning…) upar ho to kuch nahi
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    _focusSearch();
    return true;
  }

  /// Active products (aakhri edit wala upar) jo search se match karein
  /// (name / SKU / koi barcode). Build aur Enter dono yahi use karte —
  /// scanner ka Enter rebuild se pehle aa jata hai.
  List<ProductModel> _filterProducts(String rawQuery) {
    final query = rawQuery.toLowerCase();
    final all = ref.read(productProvider).allProducts
        .where((p) => p.isActive && p.deletedAt == null)
        .toList()
      // Sab se aakhir mein edit hua product (updated_at) top par
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (query.isEmpty) return all;
    return all.where((p) =>
        p.name.toLowerCase().contains(query) ||
        p.sku.toLowerCase().contains(query) ||
        p.barcodes.any((b) => b.toLowerCase().contains(query))).toList();
  }

  void _onSearchChanged(String q) {
    ref.read(assignStockProvider.notifier).updateSearch(q);
    if (_highlight != -1) setState(() => _highlight = -1);
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  /// Keyboard se add: cart → search saaf → search par focus
  /// (pehle se cart mein ho to provider kuch nahi karta — pehle jaisa)
  void _addByKeyboard(ProductModel p) {
    ref.read(assignStockProvider.notifier).addToCart(p);
    _searchController.clear();
    ref.read(assignStockProvider.notifier).updateSearch('');
    setState(() => _highlight = -1);
    _searchFocus.requestFocus();
  }

  void _setHighlight(int i) {
    if (_filtered.isEmpty) return;
    setState(() => _highlight = i.clamp(0, _filtered.length - 1));
    _scrollToHighlight();
  }

  // Highlighted item nazar mein rahe. Item bana ho → ensureVisible;
  // na bana ho (tez ↓) → andaze se jump, agle frame mein theek jagah.
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
      final pos    = _scroll.position;
      final per    = (pos.maxScrollExtent + pos.viewportDimension) /
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
    final state = ref.watch(assignStockProvider);
    final notifier = ref.read(assignStockProvider.notifier);
    final productState = ref.watch(productProvider);

    // productState upar watch hai — products badlein to rebuild
    final filtered = _filterProducts(state.searchQuery);
    _filtered = filtered;
    final highlight = _highlight < filtered.length ? _highlight : -1;

    return Container(
      decoration: const BoxDecoration(
        color: WarehouseAppColor.white,
        border: Border(right: BorderSide(color: WarehouseAppColor.grey200)),
      ),
      child: Column(
        children: [
          // Search bar
          Focus(
            onKeyEvent:    _onSearchKey,
            skipTraversal: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: WarehouseAppColor.white,
                border: Border(bottom: BorderSide(color: WarehouseAppColor.grey200)),
              ),
              child: TextField(
                controller:  _searchController,
                focusNode:   _searchFocus,
                onChanged:   _onSearchChanged,
                onSubmitted: _onSearchSubmit,
                // Enter par khud unfocus na ho — focus hum decide karte hain
                onEditingComplete: () {},
                style: const TextStyle(fontSize: 13, color: WarehouseAppColor.textPrimary),
                cursorHeight: 14,
                decoration: InputDecoration(
                  hintText: 'Name, SKU ya barcode se search...',
                  hintStyle: const TextStyle(fontSize: 13, color: WarehouseAppColor.textHint),
                  prefixIcon: const Icon(Icons.search, size: 18, color: WarehouseAppColor.grey500),
                  suffixIcon: state.searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: const Icon(Icons.close, size: 16, color: WarehouseAppColor.grey500),
                        )
                      : null,
                  filled: true,
                  fillColor: WarehouseAppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
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
                  Icon(Icons.search_off, size: 40, color: WarehouseAppColor.grey300),
                  SizedBox(height: 8),
                  Text('Koi product nahi mila',
                      style: TextStyle(fontSize: 13, color: WarehouseAppColor.textHint)),
                ],
              ),
            )
                : Focus(
              focusNode:  _listFocus,
              onKeyEvent: _onListKey,
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  final isHi    = index == highlight;
                  final inCart = state.cartItems
                      .any((i) => i.productId == product.id);
                  return _ProductItem(
                    key:         isHi ? _highlightKey : ValueKey(product.id),
                    product:     product,
                    inCart:      inCart,
                    highlighted: isHi,
                    onTap: () {
                      _listFocus.requestFocus();
                      _setHighlight(index);
                    },
                    onDoubleTap: () => notifier.addToCart(product),
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

class _ProductItem extends StatefulWidget {
  final ProductModel product;
  final bool inCart;
  final bool highlighted;     // keyboard ↑/↓ wala (neela)
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _ProductItem({
    super.key,
    required this.product,
    required this.inCart,
    required this.onTap,
    required this.onDoubleTap,
    this.highlighted = false,
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
    final inStock = p.availableQty > 0; // reserve-aware (quantity − reserved)
    final hi      = widget.highlighted;

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onDoubleTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          // Highlight border 2px — padding 1px kam, height same
          padding: EdgeInsets.symmetric(
              horizontal: hi ? 11 : 12, vertical: hi ? 9 : 10),
          decoration: BoxDecoration(
            color: hi
                ? WarehouseAppColor.infoLight       // keyboard highlight (neela)
                : widget.inCart
                    ? WarehouseAppColor.primary.withOpacity(0.05)
                    : WarehouseAppColor.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hi
                  ? WarehouseAppColor.info
                  : widget.inCart
                      ? WarehouseAppColor.primary.withOpacity(0.4)
                      : WarehouseAppColor.grey200,
              width: hi ? 2.0 : 1.0,
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
                            color: WarehouseAppColor.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${p.categoryName ?? '-'}  •  Rs ${p.purchasePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, color: WarehouseAppColor.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.inCart)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: WarehouseAppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${p.availableQty.toStringAsFixed(2)} ${p.unitOfMeasure}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: WarehouseAppColor.primary)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: inStock
                        ? WarehouseAppColor.success.withOpacity(0.10)
                        : WarehouseAppColor.error.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    inStock
                        ? '${p.availableQty.toStringAsFixed(2)} ${p.unitOfMeasure}'
                        : 'Out',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: inStock ? WarehouseAppColor.success : WarehouseAppColor.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}