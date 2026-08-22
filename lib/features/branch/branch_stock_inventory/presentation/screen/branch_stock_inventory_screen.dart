import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/branch_stock_inventory/data/model/branch_stock_model.dart';

import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../../customer/presentation/widget/customer_action_button_widget.dart';
import '../../../customer/presentation/widget/customer_filter_chip_widget.dart';
import '../../data/datasource/branch_stock_remote_datasource.dart';
import '../provider/branch_stock_inventory_provider.dart';
import '../widget/delete_dilog_widget.dart';
import '../widget/edit_dilog_widget.dart';


class BranchStockInventoryScreen extends ConsumerStatefulWidget {
  const BranchStockInventoryScreen({super.key});

  @override
  ConsumerState<BranchStockInventoryScreen> createState() =>
      _BranchStockInventoryScreenState();
}

class _BranchStockInventoryScreenState
    extends ConsumerState<BranchStockInventoryScreen> {
  final _searchCtrl    = TextEditingController();
  final _scrollCtrl    = ScrollController();
  final _searchKbFocus = FocusNode(skipTraversal: true);

  // highlighted row index (rows list mein)
  int _highlightedIndex = -1;

  // feedback overlay (ProductListPanel jaisa)
  OverlayEntry? _feedbackOverlay;

  // row height — _DataRow height: 52
  static const double _rowHeight = 52.0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _searchKbFocus.dispose();
    _feedbackOverlay?.remove();
    super.dispose();
  }

  // ── Barcode / SKU exact match dhundho ─────────────────────────
  // branchStockProvider.allProducts use karta hai (saare products loaded)
  // phir current page rows mein index dhundta hai
  bool _tryBarcodeHighlight(String query) {
    if (query.isEmpty) return false;

    final allProducts = ref.read(branchStockProvider).allProducts;
    final rows        = ref.read(inventoryPageProvider).rows;

    // Step 1: exact barcode ya SKU match
    BranchStockModel? match = allProducts.cast<BranchStockModel?>().firstWhere(
          (p) =>
      (p!.barcode != null &&
          p.barcode!.toLowerCase().trim() == query.toLowerCase().trim()) ||
          p.sku.toLowerCase().trim() == query.toLowerCase().trim(),
      orElse: () => null,
    );

    // Step 2: agar exact nahi mila, single filtered result
    if (match == null) {
      final filtered = allProducts.where((p) =>
      p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.sku.toLowerCase().contains(query.toLowerCase()) ||
          (p.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
      if (filtered.length == 1) match = filtered.first;
    }

    if (match == null) return false;

    // Step 3: current page rows mein index dhundho
    final matchId = match.id;
    final idx = rows.indexWhere((r) => r.id == matchId);

    if (idx == -1) {
      // Product found lekin current page pe nahi —
      // normal search trigger karo taake page load ho
      return false;
    }

    // Step 4: highlight + scroll
    setState(() => _highlightedIndex = idx);
    _scrollToRow(idx);
    _showFoundFeedback(match!.name);
    return true;
  }

  void _scrollToRow(int index) {
    if (!_scrollCtrl.hasClients) return;
    final offset = index * _rowHeight;
    _scrollCtrl.animateTo(
      offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve:    Curves.easeOut,
    );
  }

  // ── Search field key events (↑↓ navigation + Escape) ──────────
  void _handleSearchKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    final key  = event.logicalKey;
    final rows = ref.read(inventoryPageProvider).rows;

    if (key == LogicalKeyboardKey.escape && event is KeyDownEvent) {
      if (_searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
        ref.read(inventoryPageProvider.notifier).onSearchChanged('');
        setState(() => _highlightedIndex = -1);
      }
      return;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (rows.isEmpty) return;
      setState(() =>
      _highlightedIndex = (_highlightedIndex + 1).clamp(0, rows.length - 1));
      _scrollToRow(_highlightedIndex);
      return;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      if (rows.isEmpty) return;
      setState(() =>
      _highlightedIndex = (_highlightedIndex - 1).clamp(0, rows.length - 1));
      _scrollToRow(_highlightedIndex);
      return;
    }
  }

  // ── Submit: barcode exact match try karo, warna normal search ──
  void _onSearchSubmitted(String value) {
    final query = value.trim();
    if (query.isEmpty) return;

    final highlighted = _tryBarcodeHighlight(query);
    if (!highlighted) {
      // Normal search — existing debounce wala call
      ref.read(inventoryPageProvider.notifier).onSearchChanged(query);
      setState(() => _highlightedIndex = -1);
    }
  }

  // ── Search field onChange: clear highlight, normal DB search ───
  void _onSearchChanged(String q) {
    setState(() => _highlightedIndex = -1);
    ref.read(inventoryPageProvider.notifier).onSearchChanged(q);
  }

  // ── Feedback overlay (ProductListPanel jaisa style) ────────────
  void _showFoundFeedback(String name) {
    _feedbackOverlay?.remove();
    _feedbackOverlay = OverlayEntry(
      builder: (_) => Positioned(
        top: 80, right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:        AppColor.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15), blurRadius: 8),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.search_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                name,
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
    Future.delayed(const Duration(milliseconds: 1600), () {
      _feedbackOverlay?.remove();
      _feedbackOverlay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(inventoryPageProvider);
    final notifier = ref.read(inventoryPageProvider.notifier);
    final posState = ref.watch(branchStockProvider);

    // highlight index out of range guard
    if (_highlightedIndex >= state.rows.length && state.rows.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
              (_) => setState(() => _highlightedIndex = state.rows.length - 1));
    }

    ref.listen<InventoryPageState>(inventoryPageProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.errorMessage!),
          backgroundColor: AppColor.error,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label:     'OK',
            textColor: Colors.white,
            onPressed: notifier.clearError,
          ),
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Stock Inventory',
            style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: notifier.refresh,
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style:   IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Stat Cards ────────────────────────────────────────
            Builder(builder: (_) {
              final auth     = ref.watch(authProvider);
              final products = posState.allProducts;
              final totalQty = products.fold(0.0, (s, p) => s + p.quantity);
              final totalCostVal = products.fold(
                  0.0, (s, p) => s + p.costPrice * p.quantity);
              final totalSaleVal = products.fold(
                  0.0, (s, p) => s + p.sellingPrice * p.quantity);

              final canSeeCost = auth.isOwner || auth.isManager;

              String fmtAmt(double v) {
                if (v == v.truncateToDouble()) return 'Rs ${v.toInt()}';
                final s = v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
                return 'Rs $s';
              }

              return Row(children: [
                SummaryCard(
                  title: 'Total Products',
                  value: '${posState.totalProducts.toStringAsFixed(0)}',
                  icon:  Icons.inventory_2_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Total Quantity',
                  value: totalQty.toStringAsFixed(2),
                  icon:  Icons.layers_outlined,
                  color: AppColor.info,
                ),
                if (canSeeCost) ...[
                  const SizedBox(width: 12),
                  SummaryCard(
                    title: 'Total Purchase Price',
                    value: fmtAmt(totalCostVal),
                    icon:  Icons.shopping_bag_outlined,
                    color: AppColor.warning,
                  ),
                ],
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Total Sale Price',
                  value: fmtAmt(totalSaleVal),
                  icon:  Icons.trending_up_rounded,
                  color: AppColor.success,
                ),
              ]);
            }),

            const SizedBox(height: 16),

            // ── Search + Filters ─────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                SizedBox(
                  width: 280,
                  child: KeyboardListener(
                    focusNode:  _searchKbFocus,
                    onKeyEvent: _handleSearchKey,
                    child: TextField(
                      controller:  _searchCtrl,
                      onChanged:   _onSearchChanged,
                      onSubmitted: _onSearchSubmitted,
                      style:        const TextStyle(fontSize: 13),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText: 'Search ya barcode scan karo...',
                        hintStyle: const TextStyle(
                            color: AppColor.textHint, fontSize: 13),
                        prefixIcon: const Icon(Icons.qr_code_scanner_rounded,
                            size: 18, color: AppColor.grey400),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 16, color: AppColor.grey400),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                            setState(() => _highlightedIndex = -1);
                          },
                        )
                            : null,
                        filled:    true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColor.primary, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ...[
                  ('all',          'All'),
                  ('in_stock',     'In Stock'),
                  ('low_stock',    'Low Stock'),
                  ('out_of_stock', 'Out of Stock'),
                ].map((f) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CustomerFilterChip(
                    label:         f.$2,
                    value:         f.$1,
                    selectedValue: state.filterStatus,
                    onTap:         notifier.onFilterStatusChanged,
                  ),
                )),

                // ── Hint text ──────────────────────────────────
                const SizedBox(width: 8),
                const Icon(Icons.info_outline_rounded,
                    size: 12, color: AppColor.textHint),
                const SizedBox(width: 4),
                const Text(
                  'Barcode scan → row highlight  |  ↑↓ navigate  |  Esc clear',
                  style: TextStyle(fontSize: 10, color: AppColor.textHint),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // ── Pagination Info + Controls (top) ─────────────────
            _PaginationBar(state: state, notifier: notifier),

            const SizedBox(height: 8),

            // ── Table ────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.rows.isEmpty
                  ? _EmptyState(isSearching: state.searchQuery.isNotEmpty)
                  : _InventoryTable(
                rows:             state.rows,
                scrollCtrl:       _scrollCtrl,
                highlightedIndex: _highlightedIndex,
                onRowTap: (idx) =>
                    setState(() => _highlightedIndex = idx),
              ),
            ),

            const SizedBox(height: 8),

            // ── Pagination Controls (bottom) ─────────────────────
            _PaginationBar(state: state, notifier: notifier),
          ],
        ),
      ),
    );
  }
}

