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

    ref.listen<AccountantBranchInventoryState>(accountantBranchInventoryProvider(widget.branchId), (_, next) {
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

          // ── Search + Filter ───────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(children: [

              // Search
              TextField(
                controller:  _searchCtrl,
                onChanged:   notifier.search,
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

              // Stock Filter Chips
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
                          StockStatus.inStock),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label:    'Low Stock',
                      selected: state.stockFilter == StockStatus.lowStock,
                      color:    AppColor.warning,
                      onTap:    () => notifier.setStockFilter(
                          StockStatus.lowStock),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label:    'Out of Stock',
                      selected: state.stockFilter == StockStatus.outOfStock,
                      color:    AppColor.error,
                      onTap:    () => notifier.setStockFilter(
                          StockStatus.outOfStock),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          // ── Summary Cards ─────────────────────────────────
          Container(
            color:   Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              _SummaryTile(
                label: 'Total',
                value: '${state.summary.totalProducts}',
                icon:  Icons.inventory_2_outlined,
                color: AppColor.primary,
              ),
              _vDivider(),
              _SummaryTile(
                label: 'In Stock',
                value: '${state.summary.inStock}',
                icon:  Icons.check_circle_outline_rounded,
                color: AppColor.success,
              ),
              _vDivider(),
              _SummaryTile(
                label: 'Low',
                value: '${state.summary.lowStock}',
                icon:  Icons.warning_amber_rounded,
                color: AppColor.warning,
              ),
              _vDivider(),
              _SummaryTile(
                label: 'Out',
                value: '${state.summary.outOfStock}',
                icon:  Icons.remove_circle_outline_rounded,
                color: AppColor.error,
              ),
              _vDivider(),
              _SummaryTile(
                label: 'Value',
                value: _fmtAmt(state.summary.totalStockValue),
                icon:  Icons.account_balance_wallet_outlined,
                color: const Color(0xFF8B5CF6),
                small: true,
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

          // ── List ──────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filtered.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: notifier.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 24),
                itemCount: state.filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (_, i) => _InventoryCard(
                  item:    state.filtered[i],
                  fmtAmt:  _fmtAmt,
                  fmtQty:  _fmtQty,
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

// ═══════════════════════════════════════════════════════════
//  Inventory Card
// ═══════════════════════════════════════════════════════════

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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Name + Stock Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF1A1D23),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w700,
                          color:      _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // SKU + Unit
                Row(children: [
                  const Icon(Icons.tag_rounded,
                      size: 12, color: AppColor.textHint),
                  const SizedBox(width: 3),
                  Text(item.sku,
                      style: const TextStyle(
                          fontSize: 11,
                          color:    AppColor.textHint)),
                  const SizedBox(width: 10),
                  const Icon(Icons.straighten_rounded,
                      size: 12, color: AppColor.textHint),
                  const SizedBox(width: 3),
                  Text(item.unit,
                      style: const TextStyle(
                          fontSize: 11,
                          color:    AppColor.textHint)),
                ]),
                const SizedBox(height: 5),

                // Stock + Prices
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Stock qty
                    Row(children: [
                      Text(
                        'Stock: ',
                        style: const TextStyle(
                            fontSize: 11,
                            color:    AppColor.textSecondary),
                      ),
                      Text(
                        '${fmtQty(item.stock)} ${item.unit}',
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color:      _statusColor,
                        ),
                      ),
                    ]),

                    // Sale price
                    Text(
                      fmtAmt(item.salePrice),
                      style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w800,
                        color:      AppColor.primary,
                      ),
                    ),
                  ],
                ),

                // Min/Max stock
                if (item.minStock > 0 || item.maxStock > 0) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(
                      'Min: ${fmtQty(item.minStock)}  •  Max: ${fmtQty(item.maxStock)}',
                      style: const TextStyle(
                          fontSize: 10,
                          color:    AppColor.textHint),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Shared Widgets
// ═══════════════════════════════════════════════════════════

class _SummaryTile extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  final bool     small;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
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
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7),
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