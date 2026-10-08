// Updated on 2026-10-08 09:09 AM
// =============================================================
// warehouse_stock_inventory_screen.dart
// Stitch "Jan Ghani — Stock Inventory v2" design:
// TopBar · 5 KPI cards (In/Low/Out = clickable filter) · toolbar
// (search, stock tabs + counts, Category / Company / Sort) · table
// (product, category, company, purchase, sale, stock, status, ⋮) ·
// footer (stock value / sale value + pagination)
// productProvider ki filter logic UNCHANGED — sort + pagination sirf
// is screen ka local UI state hai.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/category/presentation/provider/category_provider.dart';
import 'package:jan_ghani_final/features/warehouse/company/presentation/provider/company_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/widget/Print_barcode_widget.dart';
import '../../data/model/product_model.dart';
import '../../presentation/provider/product_provider.dart';
import '../widget/stock_inventory_dialog.dart';
import '../widget/product_audit_dialog.dart';

/// Qty display — 12 / 12.5 / 12.125 (trailing zeros hata ke)
String _fmtQty(double v) =>
    v.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');

String _rs(double v) => 'Rs ${v.pkrFormat}';

/// Sort options (local UI state)
const _kSortLabels = {
  'name_asc':   'Naam A–Z',
  'name_desc':  'Naam Z–A',
  'stock_asc':  'Stock kam pehle',
  'stock_desc': 'Stock zyada pehle',
  'newest':     'Naye pehle',
};

class WarehouseStockInventoryScreen extends ConsumerStatefulWidget {
  const WarehouseStockInventoryScreen({super.key});

  @override
  ConsumerState<WarehouseStockInventoryScreen> createState() =>
      _WarehouseStockInventoryScreenState();
}