// ── Pagination Bar ────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final InventoryPageState    state;
  final InventoryPageNotifier notifier;

  const _PaginationBar({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (state.totalCount == 0) return const SizedBox.shrink();

    return Row(children: [
      Text(
        '${state.fromRow}–${state.toRow} of ${state.totalCount} products',
        style: const TextStyle(
            fontSize: 13, color: AppColor.textSecondary),
      ),
      const Spacer(),

      if (state.totalPages > 1) ...[
        Text('Page',
            style: const TextStyle(
                fontSize: 13, color: AppColor.textSecondary)),
        const SizedBox(width: 6),
        _PageJumper(state: state, notifier: notifier),
        Text(' of ${state.totalPages}',
            style: const TextStyle(
                fontSize: 13, color: AppColor.textSecondary)),
        const SizedBox(width: 12),
      ],

      _NavBtn(
        icon:      Icons.chevron_left_rounded,
        tooltip:   'Previous page',
        enabled:   state.hasPrev,
        onPressed: notifier.prevPage,
      ),
      const SizedBox(width: 4),

      ..._visiblePages(state).map((p) => p == -1
          ? const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('…',
            style: TextStyle(color: AppColor.textSecondary)),
      )
          : _PageNumBtn(
        page:      p,
        isCurrent: p == state.currentPage,
        onTap:     () => notifier.goToPage(p),
      )),

      const SizedBox(width: 4),
      _NavBtn(
        icon:      Icons.chevron_right_rounded,
        tooltip:   'Next page',
        enabled:   state.hasNext,
        onPressed: notifier.nextPage,
      ),
    ]);
  }

  List<int> _visiblePages(InventoryPageState s) {
    final total   = s.totalPages;
    final current = s.currentPage;
    if (total <= 7) return List.generate(total, (i) => i);

    final Set<int> pages = {0, total - 1};
    for (int i = (current - 2).clamp(0, total - 1);
    i <= (current + 2).clamp(0, total - 1);
    i++) pages.add(i);

    final sorted = pages.toList()..sort();
    final result = <int>[];
    for (int i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) result.add(-1);
      result.add(sorted[i]);
    }
    return result;
  }
}

