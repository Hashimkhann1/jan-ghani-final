// =============================================================
// balance_report_panel.dart
// Tab 2 — History & Report (Stitch-inspired minimal design).
//
// Layout: Left main column (filters + KPI + status tabs + batch
// group cards with expandable items + timeline dots) + right
// analytics column (This Month summary + 6-Week Audit Trend).
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/data/models/linked_store_model/linked_store_model.dart';
import 'package:jan_ghani_final/features/warehouse/link_stores/presentation/providers/link_stores_provider.dart';

import '../../data/model/balance_batch_model.dart';
import '../../data/model/balance_item_model.dart';
import '../../domain/balance_status.dart';
import '../provider/inventory_balance_provider.dart';

const _kBg = Color(0xFFFAFAFA);

class BalanceReportPanel extends ConsumerWidget {
  const BalanceReportPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: _kBg,
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 1100;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(child: _MainColumn()),
                SizedBox(width: 320, child: _RightColumn()),
              ],
            );
          }
          return const _MainColumn();
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// MAIN COLUMN
// ═════════════════════════════════════════════════════════════
class _MainColumn extends ConsumerWidget {
  const _MainColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(balanceReportProvider);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _FilterBar()),
        SliverToBoxAdapter(child: _KpiRow(items: state.items)),
        SliverToBoxAdapter(child: _StatusTabs(items: state.items)),
        if (state.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else if (state.errorMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(state.errorMessage!,
                    style: const TextStyle(color: AppColor.error)),
              ),
            ),
          )
        else
          _BatchList(state: state),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER BAR
