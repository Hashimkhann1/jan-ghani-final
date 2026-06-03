import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/color/app_color.dart';
import '../../data/model/accountant_branch_stock_inventory_model.dart';
import '../provider/accountant_branch_stock_inventory_provider.dart';

class AccountantBranchInventoryReportScreen extends ConsumerStatefulWidget {
  const AccountantBranchInventoryReportScreen({
    super.key,
    required this.branchId,
  });
  final String branchId;

  @override
  ConsumerState<AccountantBranchInventoryReportScreen> createState() =>
      _AccountantBranchInventoryReportScreenState();
}

class _AccountantBranchInventoryReportScreenState
    extends ConsumerState<AccountantBranchInventoryReportScreen> {
  final _searchCtrl = TextEditingController();
  final _amtFmt     = NumberFormat('#,##,###', 'en_IN');

  String _fmtAmt(double v) => 'Rs ${_amtFmt.format(v.toInt())}';
  String _fmtQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(2);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(accountantBranchInventoryProvider(widget.branchId));
    final notifier = ref.read(accountantBranchInventoryProvider(widget.branchId).notifier);

    ref.listen<AccountantBranchInventoryState>(
      accountantBranchInventoryProvider(widget.branchId),
          (_, next) {
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
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor:  Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Inventory Report',
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w700,
            color:      Color(0xFF1A1D23),
          ),
        ),
        actions: [
          IconButton(
            onPressed: notifier.load,
            icon:    const Icon(Icons.refresh_rounded,
                color: AppColor.textSecondary),
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

          // ── Search + Filter Chips ─────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(children: [

              // Search
              TextField(
                controller:   _searchCtrl,
                onChanged:    notifier.search,
                style: const TextStyle(fontSize: 14),
                cursorHeight: 16,
                decoration: InputDecoration(
                  hintText: 'Product name, SKU ya barcode...',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColor.textHint),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColor.primary),
                  suffixIcon: state.searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        size: 18, color: AppColor.textHint),
                    onPressed: () {
                      _searchCtrl.clear();
                      notifier.search('');
                    },
                  )
                      : null,
                  filled:    true,
                  fillColor: AppColor.grey100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: AppColor.grey200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColor.primary, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Filter Chips
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label:    'All',
                      selected: state.stockFilter == null,
                      color:    AppColor.primary,
                      onTap:    () => notifier.setStockFilter(null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label:    'In Stock',
                      selected: state.stockFilter == StockStatus.inStock,
                      color:    AppColor.success,
                      onTap:    () => notifier.setStockFilter(
                          state.stockFilter == StockStatus.inStock
                              ? null
                              : StockStatus.inStock),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label:    'Low Stock',
                      selected: state.stockFilter == StockStatus.lowStock,
                      color:    AppColor.warning,
                      onTap:    () => notifier.setStockFilter(
                          state.stockFilter == StockStatus.lowStock
                              ? null
                              : StockStatus.lowStock),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label:    'Out of Stock',
                      selected: state.stockFilter == StockStatus.outOfStock,
                      color:    AppColor.error,
                      onTap:    () => notifier.setStockFilter(
                          state.stockFilter == StockStatus.outOfStock
                              ? null
                              : StockStatus.outOfStock),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          // ── Summary Section ───────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(children: [

              // Row 1: Count tiles (tappable)
              Row(children: [
                _SummaryTile(
                  label: 'Total',
                  value: '${state.summary.totalProducts}',
                  icon:  Icons.inventory_2_outlined,
                  color: AppColor.primary,
                ),
                _vDivider(),
                _SummaryTile(
                  label:    'In Stock',
                  value:    '${state.summary.inStock}',
                  icon:     Icons.check_circle_outline_rounded,
                  color:    AppColor.success,
                  selected: state.stockFilter == StockStatus.inStock,
                  onTap:    () => notifier.setStockFilter(
                      state.stockFilter == StockStatus.inStock
                          ? null
                          : StockStatus.inStock),
                ),
                _vDivider(),
                _SummaryTile(
                  label:    'Low',
                  value:    '${state.summary.lowStock}',
                  icon:     Icons.warning_amber_rounded,
                  color:    AppColor.warning,
                  selected: state.stockFilter == StockStatus.lowStock,
                  onTap:    () => notifier.setStockFilter(
                      state.stockFilter == StockStatus.lowStock
                          ? null
                          : StockStatus.lowStock),
                ),
                _vDivider(),
                _SummaryTile(
                  label:    'Out',
                  value:    '${state.summary.outOfStock}',
                  icon:     Icons.remove_circle_outline_rounded,
                  color:    AppColor.error,
                  selected: state.stockFilter == StockStatus.outOfStock,
                  onTap:    () => notifier.setStockFilter(
                      state.stockFilter == StockStatus.outOfStock
                          ? null
                          : StockStatus.outOfStock),
                ),
              ]),

              const SizedBox(height: 10),
              Container(height: 1, color: const Color(0xFFE5E7EB)),
              const SizedBox(height: 10),

              // Row 2: Value cards (filter ke hisaab se)
              _ValuesRow(
                summary: state.summary,
                filter:  state.stockFilter,
                fmtAmt:  _fmtAmt,
                fmtQty:  _fmtQty,
              ),
            ]),
          ),

          Container(height: 1, color: const Color(0xFFE5E7EB)),

          // Result count
          if (!state.isLoading && state.filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(children: [
                Text(
                  '${state.filtered.length} product mila',
                  style: const TextStyle(
                      fontSize: 12, color: AppColor.textHint),
                ),
              ]),
            )
          else
            const SizedBox(height: 8),

          // ── Product List ──────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filtered.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount:       state.filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _InventoryCard(
                  item:   state.filtered[i],
                  fmtAmt: _fmtAmt,
                  fmtQty: _fmtQty,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
    width:  1,
    height: 40,
    color:  const Color(0xFFE5E7EB),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ── Values Row ─────────────────────────────────────────────
