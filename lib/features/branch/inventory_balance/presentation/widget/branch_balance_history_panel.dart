// =============================================================
// branch_balance_history_panel.dart
// Branch's Tab 2 — this store's items (any status), date-filtered.
// Read-only data table, koi action nahi.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/domain/balance_status.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/presentation/widgets/balance_widgets.dart';

import '../provider/branch_inventory_balance_provider.dart';

const _kHeaderH = 42.0;
const _kRowH    = 68.0;

const _kWidths = <double>[
  240, // Product
  90,  // System
  90,  // Physical
  90,  // Delta
  130, // Impact
  160, // Status
  260, // Reason
  180, // Applied
];

const _kHeaders = <String>[
  'Product', 'System', 'Physical', 'Delta', 'Impact', 'Status', 'Reason', 'Applied',
];

double get _kTableWidth => _kWidths.fold(0.0, (s, w) => s + w) + 32;

class BranchBalanceHistoryPanel extends ConsumerWidget {
  const BranchBalanceHistoryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(branchBalanceHistoryProvider);
    final notifier = ref.read(branchBalanceHistoryProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FiltersRow(state: state, notifier: notifier),
          const SizedBox(height: 10),
          _StatusChips(items: state.items),
          const SizedBox(height: 12),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : state.errorMessage != null
                    ? Center(child: Text(state.errorMessage!,
                        style: const TextStyle(color: AppColor.error, fontSize: 12)))
                    : state.items.isEmpty
                        ? const Center(child: Text('Koi record nahi',
                            style: TextStyle(color: AppColor.textHint)))
                        : _HistoryTable(items: state.items),
          ),
        ],
      ),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  final BranchBalanceHistoryState state;
  final BranchBalanceHistoryNotifier notifier;
  const _FiltersRow({required this.state, required this.notifier});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
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
              helpText:  'Select date range',
              saveText:  'Apply',
            );
            if (picked != null) notifier.setDateRange(picked.start, picked.end);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.grey200),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.date_range_rounded, size: 14, color: AppColor.textSecondary),
              const SizedBox(width: 6),
              Text(
                (state.fromDate != null && state.toDate != null)
                    ? '${_fmtDate(state.fromDate!)} – ${_fmtDate(state.toDate!)}'
                    : 'Date range',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
              ),
            ]),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColor.grey200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.statusFilter?.code ?? '_all',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem(value: '_all', child: Text('All statuses')),
                ...BalanceStatus.values.map((s) => DropdownMenuItem(
                  value: s.code, child: Text(s.label),
                )),
              ],
              onChanged: (v) {
                if (v == null || v == '_all') {
                  notifier.setStatus(null);
                } else {
                  notifier.setStatus(BalanceStatus.fromCode(v));
                }
              },
            ),
          ),
        ),
        InkWell(
          onTap: notifier.refresh,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.primary.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.refresh_rounded, size: 14, color: AppColor.primary),
              SizedBox(width: 6),
              Text('Refresh',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.primary,
                  )),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StatusChips extends StatelessWidget {
  final List<BalanceItemModel> items;
  const _StatusChips({required this.items});

  @override
  Widget build(BuildContext context) {
    final counts = <BalanceStatus, int>{};
    for (final it in items) {
      counts[it.status] = (counts[it.status] ?? 0) + 1;
    }
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: BalanceStatus.values.map((s) {
        final n = counts[s] ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: s.bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: s.color.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(s.label, style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w700, color: s.color,
            )),
            const SizedBox(width: 5),
            Text('$n', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: s.color,
            )),
          ]),
        );
      }).toList(),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  final List<BalanceItemModel> items;
  const _HistoryTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final tableWidth = _kTableWidth.clamp(constraints.maxWidth, double.infinity);

      return Container(
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.grey200),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                Container(
                  height:  _kHeaderH,
                  color:   AppColor.grey100,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(_kHeaders.length, (i) {
                      return SizedBox(
                        width: _kWidths[i],
                        child: Text(
                          _kHeaders[i],
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textSecondary),
                        ),
                      );
                    }),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (_, i) => _HistoryRow(item: items[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _HistoryRow extends StatelessWidget {
  final BalanceItemModel item;
  const _HistoryRow({required this.item});

  String _fmtNum(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  String? get _reason {
    if (item.branchReason != null && item.branchReason!.isNotEmpty) {
      return 'Branch: ${item.branchReason}';
    }
    if (item.reviewerReason != null && item.reviewerReason!.isNotEmpty) {
      return 'Reviewer: ${item.reviewerReason}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final reason = _reason;
    return Container(
      height: _kRowH,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Product
          SizedBox(
            width: _kWidths[0],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary)),
                if ((item.productSku ?? '').isNotEmpty)
                  Text(item.productSku!,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: AppColor.textSecondary)),
              ],
            ),
          ),
          // System
          SizedBox(
            width: _kWidths[1],
            child: Text(_fmtNum(item.systemStockAtCount),
                style: const TextStyle(fontSize: 12.5, color: AppColor.textPrimary)),
          ),
          // Physical
          SizedBox(
            width: _kWidths[2],
            child: Text(_fmtNum(item.physicalStock),
                style: const TextStyle(fontSize: 12.5, color: AppColor.textPrimary)),
          ),
          // Delta
          SizedBox(
            width: _kWidths[3],
            child: DeltaText(delta: item.delta, fontSize: 12.5),
          ),
          // Impact
          SizedBox(
            width: _kWidths[4],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rs ${item.rupeeImpact.pkrFormat}',
                    style: const TextStyle(fontSize: 12, color: AppColor.textPrimary)),
                if (item.isHighVariance) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColor.errorLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('HIGH',
                        style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w800, color: AppColor.error)),
                  ),
                ],
              ],
            ),
          ),
          // Status
          SizedBox(
            width: _kWidths[5],
            child: BalanceStatusBadge(status: item.status),
          ),
          // Reason
          SizedBox(
            width: _kWidths[6],
            child: reason == null
                ? const Text('—', style: TextStyle(fontSize: 12, color: AppColor.textHint))
                : Tooltip(
                    message: reason,
                    child: Text(reason,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                  ),
          ),
          // Applied
          SizedBox(
            width: _kWidths[7],
            child: (item.status == BalanceStatus.applied &&
                    item.appliedStockBefore != null &&
                    item.appliedStockAfter != null)
                ? Text(
                    '${_fmtNum(item.appliedStockBefore!)} → ${_fmtNum(item.appliedStockAfter!)}',
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColor.success),
                  )
                : const Text('—', style: TextStyle(fontSize: 12, color: AppColor.textHint)),
          ),
        ],
      ),
    );
  }
}