class _WarehouseStockInventoryScreenState
    extends ConsumerState<WarehouseStockInventoryScreen> {
  String _sortBy   = 'name_asc';
  int    _page     = 0;
  int    _pageSize = 25;

  void _resetPage() => setState(() => _page = 0);

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(productProvider);
    final notifier = ref.read(productProvider.notifier);

    ref.listen<ProductState>(productProvider, (prev, next) {
      // Filter / search badle → pehla page
      if (prev != null &&
          (prev.searchQuery    != next.searchQuery    ||
           prev.filterStatus   != next.filterStatus   ||
           prev.filterCategory != next.filterCategory ||
           prev.filterCompany  != next.filterCompany)) {
        _resetPage();
      }
      if (next.errorMessage != null) {
        // Desktop ke liye chhota card, screen ke right side par (full-width nahi).
        final screenW = MediaQuery.of(context).size.width;
        const cardW = 420.0;
        final leftMargin = (screenW - cardW - 24).clamp(16.0, double.infinity);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.errorMessage!,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior:        SnackBarBehavior.floating,
            margin: EdgeInsets.only(left: leftMargin, right: 24, bottom: 24),
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () => ref.read(productProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    // Sort (local) — filteredProducts ki copy
    final sorted = [...state.filteredProducts];
    switch (_sortBy) {
      case 'name_asc':
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'stock_asc':
        sorted.sort((a, b) => a.availableQty.compareTo(b.availableQty));
        break;
      case 'stock_desc':
        sorted.sort((a, b) => b.availableQty.compareTo(a.availableQty));
        break;
      case 'newest':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return Scaffold(
      backgroundColor: AppColor.grey100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            isLoading: state.isLoading,
            onRefresh: () => notifier.loadProducts(),
            onAdd:     () => _showDialog(context, ref),
          ),
          Expanded(
            child: state.isLoading && state.allProducts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatsRow(
                    state:    state,
                    onFilter: (f) => notifier.onFilterStatusChanged(
                        state.filterStatus == f ? 'all' : f),
                  ),
                  const SizedBox(height: 16),
                  _Toolbar(
                    state:      state,
                    sortBy:     _sortBy,
                    onSearch:   notifier.onSearchChanged,
                    onStatus:   notifier.onFilterStatusChanged,
                    onCategory: notifier.onFilterCategoryChanged,
                    onCompany:  notifier.onFilterCompanyChanged,
                    onSort: (v) => setState(() {
                      _sortBy = v;
                      _page   = 0;
                    }),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _ProductTable(
                      products:    sorted,
                      isSearching: state.searchQuery.isNotEmpty ||
                          state.filterStatus   != 'all' ||
                          state.filterCategory != 'all' ||
                          state.filterCompany  != 'all',
                      page:       _page,
                      pageSize:   _pageSize,
                      onPage:     (p) => setState(() => _page = p),
                      onPageSize: (s) => setState(() {
                        _pageSize = s;
                        _page     = 0;
                      }),
                      onEdit:    (p) => _showDialog(context, ref, p),
                      onHistory: (p) => ProductAuditDialog.show(context, p),
                      onDelete:  (p) => _showDeleteDialog(context, ref, p),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool         isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const _TopBar({
    required this.isLoading,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color:  AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.inventory_2_outlined,
                size: 20, color: AppColor.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock Inventory',
                    style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textPrimary)),
                Text('Products, prices aur stock manage karein',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: AppColor.textSecondary)),
              ],
            ),
          ),
          Tooltip(
            message: 'Refresh',
            child: InkWell(
              onTap:        onRefresh,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border:       Border.all(color: AppColor.grey300),
                ),
                child: isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.refresh_rounded,
                    size: 18, color: AppColor.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon:  const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              minimumSize:   Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATS — 5 cards; In / Low / Out click = filter toggle
// ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final ProductState         state;
  final ValueChanged<String> onFilter;
  const _StatsRow({required this.state, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    // Saari counts poore (non-deleted) catalog se — filter ka asar nahi
    final live = state.allProducts.where((p) => p.deletedAt == null).toList();
    final total    = state.totalCount;
    final active   = state.activeCount;
    final inStock  = live.where((p) => p.quantity > 0).length; // 'in_stock' filter jaisa
    final low      = state.lowStockCount;
    final out      = live.where((p) => p.isOutOfStock).length;
    final value    = live
        .where((p) => p.isActive)
        .fold(0.0, (s, p) => s + (p.quantity > 0 ? p.quantity : 0) * p.purchasePrice);
    final inPct    = total == 0 ? 0 : (inStock * 100 / total).round();
    final sel      = state.filterStatus;

    return Row(
      children: [
        _StatCard(
          label:    'Total Products',
          value:    '$total',
          subtitle: '$active active · ${total - active} inactive',
          icon:     Icons.grid_view_rounded,
          color:    AppColor.primary,
        ),
        const SizedBox(width: 14),
        _StatCard(
          label:    'Inventory Value',
          value:    _rs(value),
          subtitle: 'purchase price par',
          icon:     Icons.account_balance_wallet_outlined,
          color:    AppColor.info,
        ),
        const SizedBox(width: 14),
        _StatCard(
          label:    'In Stock',
          value:    '$inStock',
          subtitle: '$inPct% products',
          icon:     Icons.check_circle_outline_rounded,
          color:    AppColor.success,
          selected: sel == 'in_stock',
          onTap:    () => onFilter('in_stock'),
        ),
        const SizedBox(width: 14),
        _StatCard(
          label:    'Low Stock',
          value:    '$low',
          subtitle: 'Reorder point se neeche',
          icon:     Icons.warning_amber_rounded,
          color:    AppColor.warning,
          subtitleColor: AppColor.warningDark,
          selected: sel == 'low_stock',
          onTap:    () => onFilter('low_stock'),
        ),
        const SizedBox(width: 14),
        _StatCard(
          label:    'Out of Stock',
          value:    '$out',
          subtitle: 'Available 0 ya kam',
          icon:     Icons.highlight_off_rounded,
          color:    AppColor.error,
          selected: sel == 'out_stock',
          onTap:    () => onFilter('out_stock'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String        label;
  final String        value;
  final String        subtitle;
  final IconData      icon;
  final Color         color;
  final Color?        subtitleColor;
  final bool          selected;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.subtitleColor,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.08) : AppColor.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : AppColor.grey200,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize:      11,
                              fontWeight:    FontWeight.w600,
                              letterSpacing: 0.6,
                              color: selected
                                  ? (subtitleColor ?? color)
                                  : AppColor.textSecondary)),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      Container(width: 6, height: 6,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: color)),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color:        color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: subtitleColor ?? color, size: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit:       BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: TextStyle(
                          fontSize:   22,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? (subtitleColor ?? color)
                              : AppColor.textPrimary)),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w500,
                        color:      subtitleColor ?? color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOOLBAR — search · stock tabs · Category / Company / Sort
// ─────────────────────────────────────────────────────────────
class _Toolbar extends ConsumerWidget {
  final ProductState          state;
  final String                sortBy;
  final ValueChanged<String>  onSearch;
  final ValueChanged<String>  onStatus;
  final ValueChanged<String>  onCategory;
  final ValueChanged<String>  onCompany;
  final ValueChanged<String>  onSort;

  const _Toolbar({
    required this.state,
    required this.sortBy,
    required this.onSearch,
    required this.onStatus,
    required this.onCategory,
    required this.onCompany,
    required this.onSort,
  });

  static const _tabs = [
    ('All',      'all'),
    ('In Stock', 'in_stock'),
    ('Low',      'low_stock'),
    ('Out',      'out_stock'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tab counts — search + category + company ke baad (status ke ilawa).
    // Provider ke _computeFiltered ka mirror (status chhod kar).
    final q   = state.searchQuery.toLowerCase();
    final cat = state.filterCategory;
    final com = state.filterCompany;
    final base = state.allProducts.where((p) {
      if (p.deletedAt != null)                         return false;
      if (cat != 'all' && p.categoryId != cat)         return false;
      if (com != 'all' && p.companyId  != com)         return false;
      if (q.isNotEmpty) {
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.barcodes.any((b) => b.toLowerCase().contains(q)) ||
            (p.categoryName?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
    final counts = {
      'all':       base.length,
      'in_stock':  base.where((p) => p.quantity > 0).length,
      'low_stock': base.where((p) => p.isLowStock).length,
      'out_stock': base.where((p) => p.isOutOfStock).length,
    };

    final categories = ref
        .watch(categoryProvider)
        .allCategories
        .where((c) => c.isActive && c.deletedAt == null)
        .map((c) => (id: c.id, name: c.name))
        .toList();
    final companies = ref
        .watch(companyProvider)
        .allCompanies
        .where((c) => c.isActive && c.deletedAt == null)
        .map((c) => (id: c.id, name: c.name))
        .toList();

    final tabs = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(9),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, key) in _tabs)
            _StatusTab(
              label:    label,
              count:    counts[key] ?? 0,
              selected: state.filterStatus == key,
              // Low / Out tab amber / red selected rang
              color: key == 'low_stock'
                  ? AppColor.warningDark
                  : key == 'out_stock' ? AppColor.error
                  : key == 'in_stock'  ? AppColor.success
                  : AppColor.primary,
              onTap: () => onStatus(key),
            ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 400,
                child: _SearchField(
                  initial:   state.searchQuery,
                  onChanged: onSearch,
                ),
              ),
              const Spacer(),
              Flexible(
                flex: 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: tabs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SearchableFilterDropdown(
                prefix:      'Category',
                allLabel:    'All Categories',
                items:       categories,
                selectedId:  state.filterCategory,
                onChanged:   onCategory,
                activeColor: AppColor.primary,
              ),
              const SizedBox(width: 10),
              _SearchableFilterDropdown(
                prefix:      'Company',
                allLabel:    'All Companies',
                items:       companies,
                selectedId:  state.filterCompany,
                onChanged:   onCompany,
                activeColor: AppColor.success,
              ),
              const SizedBox(width: 10),
              _SortField(value: sortBy, onChanged: onSort),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String       label;
  final int          count;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _StatusTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? AppColor.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: selected ? color.withOpacity(0.5) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize:   12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : AppColor.textPrimary,
                )),
            const SizedBox(width: 6),
            Container(
              padding: selected
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(count.toDouble().pkrFormat,
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : AppColor.textSecondary,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search field (name / SKU / barcode) ──────────────────────
class _SearchField extends StatefulWidget {
  final String               initial;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.initial, required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller =
  TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: _controller,
        onChanged: (q) {
          widget.onChanged(q);
          setState(() {});
        },
        style: const TextStyle(fontSize: 13.5, color: AppColor.textPrimary),
        decoration: InputDecoration(
          hintText:  'Name, SKU ya barcode se search...',
          hintStyle: const TextStyle(fontSize: 13.5, color: AppColor.textHint),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColor.grey600),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              _controller.clear();
              widget.onChanged('');
              setState(() {});
            },
          )
              : const Icon(Icons.qr_code_scanner_rounded,
              size: 20, color: AppColor.grey600),
          filled:    true,
          fillColor: AppColor.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.grey300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.grey300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
        ),
      ),
    );
  }
}

// ── Sort dropdown (local) ────────────────────────────────────
class _SortField extends StatelessWidget {
  final String               value;
  final ValueChanged<String> onChanged;
  const _SortField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip:    'Sort',
      onSelected: onChanged,
      offset:     const Offset(0, 46),
      color:      AppColor.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColor.grey200)),
      itemBuilder: (_) => [
        for (final e in _kSortLabels.entries)
          CheckedPopupMenuItem<String>(
            value:   e.key,
            checked: e.key == value,
            child:   Text(e.value, style: const TextStyle(fontSize: 13)),
          ),
      ],
      child: Container(
        height:  42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color:        AppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: AppColor.grey300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sort:',
                style: TextStyle(fontSize: 13, color: AppColor.textSecondary)),
            const SizedBox(width: 8),
            Text(_kSortLabels[value] ?? '',
                style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color:      AppColor.textPrimary)),
            const SizedBox(width: 8),
            const Icon(Icons.sort_by_alpha_rounded,
                size: 16, color: AppColor.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRODUCT TABLE + pagination
// ─────────────────────────────────────────────────────────────
const int    _kColProduct  = 5;
const int    _kColCategory = 2;
const int    _kColCompany  = 2;
const int    _kColPurchase = 2;
const int    _kColSale     = 2;
const int    _kColStock    = 2;
const int    _kColStatus   = 2;
const double _kColActions  = 64;

class _ProductTable extends StatefulWidget {
  final List<ProductModel>         products;
  final bool                       isSearching;
  final int                        page;
  final int                        pageSize;
  final ValueChanged<int>          onPage;
  final ValueChanged<int>          onPageSize;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onHistory;
  final ValueChanged<ProductModel> onDelete;

  const _ProductTable({
    required this.products,
    required this.isSearching,
    required this.page,
    required this.pageSize,
    required this.onPage,
    required this.onPageSize,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
  });

  @override
  State<_ProductTable> createState() => _ProductTableState();
}

class _ProductTableState extends State<_ProductTable> {
  static const double _minWidth = 900;
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list      = widget.products;
    final pageCount = list.isEmpty ? 1 : ((list.length - 1) ~/ widget.pageSize) + 1;
    final page      = widget.page.clamp(0, pageCount - 1);
    final start     = page * widget.pageSize;
    final end       = (start + widget.pageSize).clamp(0, list.length);
    final rows      = list.isEmpty ? const <ProductModel>[] : list.sublist(start, end);

    return Container(
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = constraints.maxWidth >= _minWidth
                      ? constraints.maxWidth
                      : _minWidth;
                  return Scrollbar(
                    controller:      _hScroll,
                    thumbVisibility: constraints.maxWidth < _minWidth,
                    child: SingleChildScrollView(
                      controller:      _hScroll,
                      scrollDirection: Axis.horizontal,
                      physics:         const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            const _TableHeader(),
                            Expanded(
                              child: rows.isEmpty
                                  ? _EmptyState(isSearching: widget.isSearching)
                                  : ListView.builder(
                                itemCount:  rows.length,
                                itemExtent: 64, // fixed height — scroll fast
                                itemBuilder: (context, i) {
                                  final p = rows[i];
                                  return RepaintBoundary(
                                    child: _ProductRow(
                                      key:       ValueKey(p.id),
                                      product:   p,
                                      onEdit:    () => widget.onEdit(p),
                                      onHistory: () => widget.onHistory(p),
                                      onDelete:  () => widget.onDelete(p),
                                      onPrintQR: () => PrintBarcodeWidget.show(context, p),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _TableFooter(
              all:        list,
              shown:      rows.length,
              start:      start,
              page:       page,
              pageCount:  pageCount,
              pageSize:   widget.pageSize,
              onPage:     widget.onPage,
              onPageSize: widget.onPageSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height:  48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color:  AppColor.primary.withOpacity(0.04),
        border: const Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: const Row(
        children: [
          _TH('PRODUCT',  _kColProduct),
          _TH('CATEGORY', _kColCategory),
          _TH('COMPANY',  _kColCompany),
          _TH('PURCHASE', _kColPurchase, align: TextAlign.right),
          _TH('SALE',     _kColSale,     align: TextAlign.right),
          _TH('STOCK',    _kColStock,    align: TextAlign.right),
          SizedBox(width: 28),
          _TH('STATUS',   _kColStatus),
          SizedBox(
            width: _kColActions,
            child: Text('ACTIONS', textAlign: TextAlign.right, style: _TH.style),
          ),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String    text;
  final int       flex;
  final TextAlign align;
  const _TH(this.text, this.flex, {this.align = TextAlign.left});

  static const style = TextStyle(
      fontSize:      11,
      fontWeight:    FontWeight.w600,
      letterSpacing: 0.6,
      color:         AppColor.textSecondary);

  @override
  Widget build(BuildContext context) => Expanded(
    flex:  flex,
    child: Text(text, textAlign: align, style: style),
  );
}

// ── Product row ──────────────────────────────────────────────
class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onDelete;
  final VoidCallback onPrintQR;

  const _ProductRow({
    required super.key,
    required this.product,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
    required this.onPrintQR,
  });

  static const _thumbBg = [
    Color(0xFFFEF3C7), Color(0xFFDCFCE7), Color(0xFFFEE2E2),
    Color(0xFFE0E7FF), Color(0xFFCCFBF1), Color(0xFFFCE7F3),
  ];
  static const _thumbFg = [
    Color(0xFFB45309), Color(0xFF15803D), Color(0xFFB91C1C),
    Color(0xFF4338CA), Color(0xFF0F766E), Color(0xFFBE185D),
  ];

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p   = product;
    final ini = _initials(p.name);
    final ci  = ini.codeUnitAt(0) % _thumbBg.length;

    // Stock rang: out = laal, low = amber, warna normal
    final stockColor = p.isOutOfStock
        ? AppColor.error
        : p.isLowStock ? AppColor.warningDark : AppColor.textPrimary;

    final margin = (p.purchasePrice > 0 && p.sellingPrice > 0)
        ? (p.sellingPrice - p.purchasePrice) * 100 / p.purchasePrice
        : null;

    final sub = [
      'SKU: ${p.sku}',
      if (p.primaryBarcode != null && p.primaryBarcode!.isNotEmpty) p.primaryBarcode!,
    ].join(' · ');

    return _HoverRow(
        child: Opacity(
          opacity: p.isActive ? 1 : 0.6,
          child: Row(
            children: [
              // ── Product ───────────────────────────────
              Expanded(
                flex: _kColProduct,
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color:        _thumbBg[ci],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(ini,
                          style: TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w700,
                              color:      _thumbFg[ci])),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        mainAxisAlignment:  MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize:   14,
                                  fontWeight: FontWeight.w600,
                                  color:      AppColor.textPrimary)),
                          Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5, color: AppColor.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Category / Company chips ──────────────
              Expanded(
                flex: _kColCategory,
                child: _TagChip(
                  label: p.categoryName ?? '—',
                  color: AppColor.primary,
                ),
              ),
              Expanded(
                flex: _kColCompany,
                child: _TagChip(
                  label: p.companyName ?? '—',
                  color: AppColor.success,
                ),
              ),

              // ── Purchase ──────────────────────────────
              Expanded(
                flex: _kColPurchase,
                child: Text(_rs(p.purchasePrice),
                    textAlign: TextAlign.right,
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, color: AppColor.textPrimary)),
              ),

              // ── Sale + margin ─────────────────────────
              Expanded(
                flex: _kColSale,
                child: Column(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_rs(p.sellingPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColor.textPrimary)),
                    if (margin != null)
                      Text(
                        '${margin >= 0 ? '+' : ''}${margin.toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize:   10.5,
                            fontWeight: FontWeight.w600,
                            color: margin >= 0
                                ? AppColor.success : AppColor.error),
                      ),
                  ],
                ),
              ),

              // ── Stock (physical + reserved) ───────────
              Expanded(
                flex: _kColStock,
                child: Column(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.quantity < 0 ? '−${_fmtQty(-p.quantity)}' : _fmtQty(p.quantity)} ${p.unitOfMeasure}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w700,
                          color:      stockColor),
                    ),
                    // Reserved ho to available + reserved sub-label
                    if (p.reservedQty > 0)
                      Text(
                        '${_fmtQty(p.availableQty)} free · ${_fmtQty(p.reservedQty)} reserved',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColor.textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 28),

              // ── Status ────────────────────────────────
              Expanded(
                flex: _kColStatus,
                child: Align(
                  alignment: Alignment.centerLeft,
                  // Tang column par pill chhota ho jaye (overflow nahi)
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _StatusPill(product: p),
                  ),
                ),
              ),

              // ── ⋮ menu ────────────────────────────────
              SizedBox(
                width: _kColActions,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _RowMenu(
                    onEdit:    onEdit,
                    onHistory: onHistory,
                    onPrintQR: onPrintQR,
                    onDelete:  onDelete,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// ── Row hover — sirf halka grey, ek waqt mein ek hi row ──────
// (pehle ValueNotifier StatelessWidget mein tha — rebuild par hover
//  atak jata tha aur kai rows rangeen reh jati thin)
class _HoverRow extends StatefulWidget {
  final Widget child;
  const _HoverRow({required this.child});

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hover = false;

  @override
  void deactivate() {
    _hover = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) { if (mounted) setState(() => _hover = true);  },
      onExit:  (_) { if (mounted) setState(() => _hover = false); },
      child: Container(
        decoration: BoxDecoration(
          color: _hover ? AppColor.grey100 : AppColor.surface,
          border: const Border(bottom: BorderSide(color: AppColor.grey200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: widget.child,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ProductModel product;
  const _StatusPill({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final (String label, Color fg, Color bg) = p.isOutOfStock
        ? ('Out of Stock', AppColor.error, AppColor.errorLight)
        : p.isLowStock
        ? ('Low Stock', AppColor.warningDark, AppColor.warningLight)
        : ('In Stock', AppColor.success, AppColor.successLight);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: fg)),
          const SizedBox(width: 5),
          Text(label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

// ── ⋮ menu: Edit · Stock history · Print QR · Delete ─────────
class _RowMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onPrintQR;
  final VoidCallback onDelete;

  const _RowMenu({
    required this.onEdit,
    required this.onHistory,
    required this.onPrintQR,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip:     'Actions',
      offset:      const Offset(0, 38),
      color:       AppColor.surface,
      constraints: const BoxConstraints(minWidth: 220),
      icon: const Icon(Icons.more_vert_rounded,
          size: 20, color: AppColor.grey700),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColor.grey200)),
      onSelected: (value) {
        switch (value) {
          case 'edit':    onEdit();    break;
          case 'history': onHistory(); break;
          case 'printQr': onPrintQR(); break;
          case 'delete':  onDelete();  break;
        }
      },
      itemBuilder: (_) => [
        _item('edit',    Icons.edit_outlined,           'Edit karein'),
        _item('history', Icons.history_rounded,         'Stock history'),
        _item('printQr', Icons.print_outlined,          'Print QR / barcode'),
        const PopupMenuDivider(height: 8),
        _item('delete',  Icons.delete_outline_rounded,  'Delete', danger: true),
      ],
    );
  }

  PopupMenuItem<String> _item(String v, IconData icon, String label,
      {bool danger = false}) =>
      PopupMenuItem<String>(
        value:  v,
        height: 42,
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: danger ? AppColor.error : AppColor.textPrimary),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: danger ? AppColor.error : AppColor.textPrimary)),
          ],
        ),
      );
}

// ── Footer: count · stock / sale value · pagination ──────────
class _TableFooter extends StatelessWidget {
  final List<ProductModel> all;
  final int                shown;
  final int                start;
  final int                page;
  final int                pageCount;
  final int                pageSize;
  final ValueChanged<int>  onPage;
  final ValueChanged<int>  onPageSize;

  const _TableFooter({
    required this.all,
    required this.shown,
    required this.start,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.onPage,
    required this.onPageSize,
  });

  @override
  Widget build(BuildContext context) {
    double stockValue = 0, saleValue = 0;
    for (final p in all) {
      final q = p.quantity > 0 ? p.quantity : 0;
      stockValue += q * p.purchasePrice;
      saleValue  += q * p.sellingPrice;
    }

    const muted = TextStyle(fontSize: 12.5, color: AppColor.textSecondary);
    const bold  = TextStyle(fontSize: 12.5,
        fontWeight: FontWeight.w700, color: AppColor.textPrimary);

    final countText = Text.rich(TextSpan(style: muted, children: [
      const TextSpan(text: 'Showing '),
      TextSpan(text: all.isEmpty ? '0' : '${start + 1}–${start + shown}', style: bold),
      const TextSpan(text: ' of '),
      TextSpan(text: all.length.toDouble().pkrFormat, style: bold),
      const TextSpan(text: ' products'),
    ]));

    final summary = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Text.rich(TextSpan(style: muted, children: [
        const TextSpan(text: 'Stock value '),
        TextSpan(text: _rs(stockValue), style: bold),
        const TextSpan(text: '   ·   Sale value '),
        TextSpan(text: _rs(saleValue),
            style: bold.copyWith(color: AppColor.success)),
      ])),
    );

    final pager = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Show', style: muted),
        const SizedBox(width: 8),
        PopupMenuButton<int>(
          tooltip:    'Rows per page',
          onSelected: onPageSize,
          color:      AppColor.surface,
          itemBuilder: (_) => [
            for (final n in const [25, 50, 100])
              CheckedPopupMenuItem<int>(
                value:   n,
                checked: n == pageSize,
                child:   Text('$n', style: const TextStyle(fontSize: 13)),
              ),
          ],
          child: Container(
            height:  32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border:       Border.all(color: AppColor.grey300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$pageSize', style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: AppColor.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        _PageBtn(
          icon:  Icons.chevron_left_rounded,
          onTap: page > 0 ? () => onPage(page - 1) : null,
        ),
        for (final p in _pages())
          p == -1
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('…', style: muted),
          )
              : _PageBtn(
            label:    '${p + 1}',
            selected: p == page,
            onTap:    () => onPage(p),
          ),
        _PageBtn(
          icon:  Icons.chevron_right_rounded,
          onTap: page < pageCount - 1 ? () => onPage(page + 1) : null,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColor.grey200))),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 1050) {
            return Row(
              children: [
                countText,
                const Spacer(),
                summary,
                const Spacer(),
                pager,
              ],
            );
          }
          return SizedBox(
            width: double.infinity,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing:            16,
              runSpacing:         8,
              children: [countText, summary, pager],
            ),
          );
        },
      ),
    );
  }

  /// 1 … (page-1) page (page+1) … last — -1 = ellipsis
  List<int> _pages() {
    if (pageCount <= 7) return List.generate(pageCount, (i) => i);
    final set = <int>{0, pageCount - 1, page - 1, page, page + 1}
      ..removeWhere((p) => p < 0 || p >= pageCount);
    final sorted = set.toList()..sort();
    final out = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) out.add(-1);
      out.add(sorted[i]);
    }
    return out;
  }
}

class _PageBtn extends StatelessWidget {
  final String?       label;
  final IconData?     icon;
  final bool          selected;
  final VoidCallback? onTap;

  const _PageBtn({
    this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          constraints: const BoxConstraints(minWidth: 32),
          height:      32,
          padding:     const EdgeInsets.symmetric(horizontal: 8),
          alignment:   Alignment.center,
          decoration: BoxDecoration(
            color:        selected ? AppColor.primary : AppColor.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
                color: selected ? AppColor.primary : AppColor.grey300),
          ),
          child: icon != null
              ? Icon(icon, size: 18,
              color: disabled ? AppColor.grey400 : AppColor.textPrimary)
              : Text(label!,
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColor.white : AppColor.textPrimary)),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isSearching;
  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(isSearching ? Icons.search_off_rounded : Icons.inventory_2_outlined,
          size: 56, color: AppColor.grey300),
      const SizedBox(height: 12),
      Text(isSearching ? 'Koi product nahi mila' : 'Abhi tak koi product nahi',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: AppColor.textSecondary)),
      const SizedBox(height: 4),
      Text(isSearching ? 'Search ya filter change karein' : 'Add Product button se product add karein',
          style: const TextStyle(fontSize: 13, color: AppColor.textHint)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
// SEARCHABLE FILTER DROPDOWN (Category + Company) — closed field
// "Category: All" style; menu wahi purana (_MenuSearchBody)
// ─────────────────────────────────────────────────────────────
class _SearchableFilterDropdown extends StatefulWidget {
  final String                            prefix;     // "Category" / "Company"
  final String                            allLabel;   // menu ka "All ..." item
  final List<({String id, String name})>  items;
  final String                            selectedId; // 'all' ya id
  final ValueChanged<String>              onChanged;
  final Color                             activeColor;

  const _SearchableFilterDropdown({
    required this.prefix,
    required this.allLabel,
    required this.items,
    required this.selectedId,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  State<_SearchableFilterDropdown> createState() =>
      _SearchableFilterDropdownState();
}

class _SearchableFilterDropdownState extends State<_SearchableFilterDropdown> {
  final _fieldKey = GlobalKey();

  Future<void> _openMenu() async {
    final ctx = _fieldKey.currentContext;
    if (ctx == null) return;
    final box        = ctx.findRenderObject() as RenderBox;
    final overlayBox = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    final topLeft    = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size       = box.size;

    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy + size.height + 4,
      overlayBox.size.width - (topLeft.dx + size.width),
      0,
    );

    final picked = await showMenu<String>(
      context:  ctx,
      position: position,
      color:    Colors.white,
      elevation: 8,
      constraints: BoxConstraints.tightFor(
          width: size.width < 240 ? 240 : size.width),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _MenuSearchBody(
            allLabel:    widget.allLabel,
            items:       widget.items,
            selectedId:  widget.selectedId,
            activeColor: widget.activeColor,
            onPick:      (v) => Navigator.pop(ctx, v),
          ),
        ),
      ],
    );

    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final validIds = widget.items.map((e) => e.id).toSet();
    final safeValue = (widget.selectedId != 'all' &&
            validIds.contains(widget.selectedId))
        ? widget.selectedId
        : 'all';
    final isFiltered = safeValue != 'all';
    final label = isFiltered
        ? widget.items.firstWhere((e) => e.id == safeValue).name
        : 'All';
    final c = widget.activeColor;

    return InkWell(
      onTap:        _openMenu,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        key:     _fieldKey,
        height:  42,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          color:        AppColor.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isFiltered ? c.withOpacity(0.6) : AppColor.grey300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.prefix}:',
                style: const TextStyle(
                    fontSize: 13, color: AppColor.textSecondary)),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: 160),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:        c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600, color: c)),
            ),
            const SizedBox(width: 4),
            // Filter laga ho to ✕ (wapas All), warna arrow
            if (isFiltered)
              Tooltip(
                message: 'All products show karo',
                child: InkWell(
                  onTap:        () => widget.onChanged('all'),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: c),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColor.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Functions (dialogs — unchanged) ───────────────────
// ── Helper Functions ──────────────────────────────────────────
void _showDialog(BuildContext context, WidgetRef ref, [ProductModel? product]) {
  showDialog(context: context, barrierDismissible: false, builder: (_) => StockInventoryDialog(product: product));
}

void _showDeleteDialog(BuildContext context, WidgetRef ref, ProductModel product) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFFFEF2F2), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Column(children: [
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 28)),
              const SizedBox(height: 12),
              const Text("Delete Product", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23))),
              const SizedBox(height: 6),
              Text('"${product.name}" ko delete karna chahte hain?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF6C7280), height: 1.5)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Expanded(child: Text("Product soft delete hoga", style: TextStyle(fontSize: 12, color: Color(0xFF6C7280)))),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), side: const BorderSide(color: Color(0xFFE5E7EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Cancel", style: TextStyle(color: Color(0xFF6C7280), fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(
                onPressed: () { Navigator.pop(ctx); ref.read(productProvider.notifier).deleteProduct(product.id); },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              )),
            ]),
          ),
        ],
      ),
    ),
  );
}

