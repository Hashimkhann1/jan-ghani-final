import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/color/app_color.dart';
import '../../../../../core/widget/app_icon.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/presentation/provider/branch_stock_inventory_provider.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';
import '../provider/sale_return_provider.dart';
import '../screen/sale_invoice_screen.dart';

/// Jin products ka barcode ya SKU [code] ke bilkul barabar hai.
List<BranchStockModel> findByExactCode(
    List<BranchStockModel> products, String code) {
  final q = code.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return products
      .where((p) =>
          p.sku.trim().toLowerCase() == q ||
          splitBarcodes(p.barcode).any((c) => c.toLowerCase() == q))
      .toList();
}

/// 6 ya us se zyada sirf digits — scan hua barcode (naam / qty nahi).
bool looksLikeBarcode(String text) => RegExp(r'^\d{6,}$').hasMatch(text.trim());

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

  final _searchKbFocus = FocusNode(skipTraversal: true);
  final _qtyKbFocus    = FocusNode(skipTraversal: true);

  OverlayEntry? _feedbackOverlay;

  /// Physical / Digital product tab (sale only; returns are physical-only).
  bool _showDigital = false;

  void _setDigitalTab(bool digital) {
    if (ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn) return;
    setState(() {
      _showDigital  = digital;
      _hoveredIndex = -1;
    });
  }

  List<BranchStockModel> _byTab(List<BranchStockModel> all, bool isReturn) {
    final digital = _showDigital && !isReturn;
    return all.where((p) => p.isDigital == digital).toList();
  }

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

  String _lastSearchText = '';

  void _onSearchChanged() {
    // Up/Down arrow caret move bhi controller notify karta hai —
    // sirf asal text change par hovered index reset karo.
    if (_searchCtrl.text == _lastSearchText) return;
    _lastSearchText = _searchCtrl.text;
    final isReturn = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;
    if (isReturn) {
      ref.read(saleReturnProvider.notifier).updateSearch(_searchCtrl.text);
    } else {
      ref.read(saleInvoiceProvider.notifier).updateSearch(_searchCtrl.text);
    }
    setState(() => _hoveredIndex = -1);
  }

  void _handleSearchKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final key = event.logicalKey;

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

    if (key == LogicalKeyboardKey.arrowDown) {
      final products = _currentProducts();
      if (products.isEmpty) return;
      setState(() =>
      _hoveredIndex = (_hoveredIndex + 1).clamp(0, products.length - 1));
      _scrollToHovered();
      return;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      final products = _currentProducts();
      if (products.isEmpty) return;
      setState(() =>
      _hoveredIndex = _hoveredIndex <= 0 ? 0 : _hoveredIndex - 1);
      _scrollToHovered();
      return;
    }
  }

  void _onSearchSubmitted(String value) {
    final query    = value.trim();
    final products = _currentProducts();

    if (query.isNotEmpty) {
      final added = _tryBarcodeAdd(query);
      if (added) return;
    }

    // Scan hua code kisi product se exact match nahi hua: kuch add na karo,
    // aur cursor search par rakho (Qty par gaya to agla scan qty ban jata).
    if (looksLikeBarcode(query) &&
        findByExactCode(ref.read(branchStockProvider).allProducts, query)
            .isEmpty) {
      _showToast('Barcode "$query" kisi product se match nahi hua',
          error: true);
      _refocusSearchSelectAll();
      return;
    }

    final sameCode =
        findByExactCode(ref.read(branchStockProvider).allProducts, query);
    if (sameCode.length > 1) {
      _showToast(
          '${sameCode.length} products par yehi code hai — sahi product select karein',
          error: true);
    }

    if (_hoveredIndex >= 0 && _hoveredIndex < products.length) {
      _focusQty();
      return;
    }

    // Ek hi result ho tab bhi seedha add nahi: pehle highlight + Qty,
    // dusre Enter par add.
    if (products.isNotEmpty) {
      setState(() => _hoveredIndex = 0);
      _scrollToHovered();
      _focusQty();
      return;
    }

    if (query.isNotEmpty) {
      _showToast('Koi product nahi mila', error: true);
      _refocusSearchSelectAll();
    }
  }

  /// Search par wapas, purana text selected — agla scan usay replace kare.
  void _refocusSearchSelectAll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusFromProvider?.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchCtrl.selection = TextSelection(
            baseOffset: 0, extentOffset: _searchCtrl.text.length);
      });
    });
  }

  void _handleQtyKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _searchFocusFromProvider?.requestFocus();
    }
  }

  void _onQtySubmitted(String value) {
    // Cursor Qty par tha aur barcode scan ho gaya: usay quantity na samjho.
    final typed = value.trim();
    if (looksLikeBarcode(typed)) {
      _qtyCtrl.text = '1';
      setState(() => _hoveredIndex = -1);
      _searchCtrl.text = typed;
      _onSearchSubmitted(typed);
      return;
    }
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
    final tabProducts = _byTab(allProducts, isReturn);
    if (q.isEmpty) return tabProducts;
    return tabProducts.where((p) =>
    p.name.toLowerCase().contains(q.toLowerCase()) ||
        p.sku.toLowerCase().contains(q.toLowerCase()) ||
        (p.barcode?.toLowerCase().contains(q.toLowerCase()) ?? false))
        .toList();
  }

  bool _tryBarcodeAdd(String query) {
    if (query.isEmpty) return false;
    final isReturn    = ref.read(saleInvoiceProvider).saleType == SaleType.saleReturn;
    final allProducts = ref.read(branchStockProvider).allProducts;

    // Sirf poora (exact) barcode / SKU match. Adha match kabhi auto-add
    // nahi hota. Ek se zyada product par wahi code ho to bhi nahi —
    // cashier list se dekh kar select kare.
    final matches = findByExactCode(allProducts, query);
    final BranchStockModel? match =
        matches.length == 1 ? matches.first : null;

    if (match == null) return false;

    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1;

    if (isReturn) {
      ref.read(saleReturnProvider.notifier).addToCart(match,
          qty: qty > 0 ? qty : 1, entryMethod: kEntryBarcode);
      _onProductAdded(match.name, qty, isReturn: true);
    } else {
      if (!_doAddToCart(match, qty, kEntryBarcode)) return true;
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
      ref.read(saleReturnProvider.notifier)
          .addToCart(found, entryMethod: kEntryBarcode);
      _onProductAdded(found.name, 1, isReturn: true);
      return true;
    }
    return false;
  }

  bool _doAddToCart(
      BranchStockModel product, double qty, String entryMethod) {
    final notifier = ref.read(saleInvoiceProvider.notifier);
    if (!product.isDigital && product.quantity <= 0) {
      _showToast('${product.name} — stock khatam hai (0 ya negative)', error: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusFromProvider?.requestFocus();
      });
      return false;
    }
    final state    = ref.read(saleInvoiceProvider);
    final existing = state.cartItems
        .where((i) => i.product.productId == product.productId)
        .firstOrNull;

    if (existing != null) {
      notifier.updateQuantity(existing.cartId, existing.quantity + qty);
      notifier.markEntry(existing.cartId, entryMethod);
    } else {
      notifier.addToCart(product, entryMethod: entryMethod);
      if (qty != 1) {
        final newState = ref.read(saleInvoiceProvider);
        final newItem  = newState.cartItems
            .where((i) => i.product.productId == product.productId)
            .firstOrNull;
        if (newItem != null) notifier.updateQuantity(newItem.cartId, qty);
      }
    }
    return true;
  }

  void _onProductAdded(String name, double qty, {bool isReturn = false}) {
    _qtyCtrl.text = '1';
    // Selection wahin rehti hai: agla ↑↓ isi product se aage chale.
    // (Search text badalne par _onSearchChanged khud reset karta hai.)
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
      ref.read(saleReturnProvider.notifier)
          .addToCart(product, qty: qty, entryMethod: kEntryManual);
      _onProductAdded(product.name, qty, isReturn: true);
    } else {
      if (!_doAddToCart(product, qty, kEntryManual)) return;
      _onProductAdded(product.name, qty);
    }
  }

  void _showAddedFeedback(String name, double qty) => _showToast(
      '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 1)} × $name');

  void _showToast(String text, {bool error = false}) {
    _feedbackOverlay?.remove();
    _feedbackOverlay = OverlayEntry(
      builder: (_) => Positioned(
        top: 80, right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:        error ? AppColor.error : AppColor.success,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15), blurRadius: 8)
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(error ? Icons.block_rounded : Icons.check_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                text,
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
    final entry = _feedbackOverlay;
    Future.delayed(Duration(milliseconds: error ? 2200 : 1400), () {
      if (_feedbackOverlay == entry) {
        entry?.remove();
        _feedbackOverlay = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool?>(productTabRequestProvider, (_, v) {
      if (v == null) return;
      _setDigitalTab(v);
      ref.read(productTabRequestProvider.notifier).state = null;
    });
    _searchFocusFromProvider ??= ref.read(posSearchFocusProvider);

    final invoiceState = ref.watch(saleInvoiceProvider);
    final isReturn     = invoiceState.saleType == SaleType.saleReturn;
    final searchQuery  = isReturn
        ? ref.watch(saleReturnProvider).searchQuery
        : invoiceState.searchQuery;

    final notifier    = ref.read(saleInvoiceProvider.notifier);
    final retNotifier = ref.read(saleReturnProvider.notifier);

    final tabProducts = _byTab(ref.watch(branchStockProvider).allProducts, isReturn);
    final products    = searchQuery.isEmpty
        ? tabProducts
        : tabProducts.where((p) =>
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

              // ── Physical / Digital ───────────────────────
              if (!isReturn) ...[
                Row(children: [
                  Expanded(
                    child: _TypeButton(
                      label:    'Physical',
                      shortcut: 'Ctrl+1',
                      icon:     Icons.inventory_2_outlined,
                      selected: !_showDigital,
                      color:    accent,
                      onTap:    () => setState(() {
                        _showDigital  = false;
                        _hoveredIndex = -1;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeButton(
                      label:    'Digital',
                      shortcut: 'Ctrl+2',
                      icon:     Icons.phone_android_rounded,
                      selected: _showDigital,
                      color:    accent,
                      onTap:    () => setState(() {
                        _showDigital  = true;
                        _hoveredIndex = -1;
                      }),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
              ],

              // ── Search + Qty Row ─────────────────────────
              Row(children: [

                // ── Search field ──────────────────────────
                Expanded(
                  child: KeyboardListener(
                    focusNode:  _searchKbFocus,
                    onKeyEvent: _handleSearchKey,
                    child: TextField(
                      controller:  _searchCtrl,
                      focusNode:   _searchFocusFromProvider,
                      onSubmitted: _onSearchSubmitted,
                      style: const TextStyle(
                          fontSize: 13, color: AppColor.textPrimary),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText:  'Search ya barcode scan karo...',
                        hintStyle: const TextStyle(
                            fontSize: 11, color: AppColor.textHint),
                        prefixIcon: const AppIcon('ic_barcode',
                            size: 16, color: AppColor.grey400),
                        prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
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
                    onKeyEvent: _handleQtyKey,
                    child: TextField(
                      controller:   _qtyCtrl,
                      focusNode:    _qtyFocus,
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
                onTap: () {
                  setState(() => _hoveredIndex = index);
                  _focusQty();
                },
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
class _TypeButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;
  final String?      shortcut;

  const _TypeButton({
    this.shortcut,
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color:        selected ? color : AppColor.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color : AppColor.grey200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: selected ? Colors.white : AppColor.textPrimary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                  color:      selected ? Colors.white : AppColor.textPrimary)),
          if (shortcut != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.2)
                    : color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(shortcut!,
                  style: TextStyle(
                      fontSize:   9,
                      fontWeight: FontWeight.w600,
                      color:      selected ? Colors.white : color)),
            ),
          ],
        ],
      ),
    ),
  );
}

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

    // shelf name badge color — hovered pe white text, normal pe primary tint
    final shelfBg   = widget.isHovered
        ? Colors.white.withOpacity(0.20)
        : AppColor.primary.withOpacity(0.08);
    final shelfText = widget.isHovered ? Colors.white : AppColor.primary;

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
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // ── Serial number ──────────────────────────────
                SizedBox(
                  width: 22,
                  child: Text('${widget.index}',
                      style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color: widget.isHovered ? accent : AppColor.textHint)),
                ),

                // ── Name + shelf badge ─────────────────────────
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product name
                      Text(
                        p.name,
                        style: TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color: widget.isHovered
                                ? accent
                                : inStock
                                ? AppColor.textPrimary
                                : AppColor.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // ── Shelf badge — sirf tab dikhao jab ho ──
                      if (p.shelfName != null && p.shelfName!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shelves,
                              size: 9,
                              color: widget.isHovered
                                  ? Colors.white.withOpacity(0.85)
                                  : AppColor.primary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color:        shelfBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.shelfName!,
                                style: TextStyle(
                                    fontSize:   9,
                                    fontWeight: FontWeight.w600,
                                    color:      shelfText),
                                maxLines:  1,
                                overflow:  TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Stock ──────────────────────────────────────
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

                // ── Price ──────────────────────────────────────
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