import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../../../../../core/widget/dropwdown/app_drop_down.dart';
import '../../data/model/accountant_branch_stock_inventory_model.dart';
import '../../data/service/accountant_branch_inventory_pdf_service.dart';
import '../provider/accountant_branch_stock_inventory_provider.dart';

class AccountantBranchInventoryReportScreen extends ConsumerStatefulWidget {
  const AccountantBranchInventoryReportScreen({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<AccountantBranchInventoryReportScreen> createState() =>
      _AccountantBranchInventoryReportScreenState();
}

class _AccountantBranchInventoryReportScreenState
    extends ConsumerState<AccountantBranchInventoryReportScreen> {
  final _searchCtrl = TextEditingController();
  final _amtFmt = NumberFormat('#,##,###.##', 'en_IN');

  String _fmtAmt(double v) => 'Rs ${_amtFmt.format(v)}';
  String _fmtQty(double q) => q.toStringAsFixed(2);
  bool _isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 800;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountantBranchInventoryProvider(widget.branchId));
    final notifier = ref.read(accountantBranchInventoryProvider(widget.branchId).notifier);
    final desktop = _isDesktop(context);

    ref.listen<AccountantBranchInventoryState>(
      accountantBranchInventoryProvider(widget.branchId),
          (_, next) {
        if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: notifier.clearError,
            ),
          ));
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: desktop
          ? _DesktopLayout(
        state: state,
        notifier: notifier,
        fmtAmt: _fmtAmt,
        fmtQty: _fmtQty,
        searchCtrl: _searchCtrl,
      )
          : _MobileLayout(
        state: state,
        notifier: notifier,
        fmtAmt: _fmtAmt,
        fmtQty: _fmtQty,
        searchCtrl: _searchCtrl,
      ),
    );
  }
}

// Helper: build category dropdown items (shared by desktop + mobile)
List<DropdownItem<String?>> _categoryDropdownItems(List<CategoryModel> categories) {
  return [
    const DropdownItem<String?>(value: null, label: 'All Categories', icon: Icons.apps_rounded),
    ...categories.map((c) => DropdownItem<String?>(
      value: c.id,
      label: c.name,
      icon: Icons.category_outlined,
    )),
  ];
}