// ─────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(balanceReportProvider);
    final notifier = ref.read(balanceReportProvider.notifier);
    final storesAsync = ref.watch(linkedStoresProvider(AppConfig.warehouseId));

    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
      child: Row(
        children: [
          // Date range
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                initialDateRange: (state.fromDate != null && state.toDate != null)
                    ? DateTimeRange(start: state.fromDate!, end: state.toDate!)
                    : null,
                firstDate: DateTime(2020),
                lastDate:  DateTime(now.year, now.month, now.day),
                helpText: 'Select date range',
                saveText: 'Apply',
              );
              if (picked != null) notifier.setCustomRange(picked.start, picked.end);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColor.grey200),
              ),
              child: Text(
                (state.fromDate != null && state.toDate != null)
                    ? '${fmt(state.fromDate!)} – ${fmt(state.toDate!)}'
                    : 'Date range',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Store dropdown
          storesAsync.when(
            data: (stores) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColor.grey200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.storeFilter ?? '_all',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary),
                  items: [
                    const DropdownMenuItem<String>(
                        value: '_all', child: Text('All stores')),
                    ...stores.map<DropdownMenuItem<String>>((LinkedStoreModel s) =>
                        DropdownMenuItem(value: s.storeId, child: Text(s.storeName))),
                  ],
                  onChanged: (v) => notifier.setStore(v == '_all' ? null : v),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 10),

          // Search
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColor.grey200),
              ),
              child: TextField(
                onChanged: notifier.setSearch,
                decoration: const InputDecoration(
                  hintText: 'Batch # or product...',
                  hintStyle: TextStyle(fontSize: 12.5, color: AppColor.textHint),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Refresh (text-only)
          InkWell(
            onTap: notifier.refresh,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.refresh_rounded, size: 14, color: AppColor.primary),
                SizedBox(width: 5),
                Text('Refresh',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// KPI ROW — 5 cards
// ─────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  final List<BalanceItemModel> items;
  const _KpiRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final counts = <BalanceStatus, int>{};
    final batchIds = <String>{};
    for (final it in items) {
      counts[it.status] = (counts[it.status] ?? 0) + 1;
      batchIds.add(it.batchId);
    }
    final rp = counts[BalanceStatus.reviewPending]  ?? 0;
    final bp = counts[BalanceStatus.branchPending]  ?? 0;
    final ac = counts[BalanceStatus.applied]        ?? 0;
    final rjR = counts[BalanceStatus.reviewerRejected] ?? 0;
    final rjB = counts[BalanceStatus.branchRejected]   ?? 0;
    final rj = rjR + rjB;

    String pct(int n) => total == 0 ? '0%' : '${((n * 100) / total).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Expanded(child: _KpiCard(
          label: 'Total Items',
          value: total.toString(),
          hint:  'across ${batchIds.length} batches',
          color: AppColor.textPrimary,
        )),
        const SizedBox(width: 10),
        Expanded(child: _KpiCard(
          label: 'Review Pending',
          value: rp.toString(),
          hint:  '${pct(rp)} of total',
          color: AppColor.warning,
        )),
        const SizedBox(width: 10),
        Expanded(child: _KpiCard(
          label: 'Awaiting Branch',
          value: bp.toString(),
          hint:  pct(bp),
          color: AppColor.info,
        )),
        const SizedBox(width: 10),
        Expanded(child: _KpiCard(
          label: 'Accepted',
          value: ac.toString(),
          hint:  pct(ac),
          color: AppColor.success,
        )),
        const SizedBox(width: 10),
        Expanded(child: _KpiCard(
          label: 'Rejected',
          value: rj.toString(),
          hint:  'reviewer $rjR · branch $rjB',
          color: AppColor.error,
        )),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color  color;
  const _KpiCard({
    required this.label, required this.value, required this.hint, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10, letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColor.textSecondary,
              )),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800,
                color: color, height: 1.1,
              )),
          const SizedBox(height: 4),
          Text(hint,
              style: const TextStyle(
                fontSize: 11, color: AppColor.textSecondary,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STATUS TABS
// ─────────────────────────────────────────────────────────────
class _StatusTabs extends ConsumerWidget {
  final List<BalanceItemModel> items;
  const _StatusTabs({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(balanceReportProvider);
    final notifier = ref.read(balanceReportProvider.notifier);
    final counts = <BalanceStatus, int>{};
    for (final it in items) {
      counts[it.status] = (counts[it.status] ?? 0) + 1;
    }
    final total = items.length;

    Widget tab(String label, int count, BalanceStatus? filter) {
      final active = state.statusFilter == filter;
      return InkWell(
        onTap: () => notifier.setStatus(filter),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColor.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$label ($count)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? Colors.white : AppColor.textSecondary,
              )),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      child: Wrap(spacing: 4, runSpacing: 4, children: [
        tab('All', total, null),
        tab('Review Pending', counts[BalanceStatus.reviewPending] ?? 0,
            BalanceStatus.reviewPending),
        tab('Awaiting Branch', counts[BalanceStatus.branchPending] ?? 0,
            BalanceStatus.branchPending),
        tab('Accepted', counts[BalanceStatus.applied] ?? 0,
            BalanceStatus.applied),
        tab('Rejected',
            (counts[BalanceStatus.reviewerRejected] ?? 0) +
                (counts[BalanceStatus.branchRejected] ?? 0),
            null),  // rejected = union; user filters within cards
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BATCH LIST
// ─────────────────────────────────────────────────────────────
class _BatchList extends StatelessWidget {
  final BalanceReportState state;
  const _BatchList({required this.state});

  @override
  Widget build(BuildContext context) {
    // Apply search filter
    final q = state.searchQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? state.items
        : state.items.where((it) {
            final byName = it.productName.toLowerCase().contains(q);
            final bySku  = (it.productSku ?? '').toLowerCase().contains(q);
            final batch  = state.batchesById[it.batchId];
            final byBatch = batch?.batchNumber.toLowerCase().contains(q) ?? false;
            return byName || bySku || byBatch;
          }).toList();

    // Group by batch, sort by batch created_at desc
    final grouped = <String, List<BalanceItemModel>>{};
    for (final it in filtered) {
      grouped.putIfAbsent(it.batchId, () => []).add(it);
    }
    final batchIds = grouped.keys.toList()
      ..sort((a, b) {
        final ba = state.batchesById[a]?.createdAt ?? DateTime(1970);
        final bb = state.batchesById[b]?.createdAt ?? DateTime(1970);
        return bb.compareTo(ba);
      });

    if (batchIds.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: Column(children: const [
              Icon(Icons.folder_open_outlined, size: 42, color: AppColor.grey300),
              SizedBox(height: 10),
              Text('Koi batch nahi mila',
                  style: TextStyle(color: AppColor.textHint, fontSize: 13)),
            ]),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _BatchCard(
            batchId: batchIds[i],
            batch:   state.batchesById[batchIds[i]],
            items:   grouped[batchIds[i]]!,
          ),
          childCount: batchIds.length,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BATCH CARD (collapsible)
// ─────────────────────────────────────────────────────────────
class _BatchCard extends StatefulWidget {
  final String batchId;
  final BalanceBatchModel? batch;
  final List<BalanceItemModel> items;
  const _BatchCard({
    required this.batchId, required this.batch, required this.items,
  });

  @override
  State<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends State<_BatchCard> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final b = widget.batch;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b?.batchNumber ?? widget.batchId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColor.textPrimary,
                          )),
                      const SizedBox(height: 3),
                      Text(
                        b == null
                            ? 'Loading batch info…'
                            : '${_fmtDate(b.createdAt)} · by ${b.createdByName ?? '—'} · → ${b.storeId.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 11.5, color: AppColor.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CompositionBar(items: widget.items),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${widget.items.length} items',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColor.primary,
                      )),
                ),
                const SizedBox(width: 8),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18, color: AppColor.textSecondary,
                ),
              ]),
            ),
          ),
          if (_open) ...[
            const Divider(height: 1, color: AppColor.grey100),
            ...widget.items.map((it) => _ItemRow(item: it)),
          ],
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return 'Sent ${months[d.month - 1]} ${d.day}, ${h.toString()}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}

// ─────────────────────────────────────────────────────────────
// COMPOSITION BAR (batch status distribution)
// ─────────────────────────────────────────────────────────────
class _CompositionBar extends StatelessWidget {
  final List<BalanceItemModel> items;
  const _CompositionBar({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final counts = <BalanceStatus, int>{};
    for (final it in items) {
      counts[it.status] = (counts[it.status] ?? 0) + 1;
    }
    final segs = <MapEntry<BalanceStatus, int>>[
      MapEntry(BalanceStatus.applied,          counts[BalanceStatus.applied]         ?? 0),
      MapEntry(BalanceStatus.branchPending,    counts[BalanceStatus.branchPending]   ?? 0),
      MapEntry(BalanceStatus.reviewPending,    counts[BalanceStatus.reviewPending]   ?? 0),
      MapEntry(BalanceStatus.reviewerRejected, counts[BalanceStatus.reviewerRejected]?? 0),
      MapEntry(BalanceStatus.branchRejected,   counts[BalanceStatus.branchRejected]  ?? 0),
    ]..removeWhere((e) => e.value == 0);

    return Row(children: [
      const Text('Batch composition',
          style: TextStyle(
            fontSize: 10.5, color: AppColor.textSecondary,
            fontWeight: FontWeight.w600,
          )),
      const SizedBox(width: 10),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(
              children: segs.map((s) => Expanded(
                flex: s.value,
                child: Container(color: s.key.color),
              )).toList(),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// ITEM ROW (with timeline dots)
// ─────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final BalanceItemModel item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final delta = item.delta;
    final impact = item.rupeeImpact;
    final isRejected = item.status == BalanceStatus.reviewerRejected ||
        item.status == BalanceStatus.branchRejected;
    final reason = item.status == BalanceStatus.reviewerRejected
        ? item.reviewerReason
        : (item.status == BalanceStatus.branchRejected ? item.branchReason : null);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product info (flex 3)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        )),
                    if ((item.productSku ?? '').isNotEmpty)
                      Text(item.productSku!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColor.textSecondary)),
                    const SizedBox(height: 8),
                    _TimelineDots(status: item.status),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Stats
              _StatMini(label: 'SYS',  value: _fmt(item.systemStockAtCount)),
              const SizedBox(width: 20),
              _StatMini(label: 'PHY',  value: _fmt(item.physicalStock)),
              const SizedBox(width: 20),
              _StatMini(
                label: 'Δ DIFF',
                value: (delta >= 0 ? '+' : '−') + _fmt(delta.abs()),
                color: delta >= 0 ? AppColor.success : AppColor.error,
              ),
              const SizedBox(width: 20),
              _StatMini(
                label: 'NOW',
                value: item.appliedStockAfter != null
                    ? _fmt(item.appliedStockAfter!)
                    : '—',
              ),
              const SizedBox(width: 16),
              // Impact + status
              SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Valuation Impact',
                        style: TextStyle(
                          fontSize: 10, color: AppColor.textSecondary,
                          fontWeight: FontWeight.w600,
                        )),
                    Text('Rs ${impact.pkrFormat}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isRejected ? AppColor.error : AppColor.textPrimary,
                        )),
                    const SizedBox(height: 5),
                    _StatusPill(status: item.status),
                  ],
                ),
              ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.errorLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColor.error.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.cancel_outlined,
                    size: 13, color: AppColor.error),
                const SizedBox(width: 8),
                Expanded(child: RichText(
                  text: TextSpan(children: [
                    const TextSpan(text: 'Reason: ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColor.error,
                        )),
                    TextSpan(text: reason,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColor.textPrimary,
                          fontStyle: FontStyle.italic,
                        )),
                  ]),
                )),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatMini({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                color: AppColor.textSecondary,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: color ?? AppColor.textPrimary,
            )),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final BalanceStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Text(status.label,
          style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w800, color: status.color,
          )),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TIMELINE DOTS