// ── Page Number Button ─────────────────────────────────────────────
class _PageNumBtn extends StatelessWidget {
  final int          page;
  final bool         isCurrent;
  final VoidCallback onTap;

  const _PageNumBtn({
    required this.page,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: InkWell(
      onTap:        isCurrent ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: isCurrent ? AppColor.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isCurrent ? null : Border.all(color: AppColor.grey200),
        ),
        alignment: Alignment.center,
        child: Text(
          '${page + 1}',
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      isCurrent ? Colors.white : AppColor.textPrimary,
          ),
        ),
      ),
    ),
  );
}

// ── Nav Button ────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData     icon;
  final String       tooltip;
  final bool         enabled;
  final VoidCallback onPressed;

  const _NavBtn({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: IconButton(
      onPressed: enabled ? onPressed : null,
      icon:      Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: enabled ? AppColor.grey100 : Colors.transparent,
        foregroundColor: enabled ? AppColor.textPrimary : AppColor.grey300,
        fixedSize: const Size(32, 32),
        padding:   EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6)),
      ),
    ),
  );
}

// ── Page Jumper Input ─────────────────────────────────────────────
class _PageJumper extends StatefulWidget {
  final InventoryPageState    state;
  final InventoryPageNotifier notifier;

  const _PageJumper({required this.state, required this.notifier});