// ── Menu body: autofocus search + filtered list ───────────────
class _MenuSearchBody extends StatefulWidget {
  final String                            allLabel;
  final List<({String id, String name})>  items;
  final String                            selectedId;
  final Color                             activeColor;
  final ValueChanged<String>              onPick;

  const _MenuSearchBody({
    required this.allLabel,
    required this.items,
    required this.selectedId,
    required this.activeColor,
    required this.onPick,
  });

  @override
  State<_MenuSearchBody> createState() => _MenuSearchBodyState();
}

class _MenuSearchBodyState extends State<_MenuSearchBody> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items
            .where((e) => e.name.toLowerCase().contains(q))
            .toList();

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Search field (autofocus) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: Color(0xFF9CA3AF)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: widget.activeColor, width: 1.3),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // ── Options list ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              children: [
                if (q.isEmpty)
                  _row(id: 'all', name: widget.allLabel, isAll: true),
                ...filtered.map((e) => _row(id: e.id, name: e.name)),
                if (filtered.isEmpty && q.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text('Kuch nahi mila',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF9CA3AF))),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({required String id, required String name, bool isAll = false}) {
    final selected = widget.selectedId == id;
    return InkWell(
      onTap: () => widget.onPick(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: selected ? const Color(0xFFF3F4F6) : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isAll
                      ? const Color(0xFF717275)
                      : const Color(0xFF1A1D23),
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 16, color: widget.activeColor),
          ],
        ),
      ),
    );
  }
}

