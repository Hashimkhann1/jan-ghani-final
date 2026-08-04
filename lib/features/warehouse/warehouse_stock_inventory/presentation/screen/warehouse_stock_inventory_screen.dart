import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/core/widget/textfield/app_text_field.dart';
import 'package:jan_ghani_final/features/warehouse/category/data/model/category_model.dart';
import 'package:jan_ghani_final/features/warehouse/category/presentation/provider/category_provider.dart';
import 'package:jan_ghani_final/features/warehouse/company/data/model/company_model.dart';
import 'package:jan_ghani_final/features/warehouse/company/presentation/provider/company_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_stock_inventory/presentation/widget/Print_barcode_widget.dart';
import '../../data/model/product_model.dart';
import '../../presentation/provider/product_provider.dart';
import '../widget/chip_widget.dart';
import '../widget/stock_inventory_dialog.dart';
import '../widget/product_audit_dialog.dart';

class WarehouseStockInventoryScreen extends ConsumerWidget {
  const WarehouseStockInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(productProvider);
    final notifier = ref.read(productProvider.notifier);
    final products = state.filteredProducts;

    ref.listen<ProductState>(productProvider, (_, next) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation:       0,
        title: const Text(
          "Warehouse Stock Inventory",
          style: TextStyle(color: Color(0xFF1A1D23), fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: () => notifier.loadProducts(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(foregroundColor: const Color(0xFF6C7280)),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () => _showDialog(context, ref),
            icon:  const Icon(Icons.add_rounded, size: 18),
            label: const Text("Add Product"),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              backgroundColor: const Color(0xFFEEF2FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 12,
              children: [
                SummaryCard(title: "Total Products", value: "${state.totalCount}", icon: Icons.inventory_2_rounded, color: const Color(0xFF6366F1)),
                SummaryCard(title: "Active", value: "${state.activeCount}", icon: Icons.check_circle_outline_rounded, color: const Color(0xFF10B981)),
                SummaryCard(title: "Low Stock", value: "${state.lowStockCount}", icon: Icons.warning_amber_rounded, color: const Color(0xFFF59E0B)),
                SummaryCard(title: "Out of Stock", value: "${products.where((p) => p.isOutOfStock).length}", icon: Icons.remove_shopping_cart_rounded, color: const Color(0xFFEF4444)),
              ],
            ),
            16.hBox,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SearchField(
                  onChanged: notifier.onSearchChanged,
                  onClear: () => notifier.onSearchChanged(''),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Category Dropdown ────────────────────────
                    _CategoryFilterDropdown(
                      categories: ref
                          .watch(categoryProvider)
                          .allCategories
                          .where((c) => c.isActive && c.deletedAt == null)
                          .toList(),
                      selectedCategoryId: state.filterCategory,
                      onChanged: notifier.onFilterCategoryChanged,
                    ),
                    const SizedBox(width: 8),
                    // ── Company Dropdown ─────────────────────────
                    _CompanyFilterDropdown(
                      companies: ref
                          .watch(companyProvider)
                          .allCompanies
                          .where((c) => c.isActive && c.deletedAt == null)
                          .toList(),
                      selectedCompanyId: state.filterCompany,
                      onChanged: notifier.onFilterCompanyChanged,
                    ),
                    const SizedBox(width: 8),
                    // ── In Stock button (quantity > 0) ───────────
                    _StockFilterBtn(
                      label:    'In Stock',
                      icon:     Icons.inventory_2_rounded,
                      value:    'in_stock',
                      selected: state.filterStatus == 'in_stock',
                      color:    const Color(0xFF10B981),
                      onTap:    () => notifier.onFilterStatusChanged(
                          state.filterStatus == 'in_stock' ? 'all' : 'in_stock'),
                    ),
                    const SizedBox(width: 8),
                    // ── Low Stock button ─────────────────────────
                    _StockFilterBtn(
                      label:    'Low Stock',
                      icon:     Icons.warning_amber_rounded,
                      value:    'low_stock',
                      selected: state.filterStatus == 'low_stock',
                      color:    const Color(0xFFF59E0B),
                      onTap:    () => notifier.onFilterStatusChanged(
                          state.filterStatus == 'low_stock' ? 'all' : 'low_stock'),
                    ),
                    const SizedBox(width: 8),
                    // ── Out of Stock button ──────────────────────
                    _StockFilterBtn(
                      label:    'Out of Stock',
                      icon:     Icons.remove_shopping_cart_rounded,
                      value:    'out_stock',
                      selected: state.filterStatus == 'out_stock',
                      color:    const Color(0xFFEF4444),
                      onTap:    () => notifier.onFilterStatusChanged(
                          state.filterStatus == 'out_stock' ? 'all' : 'out_stock'),
                    ),
                  ],
                ),
              ],
            ),
            16.hBox,
            Expanded(
              child: products.isEmpty
                  ? _EmptyState(isSearching: state.searchQuery.isNotEmpty || state.filterStatus != 'all')
                  : _ProductTable(
                products:  products,
                onEdit:    (p) => _showDialog(context, ref, p),
                onHistory: (p) => ProductAuditDialog.show(context, p),
                onDelete:  (p) => _showDeleteDialog(context, ref, p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Table ─────────────────────────────────────────────
class _ProductTable extends StatelessWidget {
  final List<ProductModel>         products;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onHistory;
  final ValueChanged<ProductModel> onDelete;

  const _ProductTable({
    required this.products,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
  });

  static const _cols = [
    'SKU', 'Product Name', 'Category', 'Company',
    'Purchase Price', 'Sale Price', 'Stock', 'Stock Status', 'Actions'
  ];

  int _flex(String h) {
    switch (h) {
      case 'Product Name':    return 3;
      case 'Category':        return 2;
      case 'Company':         return 2;
      case 'Purchase Price':  return 2;
      case 'Sale Price':      return 2;
      case 'Stock':           return 2;
      case 'Stock Status':    return 2;
      case 'Actions':         return 1;
      default:                return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────
            Container(
              color:   const Color(0xFFF8F9FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // # column — row ke index badge ke saath align
                  const SizedBox(
                    width: 32,
                    child: Text(
                      '#',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:      12,
                        fontWeight:    FontWeight.w700,
                        color:         Color(0xFF6C7280),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  ..._cols.map((h) => Expanded(
                    flex: _flex(h),
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6C7280),
                        letterSpacing: 0.4,
                      ),
                    ),
                  )),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── Rows — ListView.builder (MAIN FIX) ──────────
            Expanded(
              child: ListView.builder(
                // ✅ Sirf visible rows build hongi (~15-20), 2000 nahi
                itemCount: products.length,
                itemExtent: 58, // ✅ Fixed height (reserved sub-label ke liye thoda zyada)
                itemBuilder: (context, index) {
                  return RepaintBoundary( // ✅ Ek row ka repaint doosri ko affect nahi karega
                    child: _ProductRow(
                      key:       ValueKey(products[index].id), // ✅ Correct diffing
                      product:   products[index],
                      isEven:    index.isEven,
                      index:     index,
                      flex:      _flex,
                      onEdit:    () => onEdit(products[index]),
                      onHistory: () => onHistory(products[index]),
                      onDelete:  () => onDelete(products[index]),
                      onPrintQR: () => PrintBarcodeWidget.show(context, products[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Row — StatelessWidget + ValueNotifier ─────────────
class _ProductRow extends StatelessWidget {
  final ProductModel         product;
  final bool                 isEven;
  final int                  index;           // 0-based — display mein +1
  final int Function(String) flex;
  final VoidCallback         onEdit;
  final VoidCallback         onHistory;
  final VoidCallback         onDelete;
  final VoidCallback         onPrintQR;

  // ✅ ValueNotifier — sirf AnimatedContainer rebuild hoga, poora Row nahi
  final _hovered = ValueNotifier<bool>(false);

  String _fmt(double v) =>
      v.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');

  _ProductRow({
    required super.key,
    required this.product,
    required this.isEven,
    required this.index,
    required this.flex,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
    required this.onPrintQR,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;

    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit:  (_) => _hovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: _hovered,
        builder: (_, hovered, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          // ✅ Sirf yeh line rebuild hoti hai hover par
          color: hovered
              ? const Color(0xFFEEF2FF)
              : isEven ? Colors.white : const Color(0xFFFAFAFC),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: child, // ✅ child rebuild nahi hoga
        ),
        // ✅ Yeh static child hai — hover par rebuild skip hoga
        child: Row(
          children: [
            // Index badge — 1, 2, 3 ...
            SizedBox(
              width: 32,
              child: Center(
                child: Container(
                  width:  24,
                  height: 24,
                  decoration: BoxDecoration(
                    color:        const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize:   10,
                        fontWeight: FontWeight.w700,
                        color:      Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 5,),

            Expanded(
              flex: flex('SKU'),
              child: Text(
                p.sku,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Color(0xFF6C7280),
                ),
              ),
            ),
            Expanded(
              flex: flex('Product Name'),
              child: Text(
                p.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D23),
                ),
              ),
            ),
            Expanded(
              flex: flex('Category'),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ChipWidget(
                    label: (p.categoryName?.length ?? 0) > 10
                        ? p.categoryName!.substring(0, 10)
                        : p.categoryName ?? '—',
                    bg:        const Color(0xFFEEF2FF),
                    textColor: const Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: flex('Company'),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ChipWidget(
                    label: (p.companyName?.length ?? 0) > 12
                        ? p.companyName!.substring(0, 12)
                        : p.companyName ?? '—',
                    bg:        const Color(0xFFF0FDF4),
                    textColor: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: flex('Purchase Price'),
              child: Text(
                'Rs. ${_fmt(p.purchasePrice)}',
                // 'Rs. ${p.purchasePrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6C7280)),
              ),
            ),
            Expanded(
              flex: flex('Sale Price'),
              child: Text(
                'Rs. ${_fmt(p.sellingPrice)}',
                // 'Rs. ${p.sellingPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            Expanded(
              flex: flex('Stock'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:  MainAxisAlignment.center,
                mainAxisSize:       MainAxisSize.min,
                children: [
                  // Physical quantity (godam ka asal maal)
                  Text(
                    '${_fmt(p.quantity)} ${p.unitOfMeasure}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      height:   1.15,
                      fontWeight: FontWeight.w600,
                      color: p.isLowStock
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF1A1D23),
                    ),
                  ),
                  // Reserved ho to available + reserved sub-label
                  if (p.reservedQty > 0)
                    Text(
                      '${_fmt(p.availableQty)} free · ${_fmt(p.reservedQty)} reserved',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 10,
                        height:   1.1,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: flex('Stock Status'),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ChipWidget(
                    label: p.isOutOfStock
                        ? 'Out of Stock'
                        : p.isLowStock ? 'Low Stock' : 'In Stock',
                    bg: p.isOutOfStock
                        ? const Color(0xFFFEE2E2)
                        : p.isLowStock
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFD1FAE5),
                    textColor: p.isOutOfStock
                        ? const Color(0xFFEF4444)
                        : p.isLowStock
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: flex('Actions'),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':    onEdit();    break;
                    case 'history': onHistory(); break;
                    case 'printQr': onPrintQR(); break;
                    case 'delete':  onDelete();  break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1)),
                      title: const Text("Edit"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'history',
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded, color: Color(0xFF10B981)),
                      title: const Text("History"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'printQr',
                    child: ListTile(
                      leading: const Icon(Icons.print, color: Color(0xFF268DF1)),
                      title: const Text("Print QR"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444)),
                      title: const Text("Delete",
                          style: TextStyle(color: Color(0xFFEF4444))),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, color: Color(0xFF6C7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

// ── Filter Chip ───────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label, value, selectedValue;
  final ValueChanged<String> onTap;
  const _FilterChip({required this.label, required this.value, required this.selectedValue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF6C7280))),
      ),
    );
  }
}

// ── Category Filter Dropdown ──────────────────────────────────
class _CategoryFilterDropdown extends StatelessWidget {
  final List<CategoryModel>   categories;
  final String                selectedCategoryId;
  final ValueChanged<String>  onChanged;

  const _CategoryFilterDropdown({
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SearchableFilterDropdown(
      allLabel:    'All Categories',
      items:       categories.map((c) => (id: c.id, name: c.name)).toList(),
      selectedId:  selectedCategoryId,
      onChanged:   onChanged,
      activeColor: const Color(0xFF6366F1),
      clearBg:     const Color(0xFFEEF2FF),
    );
  }
}

// ── Company Filter Dropdown (Category filter ka mirror) ──────
class _CompanyFilterDropdown extends StatelessWidget {
  final List<CompanyModel>   companies;
  final String               selectedCompanyId;
  final ValueChanged<String> onChanged;

  const _CompanyFilterDropdown({
    required this.companies,
    required this.selectedCompanyId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SearchableFilterDropdown(
      allLabel:    'All Companies',
      items:       companies.map((c) => (id: c.id, name: c.name)).toList(),
      selectedId:  selectedCompanyId,
      onChanged:   onChanged,
      activeColor: const Color(0xFF16A34A),
      clearBg:     const Color(0xFFF0FDF4),
    );
  }
}

// ── Searchable Filter Dropdown (Category + Company shared) ─────
// Tap par anchored menu: autofocus search field + filtered list.
// Package-free (showMenu). Closed field ka look purane dropdown jaisa.
class _SearchableFilterDropdown extends StatefulWidget {
  final String                            allLabel;   // "All Categories"/"All Companies"
  final List<({String id, String name})>  items;
  final String                            selectedId; // 'all' ya id
  final ValueChanged<String>              onChanged;
  final Color                             activeColor; // filtered border/check
  final Color                             clearBg;

  const _SearchableFilterDropdown({
    required this.allLabel,
    required this.items,
    required this.selectedId,
    required this.onChanged,
    required this.activeColor,
    required this.clearBg,
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
        : widget.allLabel;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Closed field (tap → searchable menu) ──
        InkWell(
          onTap: _openMenu,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            key: _fieldKey,
            height: 46,
            width: 175,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFiltered ? widget.activeColor : const Color(0xFF5BDD5B),
                width: 1.3,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isFiltered
                          ? const Color(0xFF1A1D23)
                          : const Color(0xFF717275),
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Color(0xFF6C7280)),
              ],
            ),
          ),
        ),

        // ── Clear button — sirf filtered hone par ──
        if (isFiltered) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: 'All products show karo',
            child: InkWell(
              onTap: () => widget.onChanged('all'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: widget.clearBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.activeColor.withOpacity(0.3)),
                ),
                child: Icon(Icons.close_rounded,
                    size: 16, color: widget.activeColor),
              ),
            ),
          ),
        ],
      ],
    );
  }
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

// ── Search Field ──────────────────────────────────────────────
class _SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback         onClear;

  const _SearchField({
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _ctrl      = TextEditingController();
  final _hasText   = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _ctrl.dispose();
    _hasText.dispose();
    super.dispose();
  }

  void _clear() {
    _ctrl.clear();
    _hasText.value = false;
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 46,
      child: TextFormField(
        controller: _ctrl,
        onChanged: (v) {
          widget.onChanged(v);
          _hasText.value = v.isNotEmpty;
        },
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1D23)),
        decoration: InputDecoration(
          hintText: "Search by name, SKU, barcode...",
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: Color(0xFF9CA3AF)),
          // ── Sirf suffix icon rebuild hoga, poora widget nahi ──
          suffixIcon: ValueListenableBuilder<bool>(
            valueListenable: _hasText,
            builder: (_, has, __) => has
                ? GestureDetector(
              onTap: _clear,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: AppColor.white),
                ),
              ),
            )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF6366F1), width: 1.5)),
        ),
      ),
    );
  }
}

// ── Stock Filter Button ───────────────────────────────────────
class _StockFilterBtn extends StatelessWidget {
  final String   label;
  final IconData icon;
  final String   value;
  final bool     selected;
  final Color    color;
  final VoidCallback onTap;

  const _StockFilterBtn({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? 'Clear filter' : label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size:  16,
                  color: selected ? color : const Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : const Color(0xFF6C7280),
                ),
              ),
              // ── X badge jab selected ho ───────────────
              if (selected) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 10, color: Colors.white),
                ),
              ],
            ],
          ),
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
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(isSearching ? Icons.search_off_rounded : Icons.inventory_2_outlined, size: 56, color: const Color(0xFFD1D5DB)),
        const SizedBox(height: 12),
        Text(isSearching ? 'Koi product nahi mila' : 'Abhi tak koi product nahi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6C7280))),
        const SizedBox(height: 4),
        Text(isSearching ? 'Search change karein' : 'Add Product button se product add karein', style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
      ]),
    );
  }
}