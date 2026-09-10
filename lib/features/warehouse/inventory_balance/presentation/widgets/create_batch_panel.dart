// =============================================================
// create_batch_panel.dart
// Tab 1 — Create Balance Request (redesigned).
//
// Layout: Left sidebar (280px) + main content + sticky footer.
//   • Left: store picker + summary tiles + view filters + sort
//   • Main: search bar + item cards (elegant, spacious)
//   • Footer: selected count + impact + big Send button
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/data/models/linked_store_model/linked_store_model.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/presentation/providers/link_stores_provider.dart';

import '../../data/model/balance_item_model.dart';
import '../../domain/balance_status.dart';
import '../provider/inventory_balance_provider.dart';

class CreateBatchPanel extends ConsumerWidget {
  const CreateBatchPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(createBatchProvider);
    final notifier = ref.read(createBatchProvider.notifier);

    // Success + error toasts
    ref.listen<CreateBatchState>(createBatchProvider, (prev, next) {
      if (next.successBatchNumber != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Batch bhej di gayi — ${next.successBatchNumber}'),
            backgroundColor: AppColor.success,
            behavior: SnackBarBehavior.floating,
          ));
        notifier.ackSuccess();
      }
      if (next.errorMessage != null && (prev?.errorMessage != next.errorMessage)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior: SnackBarBehavior.floating,
          ));
        notifier.ackError();
      }
    });

    return Container(
      color: const Color(0xFFF7F8FA),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SizedBox(width: 280, child: _LeftSidebar()),
          VerticalDivider(width: 1, thickness: 1, color: AppColor.grey200),
          Expanded(child: _MainContent()),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// LEFT SIDEBAR
// ═════════════════════════════════════════════════════════════
class _LeftSidebar extends ConsumerWidget {
  const _LeftSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createBatchProvider);
    final storesAsync = ref.watch(linkedStoresProvider(AppConfig.warehouseId));

    return Container(
      color: AppColor.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store picker
            storesAsync.when(
              data: (stores) => _StorePickerCard(
                stores: stores,
                selectedId: state.selectedStoreId,
              ),
              loading: () => const _StoreLoader(),
              error:   (_, __) => const Text('Stores load nahi hui',
                  style: TextStyle(color: AppColor.error, fontSize: 12)),
            ),
            const SizedBox(height: 18),

            // Summary tiles (only when a store is picked)
            if (state.selectedStoreId != null) ...[
              _SummaryTiles(storeId: state.selectedStoreId!),
              const SizedBox(height: 20),
              const _SectionLabel('VIEW'),
              const SizedBox(height: 10),
              _ViewFilterChips(storeId: state.selectedStoreId!),
              const SizedBox(height: 22),
              const _SectionLabel('SORT'),
              const SizedBox(height: 8),
              const _SortDropdown(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColor.textSecondary,
          letterSpacing: 1.2,
        ));
  }
}

class _StorePickerCard extends ConsumerWidget {
  final List<LinkedStoreModel> stores;
  final String? selectedId;
  const _StorePickerCard({required this.stores, required this.selectedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stores.isEmpty) {
      return const Text('Koi linked store nahi',
          style: TextStyle(color: AppColor.textSecondary, fontSize: 12));
    }
    final selected = selectedId == null
        ? null
        : stores.firstWhere((s) => s.storeId == selectedId,
            orElse: () => stores.first);

    return InkWell(
      onTap: () async {
        final picked = await showModalBottomSheet<LinkedStoreModel>(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
          builder: (_) => _StorePickList(stores: stores),
        );
        if (picked != null) {
          ref.read(createBatchProvider.notifier).selectStore(picked.storeId);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.grey200),
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.storefront_rounded,
                size: 17, color: AppColor.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selected?.storeName ?? 'Store select karein',
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (selected != null)
                  Text(selected.storeCode,
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.expand_more_rounded,
              size: 18, color: AppColor.textSecondary),
        ]),
      ),
    );
  }
}

