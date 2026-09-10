// =============================================================
// review_queue_panel.dart
// Reviewer's Tab 1 — items with status='review_pending', grouped
// by batch (batch header + items with Accept/Reject buttons).
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_batch_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/presentation/widgets/balance_widgets.dart';

import '../provider/inventory_review_provider.dart';
import 'reject_reason_dialog.dart';

class ReviewQueuePanel extends ConsumerWidget {
  const ReviewQueuePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(reviewQueueProvider);
    final notifier = ref.read(reviewQueueProvider.notifier);

    // Error snackbar
    ref.listen<ReviewQueueState>(reviewQueueProvider, (prev, next) {
      if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColor.error,
            behavior: SnackBarBehavior.floating,
          ));
      }
    });

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.done_all_rounded, size: 42, color: AppColor.grey300),
            SizedBox(height: 10),
            Center(child: Text('Koi item review ke liye pending nahi',
                style: TextStyle(color: AppColor.textHint, fontSize: 13))),
          ],
        ),
      );
    }

    // Group items by batch — sorted by batch created_at desc (latest first)
    final grouped = <String, List<BalanceItemModel>>{};
    for (final it in state.items) {
      grouped.putIfAbsent(it.batchId, () => []).add(it);
    }
    final batchIds = grouped.keys.toList()
      ..sort((a, b) {
        final ba = state.batchById[a];
        final bb = state.batchById[b];
        final da = ba?.createdAt ?? DateTime(1970);
        final db = bb?.createdAt ?? DateTime(1970);
        return db.compareTo(da);
      });

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: batchIds.length,
        itemBuilder: (_, i) {
          final bid   = batchIds[i];
          final items = grouped[bid]!;
          final batch = state.batchById[bid];
          return _BatchGroupCard(batch: batch, items: items);
        },
      ),
    );
  }
}

class _BatchGroupCard extends ConsumerWidget {
  final BalanceBatchModel? batch;
  final List<BalanceItemModel> items;
  const _BatchGroupCard({required this.batch, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.grey200),
      ),
      child: Column(
        children: [
          // Batch header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColor.grey100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.folder_open_rounded,
                      size: 16, color: AppColor.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(batch?.batchNumber ?? 'Batch',
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary)),
                      if (batch != null)
                        Text('${batch!.createdByName ?? '—'}  ·  ${batch!.createdAt.timeAgo}',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColor.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${items.length} items',
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary)),
                ),
              ],
            ),
          ),
          // Items
          ...items.map((it) => _ReviewItemRow(item: it)),
        ],
      ),
    );
  }
}

class _ReviewItemRow extends ConsumerWidget {
  final BalanceItemModel item;
  const _ReviewItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(reviewQueueProvider);
    final notifier = ref.read(reviewQueueProvider.notifier);
    final acting   = state.actingItemIds.contains(item.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColor.grey100)),
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
              if (item.isHighVariance)
                HighVarianceBadge(rupeeImpact: item.rupeeImpact),
            ],
          ),
          const SizedBox(height: 8),
          FourNumberRow(
            systemAtCount: item.systemStockAtCount,
            physical:      item.physicalStock,
            delta:         item.delta,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Impact: Rs ${item.rupeeImpact.pkrFormat}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColor.textSecondary)),
              const Spacer(),
              _ActionButton(
                icon: Icons.close_rounded,
                label: 'Reject',
                color: AppColor.error,
                enabled: !acting,
                onTap: () async {
                  final reason = await RejectReasonDialog.show(
                    context,
                    title: 'Item Reject',
                    productName: item.productName,
                  );
                  if (reason != null) {
                    await notifier.rejectItem(item, reason);
                  }
                },
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.check_rounded,
                label: 'Accept',
                color: AppColor.success,
                enabled: !acting,
                loading: acting,
                onTap: () => notifier.acceptItem(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final bool     enabled;
  final bool     loading;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (loading)
              SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ]),
        ),
      ),
    );
  }
}
