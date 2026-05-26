import 'package:flutter/material.dart';
import '../../../../../core/service/print/low_stock_print_service.dart';
import '../../data/model/dashboard_model.dart';
import '../widget/stock_badge_card_widget.dart';

class LowStockScreen extends StatefulWidget {
  final List<LowStockItem> items;
  final String storeName;

  const LowStockScreen({
    required this.items,
    this.storeName = 'My Store',
  });

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  String _search = '';
  final Set<String> _selected = {};
  bool _isPrinting = false;

  // ── Filtered list ──────────────────────────────────────────
  List<LowStockItem> get _filtered => widget.items
      .where((i) =>
  i.name.toLowerCase().contains(_search.toLowerCase()) ||
      i.sku.toLowerCase().contains(_search.toLowerCase()) ||
      (i.barcode ?? '').contains(_search))
      .toList();

  bool get _allSelected =>
      _filtered.isNotEmpty &&
          _filtered.every((i) => _selected.contains(i.id));

  void _toggleAll(bool? val) {
    setState(() {
      if (val == true) {
        _selected.addAll(_filtered.map((i) => i.id));
      } else {
        _selected.removeAll(_filtered.map((i) => i.id));
      }
    });
  }

  void _toggleItem(String id) {
    setState(() {
      _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    });
  }

  // ── Print ──────────────────────────────────────────────────
  Future<void> _printSelected() async {
    final toPrint = widget.items
        .where((i) => _selected.contains(i.id))
        .toList();

    if (toPrint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koi item select nahi hai'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPrinting = true);
    try {
      await LowStockPrintService.printReport(
        storeName: widget.storeName,
        items: toPrint,
        date: DateTime.now(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outCount =
        widget.items.where((i) => i.status == StockStatus.outOfStock).length;
    final lowCount =
        widget.items.where((i) => i.status == StockStatus.low).length;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Low Stock Alert',
          style: TextStyle(
            color: Color(0xFF1A1D23),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _isPrinting ? null : _printSelected,
                icon: _isPrinting
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.print_outlined, size: 18),
                label: Text('Print (${_selected.length})'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),

      body: Column(
        children: [
          // ── Summary Badges ───────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: StockBadgeCard(
                    label: 'Out of Stock',
                    count: outCount,
                    color: const Color(0xFFEF4444),
                    bg: const Color(0xFFFEF2F2),
                    icon: Icons.remove_shopping_cart_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StockBadgeCard(
                    label: 'Low Stock',
                    count: lowCount,
                    color: const Color(0xFFF59E0B),
                    bg: const Color(0xFFFFFBEB),
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
          ),

          // ── Search ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search product, SKU, barcode...',
                hintStyle:
                const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // ── Table Header ─────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: _TableHeader(
              allSelected: _allSelected,
              hasItems: filtered.isNotEmpty,
              onSelectAll: _toggleAll,
            ),
          ),

          // ── Table Body ───────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState()
                : Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: Color(0xFFF1F5F9),
                ),
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  final isSelected = _selected.contains(item.id);
                  return _TableRow(
                    item: item,
                    isSelected: isSelected,
                    isEven: i.isEven,
                    onTap: () => _toggleItem(item.id),
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

// ── Table Header ──────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  final bool allSelected;
  final bool hasItems;
  final ValueChanged<bool?> onSelectAll;

  const _TableHeader({
    required this.allSelected,
    required this.hasItems,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 36,
            child: Checkbox(
              value: allSelected,
              tristate: true,
              onChanged: hasItems ? onSelectAll : null,
              activeColor: const Color(0xFF3B82F6),
              checkColor: Colors.white,
              side: const BorderSide(color: Colors.white60, width: 1.5),
            ),
          ),
          // Product Name
          const Expanded(
            flex: 4,
            child: Text('PRODUCT', style: style),
          ),
          // Stock
          const SizedBox(
            width: 52,
            child: Text('STOCK', style: style, textAlign: TextAlign.center),
          ),
          // Min
          const SizedBox(
            width: 44,
            child: Text('MIN', style: style, textAlign: TextAlign.center),
          ),
          // Status
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

// ── Table Row ─────────────────────────────────────────────────
class _TableRow extends StatelessWidget {
  final LowStockItem item;
  final bool isSelected;
  final bool isEven;
  final VoidCallback onTap;

  const _TableRow({
    required this.item,
    required this.isSelected,
    required this.isEven,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = item.status == StockStatus.outOfStock;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected
            ? const Color(0xFFEFF6FF)
            : isEven
            ? Colors.white
            : const Color(0xFFFAFAFB),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            // ── Checkbox ──────────────────────────────
            SizedBox(
              width: 36,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                activeColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // ── Product Name + SKU ────────────────────
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.sku.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.sku,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Stock ─────────────────────────────────
            SizedBox(
              width: 52,
              child: Center(
                child: Text(
                  item.quantity.toStringAsFixed(
                      item.quantity.truncateToDouble() == item.quantity ? 0 : 1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOut
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ),

            // ── Min Stock ─────────────────────────────
            SizedBox(
              width: 44,
              child: Center(
                child: Text(
                  item.minStock.toStringAsFixed(
                      item.minStock.truncateToDouble() == item.minStock ? 0 : 1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),

            // ── Status Dot ────────────────────────────
            SizedBox(
              width: 28,
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOut
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
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

// ── Empty State ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Koi product nahi mila',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}