  @override
  State<_PageJumper> createState() => _PageJumperState();
}

class _PageJumperState extends State<_PageJumper> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.state.displayPage}');
  }

  @override
  void didUpdateWidget(_PageJumper old) {
    super.didUpdateWidget(old);
    final newText = '${widget.state.displayPage}';
    if (_ctrl.text != newText && !_ctrl.selection.isValid) {
      _ctrl.text = newText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _jump() {
    final page = int.tryParse(_ctrl.text.trim());
    if (page == null) return;
    widget.notifier.goToPage(page - 1);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48, height: 30,
    child: TextField(
      controller:   _ctrl,
      textAlign:    TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600),
      cursorHeight: 14,
      onSubmitted:  (_) => _jump(),
      decoration: InputDecoration(
        isDense:   true,
        filled:    true,
        fillColor: AppColor.grey100,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
              color: AppColor.primary, width: 1.2),
        ),
      ),
    ),
  );
}

// ── Inventory Table ───────────────────────────────────────────────
class _InventoryTable extends ConsumerWidget {
  final List<BranchStockModel>   rows;
  final ScrollController          scrollCtrl;
  final int                       highlightedIndex;
  final void Function(int index)  onRowTap;

  const _InventoryTable({
    required this.rows,
    required this.scrollCtrl,
    required this.highlightedIndex,
    required this.onRowTap,
  });

  static const _widths = [
    120.0,  // SKU
    160.0,  // Barcode
    170.0,  // Name
    120.0,  // Shelf Name
    70.0,   // Unit
    110.0,  // Cost Price
    110.0,  // Sale Price
    110.0,  // Wholesale
    60.0,   // Tax
    90.0,   // Discount
    100.0,  // Min Stock
    100.0,  // Max Stock
    90.0,   // Quantity
    90.0,   // Actions
  ];

  static const _headers = [
    'SKU', 'Barcode', 'Name', 'Shelf Name',
    'Unit', 'Cost Price', 'Sale Price', 'Wholesale',
    'Tax', 'Discount', 'Min Stock', 'Max Stock',
    'Quantity', 'Actions',
  ];

  static const _costPriceColIdx = 5;

  static double get _totalWidth => _widths.fold(0.0, (s, w) => s + w) + 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth       = ref.watch(authProvider);
    final canSeeCost = auth.isOwner || auth.isManager;