// Export PDF — hamesha state.filtered (current applied filters) use karta hai
Future<void> _exportPdf(BuildContext context, AccountantBranchInventoryState state) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Generating PDF...'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));

    String? categoryName;
    if (state.categoryFilter != null) {
      final match = state.categories.where((c) => c.id == state.categoryFilter);
      categoryName = match.isNotEmpty ? match.first.name : null;
    }

    await AccountantBranchInventoryPdfService.exportAndShare(
      items: state.filtered,
      categoryName: categoryName,
      stockFilter: state.stockFilter,
      deadStockOnly: state.deadStockOnly,
      searchQuery: state.searchQuery,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: AppColor.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP LAYOUT
// ══════════════════════════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final AccountantBranchInventoryState state;
  final dynamic notifier;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;
  final TextEditingController searchCtrl;

  const _DesktopLayout({
    required this.state,
    required this.notifier,
    required this.fmtAmt,
    required this.fmtQty,
    required this.searchCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1D23)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F6FA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Inventory Report',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23))),
                  SizedBox(height: 2),
                  Text('Complete branch stock details',
                      style: TextStyle(fontSize: 13, color: AppColor.textHint)),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 130,
                child: ElevatedButton.icon(
                  onPressed: () => _exportPdf(context, state),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: OutlinedButton.icon(
                  onPressed: notifier.load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: const BorderSide(color: AppColor.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // Summary + Search
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DeskSummaryCard(
                label: 'Total',
                value: '${state.summary.totalProducts}',
                icon: Icons.inventory_2_outlined,
                color: AppColor.primary,
              ),
              const SizedBox(width: 10),
              _DeskSummaryCard(
                label: 'In Stock',
                value: '${state.summary.inStock}',
                icon: Icons.check_circle_outline_rounded,
                color: AppColor.success,
                selected: state.stockFilter == StockStatus.inStock,
                onTap: () => notifier.setStockFilter(
                    state.stockFilter == StockStatus.inStock ? null : StockStatus.inStock),
              ),
              const SizedBox(width: 10),
              _DeskSummaryCard(
                label: 'Low Stock',
                value: '${state.summary.lowStock}',
                icon: Icons.warning_amber_rounded,
                color: AppColor.warning,
                selected: state.stockFilter == StockStatus.lowStock,
                onTap: () => notifier.setStockFilter(
                    state.stockFilter == StockStatus.lowStock ? null : StockStatus.lowStock),
              ),
              const SizedBox(width: 10),
              _DeskSummaryCard(
                label: 'Out of Stock',
                value: '${state.summary.outOfStock}',
                icon: Icons.remove_circle_outline_rounded,
                color: AppColor.error,
                selected: state.stockFilter == StockStatus.outOfStock,
                onTap: () => notifier.setStockFilter(
                    state.stockFilter == StockStatus.outOfStock ? null : StockStatus.outOfStock),
              ),
              const SizedBox(width: 10),
              _DeskSummaryCard(
                label: 'Diet Product',
                value: '${state.summary.deadStock}',
                icon: Icons.local_fire_department_outlined,
                color: const Color(0xFF8B5CF6),
                selected: state.deadStockOnly,
                onTap: notifier.toggleDeadStockOnly,
              ),
              const SizedBox(width: 16),
              const SizedBox(height: 48, width: 1, child: VerticalDivider(width: 1, color: Color(0xFFEEEEEE))),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: notifier.search,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Product name, SKU or barcode...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColor.primary),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColor.textHint),
                        onPressed: () {
                          searchCtrl.clear();
                          notifier.search('');
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: AppColor.grey100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColor.grey200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Category dropdown
              AppSearchableDropdown<String?>(
                items: _categoryDropdownItems(state.categories),
                value: state.categoryFilter,
                hint: 'Category',
                prefixIcon: Icons.category_outlined,
                desktopWidth: 220,
                onChanged: notifier.setCategoryFilter,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // Values row — hamesha filtered list se
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 14),
          child: _ValuesRow(
            items: state.filtered,
            stockFilter: state.stockFilter,
            deadStockOnly: state.deadStockOnly,
            categoryFilter: state.categoryFilter,
            fmtAmt: fmtAmt,
            fmtQty: fmtQty,
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),

        // Table
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.filtered.isEmpty
              ? const _EmptyState()
              : _InventoryTable(items: state.filtered, fmtAmt: fmtAmt, fmtQty: fmtQty),
        ),
      ],
    );
  }
}

class _DeskSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _DeskSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.1) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? color.withOpacity(0.4) : const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _InventoryTable extends StatelessWidget {
  final List<AccountantBranchInventoryModel> items;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;

  const _InventoryTable({required this.items, required this.fmtAmt, required this.fmtQty});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Row(children: [
            const SizedBox(width: 10),
            _TH(label: '#', flex: 1),
            _TH(label: 'Product', flex: 4),
            _TH(label: 'Category', flex: 2),
            _TH(label: 'SKU', flex: 3),
            _TH(label: 'Unit', flex: 2),
            _TH(label: 'Stock', flex: 2, center: true),
            _TH(label: 'Min / Max', flex: 3, center: true),
            _TH(label: 'Purchase Price', flex: 3, right: true),
            _TH(label: 'Sale Price', flex: 3, right: true),
            _TH(label: 'Wholesale', flex: 3, right: true),
            _TH(label: 'Status', flex: 3, center: true),
          ]),
        ),
        Container(height: 1, color: const Color(0xFFEEEEEE)),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (_, i) => _TableRow(index: i + 1, item: items[i], fmtAmt: fmtAmt, fmtQty: fmtQty),
          ),
        ),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  final bool right;
  final bool center;

  const _TH({required this.label, this.flex = 1, this.right = false, this.center = false});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      label,
      textAlign: right ? TextAlign.right : center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.textHint, letterSpacing: 0.3),
    ),
  );
}