class _ValuesRow extends StatelessWidget {
  final AccountantBranchInventorySummary summary;
  final StockStatus?                     filter;
  final String Function(double)          fmtAmt;
  final String Function(double)          fmtQty;

  const _ValuesRow({
    required this.summary,
    required this.filter,
    required this.fmtAmt,
    required this.fmtQty,
  });

  @override
  Widget build(BuildContext context) {
    final String qtyLabel;
    final double qty;
    final double saleVal;
    final double purchaseVal;
    final Color  accentColor;

    switch (filter) {
      case StockStatus.inStock:
        qtyLabel    = 'In Stock Qty';
        qty         = summary.inStockQty;
        saleVal     = summary.inStockSaleValue;
        purchaseVal = summary.inStockPurchaseValue;
        accentColor = AppColor.success;
        break;
      case StockStatus.lowStock:
        qtyLabel    = 'Low Stock Qty';
        qty         = summary.lowStockQty;
        saleVal     = summary.lowStockSaleValue;
        purchaseVal = summary.lowStockPurchaseValue;
        accentColor = AppColor.warning;
        break;
      case StockStatus.outOfStock:
        qtyLabel    = 'Out Qty';
        qty         = summary.outStockQty;
        saleVal     = summary.outStockSaleValue;
        purchaseVal = summary.outStockPurchaseValue;
        accentColor = AppColor.error;
        break;
      default:
        qtyLabel    = 'Total Qty';
        qty         = summary.inStockQty +
            summary.lowStockQty +
            summary.outStockQty;
        saleVal     = summary.totalSaleValue;
        purchaseVal = summary.totalPurchaseValue;
        accentColor = AppColor.primary;
    }

    return Row(children: [
      Expanded(
        child: _ValueCard(
          label: qtyLabel,
          value: fmtQty(qty),
          icon:  Icons.straighten_rounded,
          color: accentColor,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ValueCard(
          label: 'Purchase Value',
          value: fmtAmt(purchaseVal),
          icon:  Icons.shopping_cart_outlined,
          color: const Color(0xFF8B5CF6),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ValueCard(
          label: 'Sale Value',
          value: fmtAmt(saleVal),
          icon:  Icons.sell_outlined,
          color: AppColor.primary,
        ),
      ),
    ]);
  }
}

class _ValueCard extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final Color    color;

  const _ValueCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w800,
                color:      color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: AppColor.textHint)),
      ],
    ),
  );
}