    return LayoutBuilder(builder: (context, constraints) {
      final hiddenWidth = canSeeCost ? 0.0 : _widths[_costPriceColIdx];
      final tableWidth  = (_totalWidth - hiddenWidth)
          .clamp(constraints.maxWidth, double.infinity);
      const headerH    = 44.0;
      final rowsH      = constraints.maxHeight - headerH - 1;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [

              // ── Sticky header ──────────────────────────────────
              Container(
                height:  headerH,
                color:   AppColor.grey100,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(_headers.length, (i) {
                    if (i == _costPriceColIdx && !canSeeCost) {
                      return const SizedBox.shrink();
                    }
                    final isLast = i == _headers.length - 1;
                    return SizedBox(
                      width: _widths[i],
                      child: Text(
                        _headers[i],
                        textAlign: isLast
                            ? TextAlign.center
                            : TextAlign.left,
                        style: const TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color:      AppColor.textSecondary,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // ── Scrollable data rows ───────────────────────────
              SizedBox(
                height: rowsH,
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount:  rows.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, i) => _DataRow(
                    row:          rows[i],
                    index:        i,
                    widths:       _widths,
                    auth:         auth,
                    canSeeCost:   canSeeCost,
                    isHighlighted: i == highlightedIndex,
                    onTap:        () => onRowTap(i),
                    onEdit:       () => _openEditDialog(context, rows[i], auth),
                    onDelete:     () => _openDeleteDialog(context, rows[i]),
                    onDenied:     (action) => _showDenied(context, ref, action),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _openEditDialog(BuildContext ctx, BranchStockModel p, dynamic auth) =>
      showDialog(
        context:            ctx,
        barrierDismissible: false,
        builder: (_) => EditStockDialog(product: p, auth: auth),
      );

  void _openDeleteDialog(BuildContext ctx, BranchStockModel p) =>
      showDialog(
        context: ctx,
        builder: (_) => DeleteStockDialog(product: p),
      );

  void _showDenied(BuildContext ctx, WidgetRef ref, String action) =>
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content:         Text('Only manager can $action products'),
        backgroundColor: AppColor.error,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label:     'OK',
          textColor: Colors.white,
          onPressed: () =>
              ref.read(inventoryPageProvider.notifier).clearError(),
        ),
      ));
}

// ── Single data row ───────────────────────────────────────────────
class _DataRow extends ConsumerWidget {
  final BranchStockModel      row;
  final int                   index;
  final List<double>          widths;
  final dynamic               auth;
  final bool                  canSeeCost;
  final bool                  isHighlighted;   // ← NEW
  final VoidCallback          onTap;           // ← NEW
  final VoidCallback          onEdit;
  final VoidCallback          onDelete;
  final void Function(String) onDenied;

  const _DataRow({
    required this.row,
    required this.index,
    required this.widths,
    required this.auth,
    required this.canSeeCost,
    required this.isHighlighted,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onDenied,
  });

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEven   = index.isEven;
    final qtyColor = row.isOutOfStock
        ? AppColor.error
        : row.isLowStock
        ? AppColor.warning
        : AppColor.success;
    final auth      = ref.watch(authProvider);
    final isOwner   = auth.isOwner;

    // Highlighted row ka background + border
    Color rowBg;
    if (isHighlighted) {
      rowBg = AppColor.primary.withOpacity(0.10);
    } else {
      rowBg = isEven ? Colors.white : const Color(0xFFFAFAFF);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height:  52,
        color:   rowBg,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // SKU
            SizedBox(
              width: widths[0],
              child: Text(row.sku,
                  style: TextStyle(
                      fontSize: 12,
                      color: isHighlighted
                          ? AppColor.primary
                          : AppColor.textSecondary,
                      fontWeight: isHighlighted
                          ? FontWeight.w700
                          : FontWeight.normal)),
            ),
            // Barcode
            SizedBox(
              width: widths[1],
              child: Text(
                BranchStockDataSource().parseBarcode(row.barcode) ?? '—',
                style: TextStyle(
                    fontSize: 12,
                    color: isHighlighted
                        ? AppColor.primary
                        : AppColor.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Name
            SizedBox(
              width: widths[2],
              child: Column(
                mainAxisAlignment:  MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize:   13,
                          color: isHighlighted
                              ? AppColor.primary
                              : AppColor.textPrimary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  if (row.description != null)
                    Text(row.description!,
                        style: const TextStyle(
                            fontSize: 10, color: AppColor.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                ],
              ),
            ),
            // Shelf Name
            SizedBox(
              width: widths[3],
              child: row.shelfName != null && row.shelfName!.isNotEmpty
                  ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  row.shelfName!,
                  style: const TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              )
                  : const Text('—',
                  style: TextStyle(
                      fontSize: 13, color: AppColor.textSecondary)),
            ),
            // Unit
            SizedBox(
              width: widths[4],
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        AppColor.grey100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(row.unitOfMeasure,
                    style: const TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.textSecondary)),
              ),
            ),
            // Cost Price — sirf owner/manager
            if (canSeeCost)
              SizedBox(
                width: widths[5],
                child: Text(row.costPriceLabel,
                    style: const TextStyle(fontSize: 13)),
              ),
            // Sale Price
            SizedBox(
              width: widths[6],
              child: Text(row.sellingPriceLabel,
                  style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color: isHighlighted
                          ? AppColor.primary
                          : AppColor.primary)),
            ),
            // Wholesale
            SizedBox(
              width: widths[7],
              child: Text(row.wholesalePriceLabel,
                  style: const TextStyle(
                      fontSize: 13, color: AppColor.textSecondary)),
            ),
            // Tax
            SizedBox(
              width: widths[8],
              child: row.taxRate > 0
                  ? _Badge(value: row.taxRateLabel, color: AppColor.info)
                  : const Text('—',
                  style: TextStyle(
                      fontSize: 13, color: AppColor.textSecondary)),
            ),
            // Discount
            SizedBox(
              width: widths[9],
              child: row.discount > 0
                  ? _Badge(
                  value: row.discountLabel, color: AppColor.warning)
                  : const Text('—',
                  style: TextStyle(
                      fontSize: 13, color: AppColor.textSecondary)),
            ),
            // Min Stock
            SizedBox(
              width: widths[10],
              child: Text(
                '${row.minStockLevel} ${row.unitOfMeasure}',
                style: const TextStyle(
                    fontSize: 12, color: AppColor.textSecondary),
              ),
            ),
            // Max Stock
            SizedBox(
              width: widths[11],
              child: Text(
                '${row.maxStockLevel} ${row.unitOfMeasure}',
                style: const TextStyle(
                    fontSize: 12, color: AppColor.textSecondary),
              ),
            ),
            // Quantity
            SizedBox(
              width: widths[12],
              child: Text(
                _fmt(row.quantity),
                style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      qtyColor),
              ),
            ),
            // Actions — role-based
            SizedBox(
              width: widths[13],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomerActionButton(
                    icon:    Icons.edit_outlined,
                    color:   AppColor.primary,
                    tooltip: isOwner ? 'Edit' : 'Edit Shelf',
                    onTap:   onEdit,
                  ),
                  if (isOwner || auth.isManager) ...[
                    const SizedBox(width: 6),
                    CustomerActionButton(
                      icon:    Icons.delete_outline_rounded,
                      color:   AppColor.error,
                      tooltip: 'Delete',
                      onTap:   onDelete,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String value;
  final Color  color;
  const _Badge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(value,
        style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      color)),
  );
}

// ── Empty State ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({this.isSearching = false});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSearching
              ? Icons.search_off_rounded
              : Icons.inventory_2_outlined,
          size:  64,
          color: AppColor.grey300,
        ),
        const SizedBox(height: 16),
        Text(
          isSearching
              ? 'Koi product nahi mila'
              : 'Koi stock nahi',
          style: const TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          isSearching
              ? 'Search query change karein'
              : 'Products add hone ke baad yahan data aayega',
          style: const TextStyle(
              fontSize: 13, color: AppColor.textHint),
        ),
      ],
    ),
  );
}