// ─────────────────────────────────────────────────────────────
class _TimelineDots extends StatelessWidget {
  final BalanceStatus status;
  const _TimelineDots({required this.status});

  @override
  Widget build(BuildContext context) {
    // 3 stages: warehouse (always green), reviewer, branch
    Color reviewer;
    Color branch;
    IconData? reviewerIcon;
    IconData? branchIcon;

    switch (status) {
      case BalanceStatus.reviewPending:
        reviewer = AppColor.warning;
        branch   = AppColor.grey200;
        break;
      case BalanceStatus.branchPending:
        reviewer = AppColor.success;
        branch   = AppColor.warning;
        break;
      case BalanceStatus.reviewerRejected:
        reviewer = AppColor.error;
        reviewerIcon = Icons.close_rounded;
        branch   = AppColor.grey200;
        break;
      case BalanceStatus.branchRejected:
        reviewer = AppColor.success;
        branch   = AppColor.error;
        branchIcon = Icons.close_rounded;
        break;
      case BalanceStatus.applied:
        reviewer = AppColor.success;
        branch   = AppColor.success;
        break;
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      _dot(AppColor.primary),
      _seg(AppColor.primary),
      _dot(reviewer, icon: reviewerIcon),
      _seg(reviewer == AppColor.grey200 ? AppColor.grey200 : reviewer),
      _dot(branch, icon: branchIcon),
    ]);
  }

  Widget _dot(Color color, {IconData? icon}) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: icon != null ? Icon(icon, size: 8, color: Colors.white) : null,
    );
  }

  Widget _seg(Color color) => Container(
    width: 20, height: 2, color: color,
  );
}