class _TableRow extends StatelessWidget {
  final int index;
  final AccountantBranchInventoryModel item;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;

  const _TableRow({required this.index, required this.item, required this.fmtAmt, required this.fmtQty});

  Color get _statusColor {
    switch (item.stockStatus) {
      case StockStatus.inStock: return AppColor.success;
      case StockStatus.lowStock: return AppColor.warning;
      case StockStatus.outOfStock: return AppColor.error;
    }
  }

  String get _statusLabel {
    switch (item.stockStatus) {
      case StockStatus.inStock: return 'In Stock';
      case StockStatus.lowStock: return 'Low Stock';
      case StockStatus.outOfStock: return 'Out of Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text('$index', style: const TextStyle(fontSize: 12, color: AppColor.textHint)),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (item.isDeadStock) ...[
                  const Icon(Icons.local_fire_department_outlined, size: 13, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(item.productName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1D23)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(item.categoryName,
                style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(flex: 3, child: Text(item.sku, style: const TextStyle(fontSize: 12, color: AppColor.textSecondary))),
          Expanded(flex: 2, child: Text(item.unit, style: const TextStyle(fontSize: 12, color: AppColor.textSecondary))),
          Expanded(
            flex: 2,
            child: Text(fmtQty(item.stock),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _statusColor)),
          ),
          Expanded(
            flex: 3,
            child: Text('${fmtQty(item.minStock)} / ${fmtQty(item.maxStock)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
          ),
          Expanded(
            flex: 3,
            child: Text(fmtAmt(item.purchasePrice),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6))),
          ),
          Expanded(
            flex: 3,
            child: Text(fmtAmt(item.salePrice),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.primary)),
          ),
          Expanded(
            flex: 3,
            child: Text(fmtAmt(item.wholesalePrice),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9))),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(_statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE LAYOUT
// ══════════════════════════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final AccountantBranchInventoryState state;
  final dynamic notifier;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;
  final TextEditingController searchCtrl;

  const _MobileLayout({
    required this.state,
    required this.notifier,
    required this.fmtAmt,
    required this.fmtQty,
    required this.searchCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Inventory Report',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23))),
        actions: [
          IconButton(
            onPressed: () => _exportPdf(context, state),
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColor.primary),
            tooltip: 'Export PDF',
          ),
          IconButton(
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh_rounded, color: AppColor.textSecondary),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: searchCtrl,
              onChanged: notifier.search,
              style: const TextStyle(fontSize: 14),
              cursorHeight: 16,
              decoration: InputDecoration(
                hintText: 'Product name, SKU or barcode...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColor.primary),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColor.textHint),
                  onPressed: () {
                    searchCtrl.clear();
                    notifier.search('');
                  },
                )
                    : null,
                filled: true,
                fillColor: AppColor.grey100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColor.grey200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColor.primary, width: 1.5)),
              ),
            ),
          ),

          // Category dropdown
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: AppSearchableDropdown<String?>(
              items: _categoryDropdownItems(state.categories),
              value: state.categoryFilter,
              hint: 'Category',
              prefixIcon: Icons.category_outlined,
              fullWidth: true,
              onChanged: notifier.setCategoryFilter,
            ),
          ),

          // Filter Chips (Stock status)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'All', selected: state.stockFilter == null, color: AppColor.primary, onTap: () => notifier.setStockFilter(null)),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'In Stock',
                    selected: state.stockFilter == StockStatus.inStock,
                    color: AppColor.success,
                    onTap: () => notifier.setStockFilter(state.stockFilter == StockStatus.inStock ? null : StockStatus.inStock),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Low Stock',
                    selected: state.stockFilter == StockStatus.lowStock,
                    color: AppColor.warning,
                    onTap: () => notifier.setStockFilter(state.stockFilter == StockStatus.lowStock ? null : StockStatus.lowStock),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Out of Stock',
                    selected: state.stockFilter == StockStatus.outOfStock,
                    color: AppColor.error,
                    onTap: () => notifier.setStockFilter(state.stockFilter == StockStatus.outOfStock ? null : StockStatus.outOfStock),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Diet Product',
                    selected: state.deadStockOnly,
                    color: const Color(0xFF8B5CF6),
                    onTap: notifier.toggleDeadStockOnly,
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFFE5E7EB)),

          // Summary Cards
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  SizedBox(
                    width: 90,
                    child: _MobileSummaryCard(label: 'Total', value: '${state.summary.totalProducts}', icon: Icons.inventory_2_outlined, color: AppColor.primary),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: _MobileSummaryCard(
                      label: 'In Stock',
                      value: '${state.summary.inStock}',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColor.success,
                      selected: state.stockFilter == StockStatus.inStock,
                      onTap: () => notifier.setStockFilter(state.stockFilter == StockStatus.inStock ? null : StockStatus.inStock),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: _MobileSummaryCard(
                      label: 'Low',
                      value: '${state.summary.lowStock}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColor.warning,
                      selected: state.stockFilter == StockStatus.lowStock,
                      onTap: () => notifier.setStockFilter(state.stockFilter == StockStatus.lowStock ? null : StockStatus.lowStock),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: _MobileSummaryCard(
                      label: 'Out',
                      value: '${state.summary.outOfStock}',
                      icon: Icons.remove_circle_outline_rounded,
                      color: AppColor.error,
                      selected: state.stockFilter == StockStatus.outOfStock,
                      onTap: () => notifier.setStockFilter(state.stockFilter == StockStatus.outOfStock ? null : StockStatus.outOfStock),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: _MobileSummaryCard(
                      label: 'Diet Product',
                      value: '${state.summary.deadStock}',
                      icon: Icons.local_fire_department_outlined,
                      color: const Color(0xFF8B5CF6),
                      selected: state.deadStockOnly,
                      onTap: notifier.toggleDeadStockOnly,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Values Row — hamesha filtered list se
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: _ValuesRow(
              items: state.filtered,
              stockFilter: state.stockFilter,
              deadStockOnly: state.deadStockOnly,
              categoryFilter: state.categoryFilter,
              fmtAmt: fmtAmt,
              fmtQty: fmtQty,
            ),
          ),
          Container(height: 6, color: const Color(0xFFF5F6FA)),

          if (!state.isLoading && state.filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(children: [
                Text('${state.filtered.length} products',
                    style: const TextStyle(fontSize: 12, color: AppColor.textHint)),
              ]),
            ),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filtered.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: state.filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _InventoryCard(item: state.filtered[i], fmtAmt: fmtAmt, fmtQty: fmtQty),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _MobileSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? color.withOpacity(0.4) : color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(height: 7),
          Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColor.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Values Row (shared)
// ══════════════════════════════════════════════════════════════════════════════
class _ValuesRow extends StatelessWidget {
  final List<AccountantBranchInventoryModel> items;
  final StockStatus? stockFilter;
  final bool deadStockOnly;
  final String? categoryFilter;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;

  const _ValuesRow({
    required this.items,
    required this.stockFilter,
    required this.deadStockOnly,
    required this.categoryFilter,
    required this.fmtAmt,
    required this.fmtQty,
  });

  @override
  Widget build(BuildContext context) {
    final qty      = items.fold<double>(0, (s, i) => s + i.stock);
    final saleVal  = items.fold<double>(0, (s, i) => s + (i.stock * i.salePrice));
    final purchaseVal = items.fold<double>(0, (s, i) => s + (i.stock * i.purchasePrice));

    final Color accentColor;
    final String qtyLabel;

    if (deadStockOnly) {
      accentColor = const Color(0xFF8B5CF6);
      qtyLabel = 'Diet Product Qty';
    } else {
      switch (stockFilter) {
        case StockStatus.inStock:
          accentColor = AppColor.success;
          qtyLabel = 'In Stock Qty';
          break;
        case StockStatus.lowStock:
          accentColor = AppColor.warning;
          qtyLabel = 'Low Stock Qty';
          break;
        case StockStatus.outOfStock:
          accentColor = AppColor.error;
          qtyLabel = 'Out of Stock Qty';
          break;
        default:
          accentColor = AppColor.primary;
          qtyLabel = categoryFilter != null ? 'Category Qty' : 'Total Qty';
      }
    }

    return Row(children: [
      Expanded(child: _ValueCard(label: qtyLabel, value: fmtQty(qty), icon: Icons.straighten_rounded, color: accentColor)),
      const SizedBox(width: 8),
      Expanded(child: _ValueCard(label: 'Purchase Value', value: fmtAmt(purchaseVal), icon: Icons.shopping_cart_outlined, color: const Color(0xFF8B5CF6))),
      const SizedBox(width: 8),
      Expanded(child: _ValueCard(label: 'Sale Value', value: fmtAmt(saleVal), icon: Icons.sell_outlined, color: AppColor.primary)),
    ]);
  }
}

class _ValueCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _ValueCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColor.textHint)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Inventory Card (Mobile)
// ══════════════════════════════════════════════════════════════════════════════
class _InventoryCard extends StatelessWidget {
  final AccountantBranchInventoryModel item;
  final String Function(double) fmtAmt;
  final String Function(double) fmtQty;

  const _InventoryCard({required this.item, required this.fmtAmt, required this.fmtQty});

  Color get _statusColor {
    switch (item.stockStatus) {
      case StockStatus.inStock: return AppColor.success;
      case StockStatus.lowStock: return AppColor.warning;
      case StockStatus.outOfStock: return AppColor.error;
    }
  }

  String get _statusLabel {
    switch (item.stockStatus) {
      case StockStatus.inStock: return 'In Stock';
      case StockStatus.lowStock: return 'Low Stock';
      case StockStatus.outOfStock: return 'Out of Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_statusColor.withOpacity(0.15), _statusColor.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: _statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.isDeadStock) ...[
                            const Icon(Icons.local_fire_department_outlined, size: 13, color: Color(0xFF8B5CF6)),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(item.productName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1D23)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.tag_rounded, size: 11, color: AppColor.textHint),
                        const SizedBox(width: 2),
                        Text(item.sku, style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
                        const SizedBox(width: 8),
                        const Icon(Icons.straighten_rounded, size: 11, color: AppColor.textHint),
                        const SizedBox(width: 2),
                        Text(item.unit, style: const TextStyle(fontSize: 11, color: AppColor.textHint)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.category_outlined, size: 11, color: AppColor.textHint),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(item.categoryName,
                              style: const TextStyle(fontSize: 11, color: AppColor.textHint),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(_statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers_outlined, size: 13, color: _statusColor),
                      const SizedBox(width: 5),
                      Text('${fmtQty(item.stock)} ${item.unit}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (item.isDeadStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: const Text('No sale today',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6))),
                  ),
                const Spacer(),
                if (item.minStock > 0 || item.maxStock > 0)
                  Text('Min ${fmtQty(item.minStock)}  ·  Max ${fmtQty(item.maxStock)}',
                      style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(10)),
            child: IntrinsicHeight(
              child: Row(children: [
                Expanded(child: _PriceTile(icon: Icons.shopping_cart_outlined, label: 'Purchase', value: fmtAmt(item.purchasePrice), color: const Color(0xFF8B5CF6))),
                VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade200),
                Expanded(child: _PriceTile(icon: Icons.sell_outlined, label: 'Sale', value: fmtAmt(item.salePrice), color: AppColor.primary)),
                VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade200),
                Expanded(child: _PriceTile(icon: Icons.storefront_outlined, label: 'Wholesale', value: fmtAmt(item.wholesalePrice), color: const Color(0xFF0EA5E9))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _PriceTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(height: 5),
      Text(value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: AppColor.textHint)),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? color : AppColor.grey200, width: 1.5),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColor.textSecondary)),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No product found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text('Try a different search or clear filters',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}