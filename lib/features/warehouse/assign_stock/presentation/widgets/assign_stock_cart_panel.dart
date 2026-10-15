// Updated on 2026-10-15 10:24 AM
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';
import 'package:jan_ghani_final/features/warehouse/assign_stock/presentation/providers/assign_stock_provider.dart';
import 'assign_stock_cart_header.dart';
import 'assign_stock_cart_row.dart';
import 'assign_stock_cart_summary.dart';

class AssignStockCartPanel extends ConsumerStatefulWidget {
  const AssignStockCartPanel({super.key});

  @override
  ConsumerState<AssignStockCartPanel> createState() =>
      _AssignStockCartPanelState();
}

class _AssignStockCartPanelState extends ConsumerState<AssignStockCartPanel> {
  final ScrollController _scrollCtrl = ScrollController();
  int _prevCount = 0;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignStockProvider);
    final notifier = ref.read(assignStockProvider.notifier);

    if (state.cartItems.length > _prevCount) {
      _scrollToBottom();
    }
    _prevCount = state.cartItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Store selector + transfer number
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: WarehouseAppColor.white,
            border: Border(bottom: BorderSide(color: WarehouseAppColor.grey200)),
          ),
          child: Row(
            children: [
              // Transfer number
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: WarehouseAppColor.grey100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WarehouseAppColor.grey200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 14, color: WarehouseAppColor.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      state.transferNumber.isEmpty
                          ? 'Generating...'
                          : state.transferNumber,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: WarehouseAppColor.textPrimary),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Store dropdown
              Expanded(
                child: state.isLoading
                    ? const LinearProgressIndicator(minHeight: 2)
                    : DropdownButtonFormField<String>(
                  value: state.selectedStoreId,
                  hint: const Text('Store select karo',
                      style: TextStyle(
                          fontSize: 13,
                          color: WarehouseAppColor.textHint)),
                  onChanged: (val) {
                    if (val == null) return;
                    final store = state.linkedStores
                        .firstWhere((s) => s.storeId == val);
                    notifier.selectStore(
                        store.storeId, store.storeName);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                        Icons.store_rounded,
                        size: 16,
                        color: WarehouseAppColor.primary),
                    filled: true,
                    fillColor: WarehouseAppColor.primary.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: WarehouseAppColor.primary
                                .withOpacity(0.3))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: WarehouseAppColor.primary
                                .withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: WarehouseAppColor.primary,
                            width: 1.5)),
                  ),
                  items: state.linkedStores
                      .map((store) => DropdownMenuItem(
                    value: store.storeId,
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.storeName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        SizedBox(width: 30,),
                        Text(store.storeCode,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              color: Colors.green
                            )),
                      ],
                    ),
                  ))
                      .toList(),
                ),
              ),

              const SizedBox(width: 12),

              // Notes field
              SizedBox(
                width: 170,
                child: TextField(
                  onChanged: notifier.updateNotes,
                  style: const TextStyle(
                      fontSize: 13, color: WarehouseAppColor.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Notes (optional)',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: WarehouseAppColor.textHint),
                    prefixIcon: const Icon(Icons.notes_rounded,
                        size: 14, color: WarehouseAppColor.grey400),
                    filled: true,
                    fillColor: WarehouseAppColor.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: WarehouseAppColor.grey200)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: WarehouseAppColor.grey200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: WarehouseAppColor.primary, width: 1.5)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cart header
        const AssignStockCartHeader(),

        // Cart items
        Expanded(
          child: state.cartItems.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 56, color: WarehouseAppColor.grey300),
                const SizedBox(height: 12),
                const Text(
                  'Koi product add nahi kiya\nDouble tap karke product add karo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: WarehouseAppColor.textHint),
                ),
              ],
            ),
          )
              : ListView.separated(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            itemCount: state.cartItems.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = state.cartItems[index];
              // ValueKey(cartId) — Flutter row-states ko position se
              // nahi, cartId se match kare. Warna cart se koi item
              // remove karne par neechay wali row apne purane state
              // (controllers) ke saath re-use ho jati thi aur upar wali
              // (removed) item ki prices dikhati thi.
              return AssignStockCartRow(
                key: ValueKey(item.cartId),
                item: item,
                index: index,
              );
            },
          ),
        ),

        // Summary + button
        const AssignStockCartSummary(),
      ],
    );
  }
}