// ═════════════════════════════════════════════════════════════
// RIGHT COLUMN — This Month + 6-Week Audit Trend
// ═════════════════════════════════════════════════════════════
class _RightColumn extends ConsumerWidget {
  const _RightColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(balanceReportProvider);

    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(0, 22, 24, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ThisMonthSummary(items: state.items),
            const SizedBox(height: 14),
            _WeeklyAuditTrend(items: state.items),
          ],
        ),
      ),
    );
  }
}

class _ThisMonthSummary extends StatelessWidget {
  final List<BalanceItemModel> items;
  const _ThisMonthSummary({required this.items});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final thisMonth = items.where((it) => it.createdAt.isAfter(monthStart)).toList();
    double netImpact = 0;
    int resolved = 0;
    int applied = 0;
    Duration totalTurnaround = Duration.zero;
    int turnaroundCount = 0;
    for (final it in thisMonth) {
      netImpact += it.rupeeImpact;
      if (it.status == BalanceStatus.applied) applied++;
      if (it.status.isTerminal) resolved++;
      if (it.appliedAt != null) {
        totalTurnaround += it.appliedAt!.difference(it.createdAt);
        turnaroundCount++;
      }
    }
    final resolutionRate = thisMonth.isEmpty
        ? 0.0 : (resolved * 100.0 / thisMonth.length);
    final avgHrs = turnaroundCount == 0
        ? null
        : (totalTurnaround.inMinutes / turnaroundCount) / 60.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(
              child: Text('This Month Summary',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  )),
            ),
            Text(_monthLabel(now),
                style: const TextStyle(
                  fontSize: 11, color: AppColor.textSecondary,
                  fontWeight: FontWeight.w700,
                )),
          ]),
          const SizedBox(height: 14),
          const Text('TOTAL DISCREPANCY NET IMPACT',
              style: TextStyle(
                fontSize: 10, letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColor.textSecondary,
              )),
          const SizedBox(height: 4),
          Text('Rs ${netImpact.pkrFormat}',
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900,
                color: AppColor.textPrimary,
              )),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _MiniStatBox(
              label: 'Resolution Rate',
              value: '${resolutionRate.toStringAsFixed(1)}%',
              color: AppColor.success,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatBox(
              label: 'Avg. Turnaround',
              value: avgHrs == null
                  ? '—'
                  : avgHrs < 24
                      ? '${avgHrs.toStringAsFixed(1)} hrs'
                      : '${(avgHrs / 24).toStringAsFixed(1)} days',
              color: AppColor.primary,
            )),
          ]),
        ],
      ),
    );
  }

  String _monthLabel(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.year}';
  }
}

