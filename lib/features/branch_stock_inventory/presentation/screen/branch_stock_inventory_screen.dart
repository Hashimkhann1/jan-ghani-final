import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/core/widget/textfield/app_text_field.dart';
import '../../../../core/widget/figure_card_widget.dart';
import '../../../warehouse_stock_inventory/presentation/widget/chip_widget.dart';
import '../provider/branch_stock_inventory_provider.dart';

class BranchStockInventoryScreen extends ConsumerWidget {
  const BranchStockInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(filteredBranchStockProvider);
    final allInventoryAsync = ref.watch(branchStockProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Branch Stock Inventory",
          style: TextStyle(
            color: Color(0xFF1A1D23),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: allInventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(branchStockProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allInventories) {
          final totalProducts = allInventories.length;
          final totalStock = allInventories.fold<int>(0, (s, i) => s + i.maxStock);
          final lowStock = allInventories.where((i) => i.minStock <= 20).length;
          final outOfStock = allInventories.where((i) => !i.isActive).length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Summary Cards ──
                Row(
                  spacing: 12,
                  children: [
                    SummaryCard(
                      title: "Total Products",
                      value: "$totalProducts",
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF6366F1),
                    ),
                    SummaryCard(
                      title: "Total Stock",
                      value: "$totalStock",
                      icon: Icons.store_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    SummaryCard(
                      title: "Low Stock",
                      value: "$lowStock",
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    SummaryCard(
                      title: "Inactive",
                      value: "$outOfStock",
                      icon: Icons.remove_shopping_cart_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),

                16.hBox,

                // ── Search ──
                Row(
                  children: [
                    AppTextField(
                      hint: "Search by product, barcode, category...",
                      onChanged: (v) =>
                      ref.read(branchSearchQueryProvider.notifier).state = v,
                    ),
                  ],
                ),

                16.hBox,

                // ── Table ──
                Expanded(
                  child: inventoryAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (inventories) {
                      if (inventories.isEmpty) {
                        return _EmptyState();
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF8F9FF),
                                ),
                                headingTextStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6C7280),
                                  letterSpacing: 0.5,
                                ),
                                dataRowColor: WidgetStateProperty.resolveWith(
                                      (_) => Colors.white,
                                ),
                                dividerThickness: 1,
                                columnSpacing: 20,
                                horizontalMargin: 16,
                                columns: const [
                                  DataColumn(label: Text("Barcode")),
                                  DataColumn(label: Text("Product Name")),
                                  DataColumn(label: Text("Category")),
                                  DataColumn(label: Text("Company")),
                                  DataColumn(label: Text("Unit")),
                                  DataColumn(label: Text("Sale Price"), numeric: true),
                                  DataColumn(label: Text("Purchase Price"), numeric: true),
                                  DataColumn(label: Text("Tax"), numeric: true),
                                  DataColumn(label: Text("Discount"), numeric: true),
                                  DataColumn(label: Text("Min Stock"), numeric: true),
                                  DataColumn(label: Text("Max Stock"), numeric: true),
                                  DataColumn(label: Text("Expiry")),
                                  DataColumn(label: Text("Status")),
                                ],
                                rows: inventories.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final isLowStock = item.minStock <= 20;

                                  final expiryText = item.expiryDate != null
                                      ? '${item.expiryDate!.day.toString().padLeft(2, '0')}/'
                                      '${item.expiryDate!.month.toString().padLeft(2, '0')}/'
                                      '${item.expiryDate!.year}'
                                      : 'N/A';

                                  return DataRow(
                                    color: WidgetStateProperty.all(
                                      index.isEven
                                          ? Colors.white
                                          : const Color(0xFFFAFAFC),
                                    ),
                                    cells: [
                                      // Barcode
                                      DataCell(
                                        Text(
                                          item.barcode,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                            color: Color(0xFF6C7280),
                                          ),
                                        ),
                                      ),

                                      // Product Name
                                      DataCell(
                                        SizedBox(
                                          width: 140,
                                          child: Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1D23),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),

                                      // Category
                                      DataCell(
                                        ChipWidget(
                                          label: item.category,
                                          bg: const Color(0xFFEEF2FF),
                                          textColor: const Color(0xFF6366F1),
                                        ),
                                      ),

                                      // Company
                                      DataCell(
                                        Text(
                                          item.companyName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6C7280),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      // Unit
                                      DataCell(
                                        Text(
                                          item.unit,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6C7280),
                                          ),
                                        ),
                                      ),

                                      // Sale Price
                                      DataCell(
                                        Text(
                                          'Rs. ${item.sellPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),

                                      // Purchase Price
                                      DataCell(
                                        Text(
                                          'Rs. ${item.purchasePrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6C7280),
                                          ),
                                        ),
                                      ),

                                      // Tax
                                      DataCell(
                                        Text(
                                          '${item.tax.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6C7280),
                                          ),
                                        ),
                                      ),

                                      // Discount
                                      DataCell(
                                        Text(
                                          '${item.discount.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFF59E0B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      // Min Stock
                                      DataCell(
                                        ChipWidget(
                                          label: '${item.minStock}',
                                          bg: isLowStock
                                              ? const Color(0xFFFEF3C7)
                                              : const Color(0xFFF3F4F6),
                                          textColor: isLowStock
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFF6C7280),
                                        ),
                                      ),

                                      // Max Stock
                                      DataCell(
                                        Text(
                                          '${item.maxStock}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A1D23),
                                          ),
                                        ),
                                      ),

                                      // Expiry
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 12,
                                              color: item.expiryDate != null
                                                  ? const Color(0xFF6366F1)
                                                  : const Color(0xFFD1D5DB),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              expiryText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: item.expiryDate != null
                                                    ? const Color(0xFF374151)
                                                    : const Color(0xFFD1D5DB),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Status
                                      DataCell(
                                        ChipWidget(
                                          label: item.isActive ? 'Active' : 'Inactive',
                                          bg: item.isActive
                                              ? const Color(0xFFD1FAE5)
                                              : const Color(0xFFFEE2E2),
                                          textColor: item.isActive
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Empty state when search yields no results ──
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No products found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D23),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Try a different search keyword",
            style: TextStyle(fontSize: 13, color: Color(0xFF6C7280)),
          ),
        ],
      ),
    );
  }
}