// ── Inventory Card ─────────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  final AccountantBranchInventoryModel item;
  final String Function(double)        fmtAmt;
  final String Function(double)        fmtQty;

  const _InventoryCard({
    required this.item,
    required this.fmtAmt,
    required this.fmtQty,
  });

  Color get _statusColor {
    switch (item.stockStatus) {
      case StockStatus.inStock:    return AppColor.success;
      case StockStatus.lowStock:   return AppColor.warning;
      case StockStatus.outOfStock: return AppColor.error;
    }
  }

  String get _statusLabel {
    switch (item.stockStatus) {
      case StockStatus.inStock:    return 'In Stock';
      case StockStatus.lowStock:   return 'Low Stock';
      case StockStatus.outOfStock: return 'Out of Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Top Row ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [

              // Icon
              Container(
                width:  46,
                height: 46,
                decoration: BoxDecoration(
                  color:        _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    color: _statusColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Name + SKU
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                        color:      Color(0xFF1A1D23),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.tag_rounded,
                          size: 11, color: AppColor.textHint),
                      const SizedBox(width: 2),
                      Text(item.sku,
                          style: const TextStyle(
                              fontSize: 11,
                              color:    AppColor.textHint)),
                      const SizedBox(width: 8),
                      const Icon(Icons.straighten_rounded,
                          size: 11, color: AppColor.textHint),
                      const SizedBox(width: 2),
                      Text(item.unit,
                          style: const TextStyle(
                              fontSize: 11,
                              color:    AppColor.textHint)),
                    ]),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color:        _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor.withOpacity(0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color:  _statusColor,
                      shape:  BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(_statusLabel,
                      style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w700,
                          color:      _statusColor)),
                ]),
              ),
            ]),
          ),

          // ── Stock Bar ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stock qty badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        _statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.layers_outlined,
                        size: 13, color: _statusColor),
                    const SizedBox(width: 5),
                    Text(
                      '${fmtQty(item.stock)} ${item.unit}',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                        color:      _statusColor,
                      ),
                    ),
                  ]),
                ),

                // Min / Max
                if (item.minStock > 0 || item.maxStock > 0)
                  Text(
                    'Min ${fmtQty(item.minStock)}  ·  Max ${fmtQty(item.maxStock)}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColor.textHint),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Price Row ─────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color:        const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IntrinsicHeight(
              child: Row(children: [
                // Purchase
                Expanded(
                  child: _PriceTile(
                    icon:  Icons.shopping_cart_outlined,
                    label: 'Purchase',
                    value: fmtAmt(item.purchasePrice),
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                // Divider
                VerticalDivider(
                  width: 1, thickness: 1,
                  color: Colors.grey.shade200,
                ),
                // Sale
                Expanded(
                  child: _PriceTile(
                    icon:  Icons.sell_outlined,
                    label: 'Sale',
                    value: fmtAmt(item.salePrice),
                    color: AppColor.primary,
                  ),
                ),
                // Divider
                VerticalDivider(
                  width: 1, thickness: 1,
                  color: Colors.grey.shade200,
                ),
                // Wholesale
                Expanded(
                  child: _PriceTile(
                    icon:  Icons.storefront_outlined,
                    label: 'Wholesale',
                    value: fmtAmt(item.wholesalePrice),
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price Tile ─────────────────────────────────────────────
class _PriceTile extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final Color    color;

  const _PriceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(height: 5),
      Text(value,
          style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w800,
              color:      color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 9, color: AppColor.textHint)),
    ],
  );
}
// ── Shared Widgets ─────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String       label;
  final String       value;
  final IconData     icon;
  final Color        color;
  final bool         small;
  final bool         selected;
  final VoidCallback? onTap;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.small    = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color:        selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:       selected
              ? Border.all(color: color.withOpacity(0.4))
              : Border.all(color: Colors.transparent),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                fontSize:   small ? 10 : 13,
                fontWeight: FontWeight.w800,
                color:      color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColor.textHint)),
        ]),
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color:        selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : AppColor.grey200,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w600,
          color:      selected ? Colors.white : AppColor.textSecondary,
        ),
      ),
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
        Icon(Icons.inventory_2_outlined,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Koi product nahi mila',
            style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text('Search change karein ya filter hatayein',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}