import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import 'package:jan_ghani_final/features/branch/branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../customer/presentation/widget/customer_filter_chip_widget.dart';
import '../../data/datasource/branch_stock_remote_datasource.dart';
import '../provider/branch_stock_inventory_provider.dart';

class BranchStockInventoryScreen extends ConsumerStatefulWidget {
  const BranchStockInventoryScreen({super.key});

  @override
  ConsumerState<BranchStockInventoryScreen> createState() =>
      _BranchStockInventoryScreenState();
}

class _BranchStockInventoryScreenState
    extends ConsumerState<BranchStockInventoryScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(branchStockProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(branchStockProvider);
    final products = state.filteredProducts;

    ref.listen<BranchStockState>(branchStockProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior:        SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label:     'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(branchStockProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Stock Inventory', style: TextStyle(fontWeight: FontWeight.w700)),
        toolbarHeight: 60,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(branchStockProvider.notifier).load(),
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
                foregroundColor: AppColor.textSecondary),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Stat Cards ───────────────────────────
            Row(
              children: [
                SummaryCard(
                  title: 'Total Products',
                  value: '${state.totalProducts}',
                  icon:  Icons.inventory_2_outlined,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'In Stock',
                  value: '${state.inStockCount}',
                  icon:  Icons.check_circle_outline_rounded,
                  color: AppColor.success,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Low Stock',
                  value: '${state.lowStockCount}',
                  icon:  Icons.warning_amber_rounded,
                  color: AppColor.warning,
                ),
                const SizedBox(width: 12),
                SummaryCard(
                  title: 'Out of Stock',
                  value: '${state.outOfStockCount}',
                  icon:  Icons.remove_circle_outline_rounded,
                  color: AppColor.error,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Search + Filters ─────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      onChanged: ref
                          .read(branchStockProvider.notifier)
                          .onSearchChanged,
                      style:        const TextStyle(fontSize: 13),
                      cursorHeight: 14,
                      decoration: InputDecoration(
                        hintText: 'Search by name, SKU, barcode...',
                        hintStyle: const TextStyle(
                            color: AppColor.textHint, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColor.grey400),
                        filled:    true,
                        fillColor: AppColor.grey100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   BorderSide.none,
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
                      onTap: ref
                          .read(branchStockProvider.notifier)
                          .onFilterStatusChanged,
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Table ─────────────────────────────────
            Expanded(
              child: products.isEmpty ?
              _EmptyState(isSearching: state.searchQuery.isNotEmpty) :
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  const double minTableWidth = 1200;
                  final tableWidth =
                  availableWidth > minTableWidth ? availableWidth : minTableWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: tableWidth),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColor.grey100),
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                                (s) => s.contains(WidgetState.hovered)
                                ? AppColor.primary.withValues(alpha: 0.05)
                                : null,
                          ),
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 60,
                          columnSpacing: (tableWidth * 0.02).clamp(12.0, 40.0),
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('SKU')),
                            DataColumn(label: Text('Barcode')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Unit')),
                            DataColumn(label: Text('Cost Price')),
                            DataColumn(label: Text('Sale Price')),
                            DataColumn(label: Text('Wholesale')),
                            DataColumn(label: Text('Tax')),
                            DataColumn(label: Text('Discount')),
                            DataColumn(label: Text('Min Stock')),
                            DataColumn(label: Text('Max Stock')),
                            DataColumn(label: Text('Quantity')),
                          ],
                          rows: products.map((p) => DataRow(
                            cells: [
                              // SKU
                              DataCell(Text(p.sku,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColor.textSecondary))),

                              // Barcode
                              DataCell(SizedBox(
                                width: 140,
                                child: Text(
                                  BranchStockDataSource().parseBarcode(p.barcode).toString(),
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColor.textSecondary),
                                ),
                              )),

                              // Name
                              DataCell(SizedBox(
                                width: 140,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1),
                                    if (p.description != null)
                                      Text(p.description!,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColor.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1),
                                  ],
                                ),
                              )),

                              // Unit
                              DataCell(Container(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColor.grey100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(p.unitOfMeasure,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.textSecondary)),
                              )),

                              // Cost Price
                              DataCell(Text(p.costPriceLabel,
                                  style: const TextStyle(fontSize: 13))),

                              // Sale Price
                              DataCell(Text(p.sellingPriceLabel,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.primary))),

                              // Wholesale
                              DataCell(Text(p.wholesalePriceLabel,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColor.textSecondary))),

                              // Tax
                              DataCell(p.taxRate > 0
                                  ? _PercentBadge(value: p.taxRateLabel, color: AppColor.info)
                                  : const Text('—',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColor.textSecondary))),

                              // Discount
                              DataCell(p.discount > 0
                                  ? _PercentBadge(
                                  value: p.discountLabel, color: AppColor.warning)
                                  : const Text('—',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColor.textSecondary))),

                              // Min Stock
                              DataCell(Text('${p.minStockLevel} ${p.unitOfMeasure}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColor.textSecondary))),

                              // Max Stock
                              DataCell(Text('${p.maxStockLevel} ${p.unitOfMeasure}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColor.textSecondary))),

                              // Quantity
                              DataCell(Text(
                                p.quantityLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: p.isOutOfStock
                                      ? AppColor.error
                                      : p.isLowStock
                                      ? AppColor.warning
                                      : AppColor.success,
                                ),
                              )),
                            ],
                          )).toList(),
                        ),
                      ),
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

// ── Percent Badge ─────────────────────────────────────────────
class _PercentBadge extends StatelessWidget {
  final String value;
  final Color  color;
  const _PercentBadge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(value,
        style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      color)),
  );
}

// ── Stock Status Badge ────────────────────────────────────────
class _StockStatusBadge extends StatelessWidget {
  final BranchStockModel p;
  const _StockStatusBadge({required this.p});

  Color get _color {
    if (p.isOutOfStock) return AppColor.error;
    if (p.isLowStock)   return AppColor.warning;
    return AppColor.success;
  }

  IconData get _icon {
    if (p.isOutOfStock) return Icons.remove_circle_outline_rounded;
    if (p.isLowStock)   return Icons.warning_amber_rounded;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color:        _color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border:       Border.all(color: _color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 12, color: _color),
        const SizedBox(width: 5),
        Text(p.stockStatus,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      _color)),
      ],
    ),
  );
}

// ── Empty State ───────────────────────────────────────────────
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
          isSearching ? 'Koi product nahi mila' : 'Koi stock nahi',
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