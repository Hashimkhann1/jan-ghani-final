import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/model/product_model/product_model.dart';
import 'package:jan_ghani_final/utils/app_colors/app_colors.dart';
import 'package:jan_ghani_final/utils/constant/enum_constant/enum_constant.dart';
import 'package:jan_ghani_final/view/pos_terminal_view/pos_terminal_cart_widget/pos_terminal_cart_widget.dart';
import 'package:jan_ghani_final/view_model/pos_terminal_view_model/provider/pos_terminal_provider.dart';

class PosTerminalView extends ConsumerStatefulWidget {
  const PosTerminalView({super.key});

  @override
  ConsumerState<PosTerminalView> createState() => _PosTerminalViewState();
}

class _PosTerminalViewState extends ConsumerState<PosTerminalView> {
  static const _green = AppColors.primaryColors;
  static const _bgPage = Color(0xFFF4FAF7);
  static const _topBarBg = Color(0xFFFFFFFF);

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      'Rs${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                // ── Left: Products ──────────────────────────────────────
                Expanded(child: _buildProductsSection()),
                // ── Right: Cart ─────────────────────────────────────────

                SizedBox(height: MediaQuery.of(context).size.height * 0.83, child: VerticalDivider(color: Colors.grey.withOpacity(0.3),)),
                const PosTerminalCartWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 52,
      color: _topBarBg,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Online badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: _green.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('Online',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: _green)),
            ]),
          ),
          const SizedBox(width: 10),
          // Shift Open badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: const [
              SizedBox(width: 4),
              Text('Shift Open',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
          const SizedBox(width: 10),
          // Store + cash
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: const [
                Text('Jan Ghani· 5 days',
                    style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                SizedBox(width: 4),
                Text('| Rs520,640.00',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF888888)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          // Clock
          const Icon(Icons.access_time, size: 14, color: Color(0xFF888888)),
          const SizedBox(width: 4),
          const Text('08:21 AM',
              style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
          const Spacer(),
          // Right actions
          _TopBarAction(icon: Icons.list_alt_outlined, label: 'Orders', onTap: () {}),
          const SizedBox(width: 4),
          _TopBarAction(icon: Icons.pause_circle_outline, label: 'Hold', onTap: () {}),
          const SizedBox(width: 4),
          _TopBarAction(icon: Icons.history, label: 'Returns', onTap: () {}),
          const SizedBox(width: 4),
          _TopBarAction(icon: Icons.fullscreen, label: '', onTap: () {}),

        ],
      ),
    );
  }

  // ── Products Section ──────────────────────────────────────────────────────
  Widget _buildProductsSection() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryTabs(),
        _buildProductCountRow(),
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final posUi = ref.watch(posUiProvider);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF7F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => ref.read(posUiProvider.notifier).setSearch(v),
                decoration: InputDecoration(
                  hintText: 'Search products, SKU, or barcode...',
                  hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                  prefixIcon: const Icon(Icons.search,
                      size: 20, color: Color(0xFF9E9E9E)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Barcode scanner btn
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_scanner,
                size: 22, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Category Tabs ─────────────────────────────────────────────────────────
  Widget _buildCategoryTabs() {
    final categories = ref.watch(categoriesProvider);
    final counts = ref.watch(categoryCountProvider);
    final selected = ref.watch(posUiProvider).selectedCategory;

    return Container(
      color: Colors.white,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final count = counts[cat] ?? 0;
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => ref.read(posUiProvider.notifier).setCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _green : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Text(cat,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF444444))),
                const SizedBox(width: 4),
                Text('$count',
                    style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white.withOpacity(0.85)
                            : const Color(0xFF888888))),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Product Count + View Toggle ───────────────────────────────────────────
  Widget _buildProductCountRow() {
    final filtered = ref.watch(filteredProductsProvider);
    final isGrid = ref.watch(posUiProvider).isGridView;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Text('${filtered.length} products',
              style:
              const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          const Spacer(),
          // Grid / List toggle
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              _ViewToggle(
                icon: Icons.grid_view,
                isSelected: isGrid,
                onTap: () =>
                    ref.read(posUiProvider.notifier).setGridView(true),
              ),
              _ViewToggle(
                icon: Icons.format_list_bulleted,
                isSelected: !isGrid,
                onTap: () =>
                    ref.read(posUiProvider.notifier).setGridView(false),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Product Grid ──────────────────────────────────────────────────────────
  Widget _buildProductGrid() {
    final products = ref.watch(filteredProductsProvider);
    final isGrid = ref.watch(posUiProvider).isGridView;
    final cart = ref.watch(cartProvider);

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 40, color: Color(0xFFCCCCCC)),
            SizedBox(height: 8),
            Text('No products found',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
          ],
        ),
      );
    }

    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => _ProductCard(
          product: products[i],
          cartQty: cart.items
              .where((item) => item.product.sku == products[i].sku)
              .fold(0, (s, item) => s + item.quantity),
          onTap: () =>
              ref.read(cartProvider.notifier).addProduct(products[i]),
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        itemCount: products.length,
        itemBuilder: (_, i) => _ProductListTile(
          product: products[i],
          cartQty: cart.items
              .where((item) => item.product.sku == products[i].sku)
              .fold(0, (s, item) => s + item.quantity),
          onTap: () =>
              ref.read(cartProvider.notifier).addProduct(products[i]),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT CARD (Grid)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  final ProductModel product;
  final int cartQty;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.cartQty,
    required this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  Color get _statusColor {
    switch (widget.product.status) {
      case StockStatus.outOfStock:
        return Colors.red;
      case StockStatus.lowStock:
        return const Color(0xFFF59E0B);
      default:
        return AppColors.primaryColors;
    }
  }

  String get _statusLabel {
    switch (widget.product.status) {
      case StockStatus.outOfStock:
        return 'Out';
      case StockStatus.lowStock:
        return 'Low';
      default:
        return '';
    }
  }

  String _fmt(double v) =>
      'PKR ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = widget.product.status == StockStatus.outOfStock;

    return GestureDetector(
      onTap: isOutOfStock ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: widget.cartQty > 0 ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.cartQty > 0
                ? AppColors.primaryColors
                : const Color(0xFFE8E8E8),
            width: widget.cartQty > 0 ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image — fills top portion of card ──────────────────
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11)),
                    child: widget.product.image != null
                        ? Image.network(
                      widget.product.image!,
                      fit: BoxFit.fill,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _initials(),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryColors,
                            ),
                          ),
                        );
                      },
                    )
                        : _initials(),
                  ),
                ),
                // ── Info row ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOutOfStock
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _fmt(widget.product.value),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColors,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.product.stock > 0)
                            Text(
                              '${widget.product.stock}',
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF888888)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Cart qty badge
            if (widget.cartQty > 0)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(
                      color: AppColors.primaryColors, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${widget.cartQty}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),

            // Status badge (Low / Out)
            if (_statusLabel.isNotEmpty)
              Positioned(
                top: 6, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_statusLabel,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            // Variants badge
            if (widget.product.variants > 0)
              Positioned(
                top: 6,
                right: widget.cartQty > 0 ? 32 : 6,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text('${widget.product.variants}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            // Out of stock overlay
            if (isOutOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _initials() {
    return Container(
      color: const Color(0xFFF0FAF4),
      alignment: Alignment.center,
      child: Text(
        widget.product.initials,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w300,
          color: widget.product.status == StockStatus.outOfStock
              ? const Color(0xFFCCCCCC)
              : const Color(0xFFAAAAAA),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT LIST TILE (List view)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductListTile extends StatefulWidget {
  final ProductModel product;
  final int cartQty;
  final VoidCallback onTap;

  const _ProductListTile({
    required this.product,
    required this.cartQty,
    required this.onTap,
  });

  @override
  State<_ProductListTile> createState() => _ProductListTileState();
}

class _ProductListTileState extends State<_ProductListTile> {
  bool _hovered = false;

  String _fmt(double v) =>
      'PKR ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final isOut = widget.product.status == StockStatus.outOfStock;

    return GestureDetector(
      onTap: isOut ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.cartQty > 0
              ? const Color(0xFFECFDF5)
              : _hovered
              ? const Color(0xFFF8F8F8)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.cartQty > 0
                ? AppColors.primaryColors
                : const Color(0xFFE8E8E8),
          ),
        ),
        child: Row(
          children: [
            // Initials
            Container(
              width: 50,
              height: 50,

                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                ),
              padding: EdgeInsets.symmetric(vertical: 5),
              child: widget.product.image != null
                  ? Image.network(
                widget.product.image!,
                fit: BoxFit.contain, // ensures image fills clipped area
                errorBuilder: (_, __, ___) => Text("NI"),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColors,
                      ),
                    ),
                  );
                },
              ) : Text("H")
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOut
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF1A1A1A))),
                  Text(widget.product.sku,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF888888))),
                ],
              ),
            ),
            Text(_fmt(widget.product.value),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColors)),
            const SizedBox(width: 8),
            Text('${widget.product.stock}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _TopBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopBarAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF444444)),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF444444))),
          ]
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW TOGGLE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggle(
      {required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColors : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 16,
            color: isSelected ? Colors.white : const Color(0xFF888888)),
      ),
    );
  }
}