class _StorePickList extends StatelessWidget {
  final List<LinkedStoreModel> stores;
  const _StorePickList({required this.stores});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColor.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select store',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    )),
              ),
            ),
            const Divider(height: 1, color: AppColor.grey100),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: stores.map((s) => ListTile(
                  leading: const Icon(Icons.storefront_rounded,
                      color: AppColor.primary, size: 18),
                  title: Text(s.storeName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(s.storeCode,
                      style: const TextStyle(fontSize: 11)),
                  onTap: () => Navigator.of(context).pop(s),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreLoader extends StatelessWidget {
  const _StoreLoader();
  @override
  Widget build(BuildContext context) => Container(
    height: 60,
    decoration: BoxDecoration(
      color: AppColor.grey100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(
      child: SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
class _SummaryTiles extends ConsumerWidget {
  final String storeId;
  const _SummaryTiles({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(createBatchProvider);
    final rowsAsync = ref.watch(pendingCountsProvider(storeId));

    return rowsAsync.when(
      loading: () => const _TilesLoader(),
      error:   (_, __) => const _TilesLoader(),
      data: (rows) {
        final effective = rows.map((r) {
          final physical = state.overrides[r.countingId] ?? r.physicalStock;
          final delta    = physical - r.systemStock;
          final impact   = (delta * r.unitPrice).abs();
          return (row: r, physical: physical, delta: delta, impact: impact,
                  isHigh: impact > kHighVarianceRupeeThreshold);
        }).toList();

        final total = effective.length;
        final totalImpact = effective.fold<double>(0, (a, e) => a + e.impact);
        final redFlagCount = effective.where((e) => e.isHigh).length;
        final selectedCount = state.selectedCountingIds.length;
        final progress = total == 0 ? 0.0 : selectedCount / total;

        return Column(
          children: [
            _SummaryTile(
              label: 'Total Pending', value: total.toString(),
              icon: Icons.inbox_outlined, iconColor: AppColor.primary,
            ),
            const SizedBox(height: 8),
            _SummaryTile(
              label: 'Total Rs Impact',
              value: 'Rs ${totalImpact.pkrFormat}',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColor.info,
            ),
            const SizedBox(height: 8),
            _SummaryTile(
              label: 'Red-flag items', value: redFlagCount.toString(),
              icon: Icons.warning_amber_rounded, iconColor: AppColor.error,
            ),
            const SizedBox(height: 8),
            _SummaryProgressTile(
              selected: selectedCount, total: total, progress: progress,
            ),
          ],
        );
      },
    );
  }
}

class _TilesLoader extends StatelessWidget {
  const _TilesLoader();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(4, (_) => Container(
      height: 54,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColor.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
    )),
  );
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _SummaryTile({
    required this.label, required this.value,
    required this.icon, required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColor.textSecondary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SummaryProgressTile extends StatelessWidget {
  final int selected;
  final int total;
  final double progress;
  const _SummaryProgressTile({
    required this.selected, required this.total, required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Selected',
                style: TextStyle(
                    fontSize: 10.5, color: AppColor.textSecondary,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$selected  ',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: AppColor.primary)),
            Text('/ $total',
                style: const TextStyle(
                    fontSize: 12, color: AppColor.textSecondary,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColor.primary.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColor.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _ViewFilterChips extends ConsumerWidget {
  final String storeId;
  const _ViewFilterChips({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createBatchProvider);
    final rowsAsync = ref.watch(pendingCountsProvider(storeId));
    final notifier = ref.read(createBatchProvider.notifier);

    return rowsAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (rows) {
        int allCount = rows.length;
        int redFlag = 0, missing = 0, extra = 0;
        for (final r in rows) {
          final physical = state.overrides[r.countingId] ?? r.physicalStock;
          final delta = physical - r.systemStock;
          final impact = (delta * r.unitPrice).abs();
          if (impact > kHighVarianceRupeeThreshold) redFlag++;
          if (delta < 0) missing++;
          if (delta > 0) extra++;
        }

        Widget chip(String label, int count, CreateViewFilter f, {IconData? icon, Color? icColor}) {
          final active = state.viewFilter == f;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: () => notifier.setViewFilter(f),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? AppColor.primary : AppColor.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: active ? AppColor.primary : AppColor.grey200,
                  ),
                ),
                child: Row(children: [
                  if (icon != null) ...[
                    Icon(icon, size: 13, color: active ? Colors.white : (icColor ?? AppColor.textSecondary)),
                    const SizedBox(width: 6),
                  ],
                  Text(label,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColor.textPrimary,
                      )),
                  const Spacer(),
                  Text(count.toString(),
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: active
                            ? Colors.white.withOpacity(0.9)
                            : AppColor.textSecondary,
                      )),
                ]),
              ),
            ),
          );
        }

        return Column(children: [
          chip('All', allCount, CreateViewFilter.all),
          chip('Red-flag only', redFlag, CreateViewFilter.redFlag,
              icon: Icons.warning_amber_rounded, icColor: AppColor.error),
          chip('Missing money', missing, CreateViewFilter.missing,
              icon: Icons.arrow_downward_rounded, icColor: AppColor.error),
          chip('Extra stock', extra, CreateViewFilter.extra,
              icon: Icons.arrow_upward_rounded, icColor: AppColor.success),
        ]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _SortDropdown extends ConsumerWidget {
  const _SortDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createBatchProvider);
    final notifier = ref.read(createBatchProvider.notifier);

    String label(CreateSortMode m) {
      switch (m) {
        case CreateSortMode.impactDesc:  return 'Impact (biggest first)';
        case CreateSortMode.impactAsc:   return 'Impact (smallest first)';
        case CreateSortMode.productName: return 'Product name (A–Z)';
        case CreateSortMode.recent:      return 'Recent counts first';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColor.grey200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CreateSortMode>(
          isExpanded: true,
          value: state.sortMode,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColor.textPrimary),
          items: CreateSortMode.values.map((m) => DropdownMenuItem(
            value: m, child: Text(label(m)),
          )).toList(),
          onChanged: (v) { if (v != null) notifier.setSortMode(v); },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// MAIN CONTENT
// ═════════════════════════════════════════════════════════════
class _MainContent extends ConsumerWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createBatchProvider);
    if (state.selectedStoreId == null) {
      return const _EmptyHint(
        text: 'Pehle left side se store select karein',
        icon: Icons.storefront_outlined,
      );
    }
    return _StoreContent(storeId: state.selectedStoreId!);
  }
}

class _StoreContent extends ConsumerWidget {
  final String storeId;
  const _StoreContent({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(pendingCountsProvider(storeId));

    return rowsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error:   (e, _) => Center(child: Text('Load nahi hui: $e',
          style: const TextStyle(color: AppColor.error, fontSize: 12))),
      data: (rows) {
        if (rows.isEmpty) {
          return const _EmptyHint(
            text: 'Is store ke liye koi pending count nahi (last 7 din)',
            icon: Icons.inbox_outlined,
          );
        }
        return Column(children: [
          const _SearchAndActionsBar(),
          Expanded(child: _FilteredList(rows: rows)),
          _StickyFooter(rows: rows),
        ]);
      },
    );
  }
}

class _SearchAndActionsBar extends ConsumerWidget {
  const _SearchAndActionsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(createBatchProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColor.grey200),
            ),
            child: TextField(
              onChanged: notifier.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Search product name…',
                hintStyle: TextStyle(fontSize: 13, color: AppColor.textHint),
                border: InputBorder.none,
                isDense: true,
                icon: Icon(Icons.search_rounded,
                    size: 18, color: AppColor.textSecondary),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const _SelectAllControls(),
      ]),
    );
  }
}

class _SelectAllControls extends ConsumerWidget {
  const _SelectAllControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createBatchProvider);
    final notifier = ref.read(createBatchProvider.notifier);
    final storeId = state.selectedStoreId ?? '';
    final rows = ref.watch(pendingCountsProvider(storeId)).value ?? const [];
    final visible = _visibleRows(rows, state);
    final visibleIds = visible.map((r) => r.countingId).toSet();
    final allSelected = visibleIds.isNotEmpty &&
        visibleIds.difference(state.selectedCountingIds).isEmpty;

    return Row(children: [
      _GhostBtn(
        label: allSelected ? 'Deselect visible' : 'Select all visible',
        icon:  allSelected ? Icons.check_box_outlined : Icons.check_box_outline_blank_rounded,
        onTap: () {
          if (allSelected) {
            final s = {...state.selectedCountingIds};
            s.removeAll(visibleIds);
            notifier.toggleAll(s, true);
          } else {
            final s = {...state.selectedCountingIds}..addAll(visibleIds);
            notifier.toggleAll(s, true);
          }
        },
      ),
      const SizedBox(width: 8),
      _GhostBtn(
        label: 'Clear',
        icon: Icons.close_rounded,
        onTap: () => notifier.toggleAll(const [], false),
      ),
    ]);
  }
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GhostBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColor.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: AppColor.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter + sort helper
List<PendingCountRow> _visibleRows(List<PendingCountRow> rows, CreateBatchState st) {
  Iterable<PendingCountRow> it = rows;

  // Search
  final q = st.searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    it = it.where((r) => r.productName.toLowerCase().contains(q) ||
        (r.productSku ?? '').toLowerCase().contains(q));
  }

  // View filter — override-aware
  double effDelta(PendingCountRow r) =>
      (st.overrides[r.countingId] ?? r.physicalStock) - r.systemStock;
  double effImpact(PendingCountRow r) => (effDelta(r) * r.unitPrice).abs();

  switch (st.viewFilter) {
    case CreateViewFilter.redFlag:
      it = it.where((r) => effImpact(r) > kHighVarianceRupeeThreshold);
      break;
    case CreateViewFilter.missing:
      it = it.where((r) => effDelta(r) < 0);
      break;
    case CreateViewFilter.extra:
      it = it.where((r) => effDelta(r) > 0);
      break;
    case CreateViewFilter.all:
      break;
  }

  final list = it.toList();

  // Sort
  switch (st.sortMode) {
    case CreateSortMode.impactDesc:
      list.sort((a, b) => effImpact(b).compareTo(effImpact(a)));
      break;
    case CreateSortMode.impactAsc:
      list.sort((a, b) => effImpact(a).compareTo(effImpact(b)));
      break;
    case CreateSortMode.productName:
      list.sort((a, b) => a.productName.toLowerCase()
          .compareTo(b.productName.toLowerCase()));
      break;
    case CreateSortMode.recent:
      list.sort((a, b) => b.countedAt.compareTo(a.countedAt));
      break;
  }
  return list;
}

class _FilteredList extends ConsumerWidget {
  final List<PendingCountRow> rows;
  const _FilteredList({required this.rows});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createBatchProvider);
    final visible = _visibleRows(rows, state);
    if (visible.isEmpty) {
      return const _EmptyHint(
          text: 'Filter ke andar koi item nahi. Filter change karein.',
          icon: Icons.filter_alt_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: visible.length,
      itemBuilder: (_, i) => _ItemCard(row: visible[i]),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ITEM CARD (redesigned — spacious, elegant)
// ═════════════════════════════════════════════════════════════
class _ItemCard extends ConsumerWidget {
  final PendingCountRow row;
  const _ItemCard({required this.row});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createBatchProvider);
    final notifier = ref.read(createBatchProvider.notifier);
    final selected = state.selectedCountingIds.contains(row.countingId);
    final override = state.overrides[row.countingId];
    final physical = override ?? row.physicalStock;
    final delta = physical - row.systemStock;
    final impact = (delta * row.unitPrice).abs();
    final isHigh = impact > kHighVarianceRupeeThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColor.primaryLight
              : (isHigh
                  ? AppColor.error.withOpacity(0.4)
                  : AppColor.grey200),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: AppColor.primary.withOpacity(0.10),)]
            : null,
      ),
      child: InkWell(
        onTap: () => notifier.toggleItem(row.countingId, !selected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar (product initial)
              // _ProductAvatar(name: row.productName),
              // const SizedBox(width: 12),

              // Checkbox
              GestureDetector(
                onTap: () => notifier.toggleItem(row.countingId, !selected),
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: selected ? AppColor.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? AppColor.primary : AppColor.grey300,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Product info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.productName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        )),
                    if ((row.productSku ?? '').isNotEmpty)
                      Text(row.productSku!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColor.textSecondary)),
                    const SizedBox(height: 3),
                    Text('Sale price: Rs ${row.unitPrice.pkrFormat}',
                        style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColor.textHint,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 3-column stats
              Expanded(
                flex: 4,
                child: Row(children: [
                  _StatCol(label: 'SYSTEM', value: _fmt(row.systemStock)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PHYSICAL',
                            style: TextStyle(
                              fontSize: 10, color: AppColor.textSecondary,
                              fontWeight: FontWeight.w700, letterSpacing: 0.8,
                            )),
                        const SizedBox(height: 4),
                        _NumberStepper(
                          value: physical,
                          isOverridden: override != null,
                          onChanged: (v) => notifier.setOverride(row.countingId, v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _StatCol(
                    label: 'DELTA',
                    value: (delta >= 0 ? '+' : '−') + _fmt(delta.abs()),
                    valueColor: delta >= 0 ? AppColor.success : AppColor.error,
                    valueWeight: FontWeight.w800,
                  ),
                ]),
              ),
              const SizedBox(width: 16),

              // Right — impact + HIGH badge
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rs ${impact.pkrFormat}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isHigh ? AppColor.error : AppColor.textPrimary,
                        )),
                    const Text('impact',
                        style: TextStyle(
                            fontSize: 10, color: AppColor.textSecondary,
                            fontWeight: FontWeight.w600)),
                    if (isHigh) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColor.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('HIGH',
                            style: TextStyle(
                              fontSize: 9, letterSpacing: 0.8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            )),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
}

class _ProductAvatar extends StatelessWidget {
  final String name;
  const _ProductAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
    // simple hash → hue
    final hue = (name.hashCode & 0x7fffffff) % 6;
    final colors = [
      const Color(0xFFEDE9FE), const Color(0xFFDBEAFE),
      const Color(0xFFDCFCE7), const Color(0xFFFFE4E6),
      const Color(0xFFFEF3C7), const Color(0xFFE0E7FF),
    ];
    final txtColors = [
      const Color(0xFF6D28D9), const Color(0xFF2563EB),
      const Color(0xFF16A34A), const Color(0xFFDB2777),
      const Color(0xFFB45309), const Color(0xFF4338CA),
    ];
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: colors[hue],
        borderRadius: BorderRadius.circular(21),
      ),
      alignment: Alignment.center,
      child: Text(initial,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: txtColors[hue],
          )),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueWeight;
  const _StatCol({
    required this.label, required this.value,
    this.valueColor, this.valueWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 10, color: AppColor.textSecondary,
                fontWeight: FontWeight.w700, letterSpacing: 0.8,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: valueWeight ?? FontWeight.w500,
                color: valueColor ?? AppColor.textPrimary,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Number stepper — minus / editable / plus
class _NumberStepper extends StatefulWidget {
  final double value;
  final bool isOverridden;
  final void Function(double? val) onChanged;
  const _NumberStepper({
    required this.value,
    required this.isOverridden,
    required this.onChanged,
  });

  @override
  State<_NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<_NumberStepper> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(covariant _NumberStepper old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && _ctrl.text != _fmt(widget.value)) {
      _ctrl.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  void _bump(double step) {
    final next = (widget.value + step).clamp(0, 999999).toDouble();
    widget.onChanged(next);
  }

  void _commit() {
    final v = double.tryParse(_ctrl.text.trim());
    if (v != null && v >= 0) {
      widget.onChanged(v);
    } else {
      _ctrl.text = _fmt(widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: widget.isOverridden ? AppColor.warningLight : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isOverridden
              ? AppColor.warning.withOpacity(0.5)
              : AppColor.grey200,
        ),
      ),
      child: Row(children: [
        _StepBtn(icon: Icons.remove_rounded, onTap: () => _bump(-1)),
        Expanded(
          child: TextField(
            controller: _ctrl,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none, isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
            ),
            onSubmitted: (_) => _commit(),
            onEditingComplete: _commit,
            onTapOutside: (_) => _commit(),
          ),
        ),
        _StepBtn(icon: Icons.add_rounded, onTap: () => _bump(1)),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28, height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: AppColor.textSecondary),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// STICKY FOOTER
// ═════════════════════════════════════════════════════════════
class _StickyFooter extends ConsumerWidget {
  final List<PendingCountRow> rows;
  const _StickyFooter({required this.rows});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createBatchProvider);
    final notifier = ref.read(createBatchProvider.notifier);

    final selected = rows.where((r) => state.selectedCountingIds.contains(r.countingId));
    double totalImpact = 0;
    int highSelected = 0;
    int highTotal = 0;
    for (final r in rows) {
      final physical = state.overrides[r.countingId] ?? r.physicalStock;
      final delta = physical - r.systemStock;
      final impact = (delta * r.unitPrice).abs();
      if (impact > kHighVarianceRupeeThreshold) {
        highTotal++;
        if (state.selectedCountingIds.contains(r.countingId)) highSelected++;
      }
    }
    for (final r in selected) {
      final physical = state.overrides[r.countingId] ?? r.physicalStock;
      final delta = physical - r.systemStock;
      totalImpact += (delta * r.unitPrice).abs();
    }
    final selectedCount = state.selectedCountingIds.length;
    final highRemaining = highTotal - highSelected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(top: BorderSide(color: AppColor.grey200)),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Row(children: [
        // Left — selected count
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$selectedCount items selected',
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                )),
            if (highTotal > 0)
              Text('$highSelected of $highTotal red-flag reviewed',
                  style: const TextStyle(
                    fontSize: 11, color: AppColor.textSecondary,
                    fontWeight: FontWeight.w600,
                  )),
          ],
        ),
        const SizedBox(width: 32),

        // Middle — impact
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TOTAL IMPACT',
                style: TextStyle(
                  fontSize: 10, letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textSecondary,
                )),
            const SizedBox(height: 3),
            Row(children: [
              Text('Rs ${totalImpact.pkrFormat}',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  )),
              if (highSelected > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColor.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColor.error.withOpacity(0.3)),
                  ),
                  child: Text('High: $highSelected',
                      style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        color: AppColor.error,
                      )),
                ),
              ],
            ]),
          ],
        ),

        const Spacer(),

        // Warning (unselected high-variance)
        if (highRemaining > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColor.warningLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.warning.withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber_rounded, size: 13, color: AppColor.warning),
              const SizedBox(width: 6),
              Text('$highRemaining red-flag still unselected',
                  style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColor.warning,
                  )),
            ]),
          ),
          const SizedBox(width: 12),
        ],

        _SendButton(
          enabled: !state.isSaving && selectedCount > 0,
          isSaving: state.isSaving,
          onTap: () => notifier.submit(rows),
        ),
      ]),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool isSaving;
  final VoidCallback onTap;
  const _SendButton({required this.enabled, required this.isSaving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color:        AppColor.primary,
            borderRadius: BorderRadius.circular(9),
            boxShadow: enabled
                ? [BoxShadow(color: AppColor.primary.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isSaving)
              const SizedBox(
                width: 15, height: 15,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            else
              const Icon(Icons.send_rounded, size: 15, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              isSaving ? 'Sending...' : 'Send to Reviewer',
              style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white,
              ),
            ),
            if (!isSaving) ...[
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String text;
  final IconData icon;
  const _EmptyHint({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColor.grey300),
          const SizedBox(height: 12),
          Text(text,
              style: const TextStyle(color: AppColor.textHint, fontSize: 13)),
        ],
      ),
    );
  }
}
