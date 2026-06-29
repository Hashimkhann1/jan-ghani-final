import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../data/model/accountant_inventory_model.dart';
import '../provider/accountant_inventory_provider.dart';

// =============================================================
// Accountant → Warehouse Inventory (read-only)
// Har product: total quantity, purchase & sale price, min/max
// =============================================================
class AccountantWarehouseInventoryScreen extends ConsumerStatefulWidget {
  final String warehouseId;
  const AccountantWarehouseInventoryScreen({
    super.key,
    required this.warehouseId,
  });

  @override
  ConsumerState<AccountantWarehouseInventoryScreen> createState() =>
      _AccountantWarehouseInventoryScreenState();
}

class _AccountantWarehouseInventoryScreenState
    extends ConsumerState<AccountantWarehouseInventoryScreen> {
  String _query = '';
  bool _searchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // Stock filter — default 'in' (In Stock)
  String _stockFilter = 'in'; // all | in | out | low

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searchOpen = true);

  void _closeSearch() => setState(() {
        _searchOpen = false;
        _searchCtrl.clear();
        _query = '';
      });

  // Stock buckets (mutually exclusive)
  //   in  → quantity > minStockLevel       (healthy)
  //   low → 0 < quantity <= minStockLevel   (reorder)
  //   out → quantity <= 0                    (khatam)
  bool _matchesStock(AccountantInventoryModel p) {
    switch (_stockFilter) {
      case 'in':  return p.quantity > p.minStockLevel;
      case 'low': return p.quantity > 0 && p.quantity <= p.minStockLevel;
      case 'out': return p.quantity <= 0;
      default:    return true; // all
    }
  }

  Widget _chip(String label, String value) {
    final selected = _stockFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _stockFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColor.primary : AppColor.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColor.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(accInventoryProvider(widget.warehouseId));

    // Total inventory value — poori inventory (filter/search se independent)
    final allItems = inventoryAsync.value ?? const <AccountantInventoryModel>[];
    final totalInventoryValue =
        allItems.fold<double>(0, (s, p) => s + p.stockValue);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textDark),
        // Search open ho to back arrow search band kare (route pop nahi)
        leading: _searchOpen
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _closeSearch,
              )
            : null,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _searchOpen
              ? TextField(
                  key: const ValueKey('search'),
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  style: const TextStyle(
                      fontSize: 15, color: AppColor.textDark),
                  decoration: const InputDecoration(
                    hintText: 'Product dhoondein...',
                    hintStyle: TextStyle(color: AppColor.textMuted),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                )
              : const Text(
                  'Warehouse Inventory',
                  key: ValueKey('title'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textDark,
                  ),
                ),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _searchOpen ? Icons.close_rounded : Icons.search_rounded),
            onPressed: _searchOpen ? _closeSearch : _openSearch,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Total Inventory Value (poori inventory) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset:     const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width:  44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:        const Color(0xFFE9FBF2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2_rounded,
                          color: AppColor.cashIn, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Inventory Value',
                            style: TextStyle(
                                fontSize: 12, color: AppColor.textMuted),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _fmtRs(totalInventoryValue),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:        AppColor.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${allItems.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stock filter chips (default: In Stock) ──
            // (Search ab AppBar mein expandable hai)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All', 'all'),
                    _chip('In Stock', 'in'),
                    _chip('Out of Stock', 'out'),
                    _chip('Low Stock', 'low'),
                  ],
                ),
              ),
            ),

            // ── List ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColor.primary,
                onRefresh: () async =>
                    ref.invalidate(accInventoryProvider(widget.warehouseId)),
                child: inventoryAsync.when(
                  data: (all) {
                    // Pehle stock filter, phir search query
                    final list = all.where((p) {
                      if (!_matchesStock(p)) return false;
                      if (_query.isEmpty) return true;
                      return p.name.toLowerCase().contains(_query) ||
                          (p.sku ?? '').toLowerCase().contains(_query);
                    }).toList();

                    if (list.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Koi product nahi mila',
                              style: TextStyle(color: AppColor.textMuted),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _InventoryCard(item: list[i]),
                    );
                  },
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 7,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _ShimmerBox(height: 120),
                    ),
                  ),
                  error: (e, _) => ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Inventory load nahi hui — pull to refresh',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inventory Card ────────────────────────────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  final AccountantInventoryModel item;
  const _InventoryCard({required this.item});

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }

  String _qty(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          // ── Collapsed: sirf name + sku ────────────────────
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE9FBF2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_rounded,
                color: AppColor.cashIn, size: 20),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: MediaQuery.of(context).size.width < 600 ? 13 : 15,
              color: AppColor.textDark,
            ),
          ),
          subtitle: item.sku?.isNotEmpty == true
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    item.sku!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textMuted),
                  ),
                )
              : null,
          // ── Collapsed: stock badge ────────────────────────
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: item.isLowStock
                  ? const Color(0xFFFEF2F2)
                  : AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_qty(item.quantity)} ${item.unitOfMeasure}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: item.isLowStock
                        ? AppColor.cashOut
                        : AppColor.primary,
                  ),
                ),
                const Text(
                  'in stock',
                  style: TextStyle(fontSize: 10, color: AppColor.textMuted),
                ),
              ],
            ),
          ),
          // ── Expanded: poora data ──────────────────────────
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Prices
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    'Purchase Price',
                    _money(item.purchasePrice),
                    AppColor.textDark,
                  ),
                ),
                Expanded(
                  child: _miniStat(
                    'Sale Price',
                    _money(item.sellingPrice),
                    AppColor.cashIn,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Min / Max
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    'Min Quantity',
                    '${item.minStockLevel} ${item.unitOfMeasure}',
                    AppColor.textDark,
                  ),
                ),
                Expanded(
                  child: _miniStat(
                    'Max Quantity',
                    '${item.maxStockLevel} ${item.unitOfMeasure}',
                    AppColor.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stock value
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    'Stock Value',
                    _money(item.stockValue),
                    AppColor.primary,
                  ),
                ),
                Expanded(
                  child: _miniStat(
                    'Unit',
                    item.unitOfMeasure,
                    AppColor.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColor.textMuted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// Rs. formatting (thousands separator)
String _fmtRs(double v) {
  final neg = v < 0;
  final s = v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '${neg ? '- ' : ''}Rs. $s';
}

// ── Shimmer ───────────────────────────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
      );
}
