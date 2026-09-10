// =============================================================
// review_history_panel.dart
// Reviewer's Tab 2 — all items (any status), date-filtered.
// Read-only display, koi action nahi.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/domain/balance_status.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/presentation/widgets/balance_widgets.dart';

import '../provider/inventory_review_provider.dart';

class ReviewHistoryPanel extends ConsumerWidget {
  const ReviewHistoryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(reviewHistoryProvider);
    final notifier = ref.read(reviewHistoryProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FiltersRow(state: state, notifier: notifier),
          const SizedBox(height: 10),
          _StatusChips(items: state.items),
          const SizedBox(height: 10),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : state.errorMessage != null
                    ? Center(child: Text(state.errorMessage!,
                        style: const TextStyle(color: AppColor.error, fontSize: 12)))
                    : state.items.isEmpty
                        ? const Center(child: Text('Koi record nahi',
                            style: TextStyle(color: AppColor.textHint)))
                        : RefreshIndicator(
                            onRefresh: notifier.refresh,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: state.items.length,
                              itemBuilder: (_, i) => _HistoryRow(item: state.items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  final ReviewHistoryState state;
  final ReviewHistoryNotifier notifier;
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

class _HistoryRow extends StatelessWidget {
  final BalanceItemModel item;
  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary)),
                    if ((item.productSku ?? '').isNotEmpty)
                      Text(item.productSku!,
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColor.textSecondary)),
                  ],
                ),
              ),
              BalanceStatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 8),
          FourNumberRow(
            systemAtCount: item.systemStockAtCount,
            physical:      item.physicalStock,
            delta:         item.delta,
          ),
          const SizedBox(height: 6),
          Row(children: [
            if (item.isHighVariance) HighVarianceBadge(rupeeImpact: item.rupeeImpact),
            const Spacer(),
            Text('Impact: Rs ${item.rupeeImpact.pkrFormat}',
                style: const TextStyle(
                    fontSize: 10.5, color: AppColor.textSecondary)),
          ]),
          if (item.reviewerReason != null && item.reviewerReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _ReasonLine(icon: Icons.rate_review_outlined, label: 'Reviewer', text: item.reviewerReason!),
          ],
          if (item.branchReason != null && item.branchReason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _ReasonLine(icon: Icons.store_outlined, label: 'Branch', text: item.branchReason!),
          ],
        ],
      ),
    );
  }
}

class _ReasonLine extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   text;
  const _ReasonLine({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 12, color: AppColor.textSecondary),
      const SizedBox(width: 6),
      Text('$label: ', style: const TextStyle(
        fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColor.textSecondary,
      )),
      Expanded(child: Text(text,
        style: const TextStyle(fontSize: 10.5, color: AppColor.textPrimary),
        maxLines: 2, overflow: TextOverflow.ellipsis,
      )),
    ]);
  }
}
