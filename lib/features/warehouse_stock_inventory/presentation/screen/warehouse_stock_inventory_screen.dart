import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/core/widget/textfield/app_text_field.dart';
import '../../../../core/widget/figure_card_widget.dart';
import '../../data/model/warehouse_stock_inventory_model.dart';
import '../provider/warehouse_stock_inventory_provider.dart';
import '../widget/action_button_widget.dart';
import '../widget/chip_widget.dart';
import '../widget/stock_inventory_dialog.dart';

class WarehouseStockInventoryScreen extends ConsumerWidget {
  const WarehouseStockInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(stockInventoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Warehouse Stock Inventory",
          style: TextStyle(
            color: Color(0xFF1A1D23),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showDialog(context, ref),
            icon: const Icon(Icons.add_rounded, size: 18),
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
      body: inventoryAsync.when(
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
                onPressed: () => ref.invalidate(stockInventoryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (inventories) {
          final totalProducts = inventories.length;
          final totalStock = inventories.fold<int>(0, (s, i) => s + i.maxStock);
          final lowStock = inventories.where((i) => i.minStock <= 20).length;
          final outOfStock = inventories.where((i) => !i.isActive).length;

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
                      title: "Out of Stock",
                      value: "$outOfStock",
                      icon: Icons.remove_shopping_cart_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),

                16.hBox,

                // ── Search ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AppTextField(
                      hint: "Search by product, barcode, category...",
                      onChanged: (v) {},
                    ),
                  ],
                ),

                16.hBox,

                // ── Table ──
                Expanded(
                  child: Container(
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
                            dataRowColor: WidgetStateProperty.resolveWith((states) => Colors.white,),
                            dividerThickness: 1,
                            columnSpacing: 50,
                            horizontalMargin: 16,
                            columns: const [
                              DataColumn(label: Text("Barcode")),
                              DataColumn(label: Text("Product Name")),
                              DataColumn(label: Text("Category")),
                              DataColumn(label: Text("Company")),
                              DataColumn(label: Text("Sale Price"), numeric: true),
                              DataColumn(label: Text("Expiry")),
                              DataColumn(label: Text("Stock")),
                              DataColumn(label: Text("Low Stock")),
                              DataColumn(label: Text("Status")),
                              DataColumn(label: Text("Actions")),
                            ],
                            rows: inventories.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final isLowStock = item.minStock <= 20;
                              final expiryText = item.expiryDate != null
                                  ? '${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}'
                                  : 'N/A';

                              return DataRow(
                                color: WidgetStateProperty.all(
                                  index.isEven ? Colors.white : const Color(0xFFFAFAFC),
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
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1D23),
                                      ),
                                      overflow: TextOverflow.ellipsis,
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

                                  // Sale Price
                                  DataCell(
                                    Text(
                                      'Rs. ${item.sellPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),

                                  // Expiry
                                  DataCell(
                                    Text(
                                      expiryText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: item.expiryDate != null
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF9CA3AF),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  // Stock (min / max + progress bar)
                                  DataCell(
                                    SizedBox(
                                      width: 90,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${item.minStock} / ${item.maxStock}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1D23),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: item.minStock / item.maxStock,
                                              minHeight: 4,
                                              backgroundColor: const Color(0xFFE5E7EB),
                                              valueColor: AlwaysStoppedAnimation(
                                                isLowStock
                                                    ? const Color(0xFFEF4444)
                                                    : const Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Low Stock chip
                                  DataCell(
                                    ChipWidget(
                                      label: isLowStock ? 'Low' : 'OK',
                                      bg: isLowStock ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                                      textColor: isLowStock ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                    ),
                                  ),

                                  // Status chip
                                  DataCell(
                                      ChipWidget(
                                        label: item.isActive ? 'Active' : 'Inactive',
                                        bg: item.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                        textColor: item.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      ),
                                  ),

                                  // Actions
                                  DataCell(
                                    Row(
                                      children: [
                                        ActionBtn(
                                          icon: Icons.edit_rounded,
                                          color: const Color(0xFF6366F1),
                                          onTap: () => _showDialog(context, ref, item),
                                        ),
                                        const SizedBox(width: 6),
                                        ActionBtn(
                                          icon: Icons.delete_rounded,
                                          color: const Color(0xFFEF4444),
                                          onTap: () => _showDeleteDialog(context, ref, item),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
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


void _showDialog(BuildContext context, WidgetRef ref, [WarehouseStockInventory? item]) async {
  final result = await showDialog<WarehouseStockInventory>(
    context: context,
    barrierDismissible: false,
    builder: (_) => StockInventoryDialog(inventory: item),
  );

  if (result != null) {
    // TODO: Call your service here
    ref.invalidate(stockInventoryProvider); // refresh list
  }
}


void _showDeleteDialog(BuildContext context, WidgetRef ref, WarehouseStockInventory item) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Delete Product",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Are you sure you want to delete\n\"${item.productName}\"?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Info Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "This action cannot be undone. Product will be permanently removed.",
                      style: TextStyle(fontSize: 12, color: Color(0xFF6C7280)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Color(0xFF6C7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // TODO: apna delete service call karo
                      // ref.read(stockInventoryServiceProvider).delete(item.id);
                      ref.invalidate(stockInventoryProvider);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}




