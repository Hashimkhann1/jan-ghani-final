// =============================================================
// linked_store_inventory_screen.dart
// Linked store ka inventory — filter chips + search + infinite scroll.
// Shell ke content area mein embed hota hai (apna Scaffold nahi).
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/inventory/presentation/providers/linked_store_inventory_provider.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/inventory/presentation/widgets/linked_store_product_row.dart';

class LinkedStoreInventoryScreen extends ConsumerStatefulWidget {
  final String storeId;
  const LinkedStoreInventoryScreen({super.key, required this.storeId});

  @override
  ConsumerState<LinkedStoreInventoryScreen> createState() =>
      _LinkedStoreInventoryScreenState();
}

class _LinkedStoreInventoryScreenState
    extends ConsumerState<LinkedStoreInventoryScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(linkedStoreInventoryProvider(widget.storeId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(linkedStoreInventoryProvider(widget.storeId));
    final notifier = ref.read(linkedStoreInventoryProvider(widget.storeId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: notifier.setSearch,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search product name, SKU ya barcode...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColor.textHint),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColor.grey500),
              suffixIcon: state.search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: AppColor.grey500),
                      splashRadius: 14,
                      onPressed: () {
                        _searchCtrl.clear();
                        notifier.setSearch('');
                      },
                    ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              filled: true,
              fillColor: AppColor.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColor.grey200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColor.primary),
              ),
            ),
          ),
        ),

        // ── Filter chips ────────────────────────────────────
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _Chip(
                label: 'All', count: state.allCount,
                color: AppColor.primary,
                selected: state.status == 'all',
                onTap: () => notifier.setStatus('all'),
              ),
              const SizedBox(width: 8),
              _Chip(
                label: 'In Stock', count: state.inStockCount,
                color: AppColor.success,
                selected: state.status == 'ok',
                onTap: () => notifier.setStatus('ok'),
              ),
              const SizedBox(width: 8),
              _Chip(
                label: 'Low (Below Min)', count: state.lowCount,
                color: AppColor.warning,
                selected: state.status == 'low',
                onTap: () => notifier.setStatus('low'),
              ),
              const SizedBox(width: 8),
              _Chip(
                label: 'Out of Stock', count: state.outCount,
                color: AppColor.error,
                selected: state.status == 'out',
                onTap: () => notifier.setStatus('out'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppColor.grey200),

        // ── List ────────────────────────────────────────────
        Expanded(child: _buildList(state, notifier)),
      ],
    );
  }

  Widget _buildList(
      LinkedStoreInventoryState state, LinkedStoreInventoryNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColor.error, size: 34),
            const SizedBox(height: 10),
            const Text('Data load nahi hua',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(state.error!,
                  style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: notifier.refresh,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(8)),
                child: const Text('Retry',
                    style: TextStyle(color: AppColor.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 36, color: AppColor.grey300),
            SizedBox(height: 10),
            Text('Koi product nahi mila',
                style: TextStyle(fontSize: 13, color: AppColor.textHint)),
          ],
        ),
      );
    }

    final count = state.products.length;
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.only(bottom: 16),
        // +1 for the footer loader when more pages
        itemCount: count + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= count) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return LinkedStoreProductRow(
            product: state.products[i],
            isLast: i == count - 1 && !state.hasMore,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER CHIP
// ─────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : AppColor.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColor.grey200),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColor.white : AppColor.grey600,
                )),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? AppColor.white.withOpacity(0.25) : AppColor.grey200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColor.white : AppColor.grey600,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