class _MiniStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 10.5, color: AppColor.textSecondary,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: color,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 6-WEEK AUDIT TREND — simple stacked bars
// ─────────────────────────────────────────────────────────────
class _WeeklyAuditTrend extends StatelessWidget {
  final List<BalanceItemModel> items;
  const _WeeklyAuditTrend({required this.items});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    // Last 6 weeks
    final buckets = List.generate(6, (i) {
      final ws = weekStart.subtract(Duration(days: 7 * (5 - i)));
      return (weekStart: ws, accepted: 0, rejected: 0);
    });
    final list = List<({DateTime weekStart, int accepted, int rejected})>.from(buckets);
    for (final it in items) {
      for (int i = 0; i < list.length; i++) {
        final ws = list[i].weekStart;
        final we = ws.add(const Duration(days: 7));
        if (it.createdAt.isAfter(ws.subtract(const Duration(seconds: 1))) &&
            it.createdAt.isBefore(we)) {
          if (it.status == BalanceStatus.applied) {
            list[i] = (weekStart: ws, accepted: list[i].accepted + 1,
                rejected: list[i].rejected);
          } else if (it.status == BalanceStatus.reviewerRejected ||
                     it.status == BalanceStatus.branchRejected) {
            list[i] = (weekStart: ws, accepted: list[i].accepted,
                rejected: list[i].rejected + 1);
          }
          break;
        }
      }
    }

    final maxVal = list.fold<int>(0,
        (m, b) => (b.accepted + b.rejected) > m ? (b.accepted + b.rejected) : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Expanded(
              child: Text('6-Week Audit Trend',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  )),
            ),
            _LegendDot(color: AppColor.success, label: 'Accepted'),
            SizedBox(width: 10),
            _LegendDot(color: AppColor.error, label: 'Rejected'),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(list.length, (i) {
                final b = list[i];
                final total = b.accepted + b.rejected;
                final ratio = maxVal == 0 ? 0.0 : total / maxVal;
                final accRatio = total == 0 ? 0.0 : b.accepted / total;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 90 * ratio,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(children: [
                            Expanded(
                              flex: (1000 * (1 - accRatio)).round(),
                              child: Container(color: AppColor.error),
                            ),
                            Expanded(
                              flex: (1000 * accRatio).round(),
                              child: Container(color: AppColor.success),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 5),
                        Text('W${i + 1}',
                            style: const TextStyle(
                              fontSize: 10, color: AppColor.textSecondary,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppColor.textSecondary,
              fontWeight: FontWeight.w700)),
    ]);
  }
}
