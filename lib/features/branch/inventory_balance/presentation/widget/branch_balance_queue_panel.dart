// =============================================================
// branch_balance_queue_panel.dart
// Branch's Tab 1 — items with status='branch_pending', flat data
// table (batch column instead of grouped cards). Accept applies
// DELTA to live branch stock (§7.4).
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/accountant/accountant_inventory_review/presentation/widget/reject_reason_dialog.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_batch_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/data/model/balance_item_model.dart';
import 'package:jan_ghani_final/features/warehouse/inventory_balance/presentation/widgets/balance_widgets.dart';

import '../provider/branch_inventory_balance_provider.dart';

const _kHeaderH = 42.0;
const _kRowH    = 64.0;

const _kWidths = <double>[
  260, // Product
  150, // Batch
  90,  // System
  90,  // Physical
  90,  // Delta
  150, // Impact
  200, // Actions
];

const _kHeaders = <String>[
  'Product', 'Batch', 'System', 'Physical', 'Delta', 'Impact', 'Actions',
];

double get _kTableWidth => _kWidths.fold(0.0, (s, w) => s + w) + 32;

class BranchBalanceQueuePanel extends ConsumerWidget {
  const BranchBalanceQueuePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(branchBalanceQueueProvider);
    final notifier = ref.read(branchBalanceQueueProvider.notifier);

    ref.listen<BranchBalanceQueueState>(branchBalanceQueueProvider, (prev, next) {
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Toolbar(
            count: state.items.length,
            totalImpact: state.items.fold(0.0, (s, i) => s + i.rupeeImpact),
            onRefresh: notifier.refresh,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.items.isEmpty
                ? RefreshIndicator(
                    onRefresh: notifier.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Icon(Icons.done_all_rounded, size: 42, color: AppColor.grey300),
                        SizedBox(height: 10),
                        Center(child: Text('Koi stock adjustment pending nahi',
                            style: TextStyle(color: AppColor.textHint, fontSize: 13))),
                      ],
                    ),
                  )
                : _QueueTable(
                    items:     state.items,
                    batchById: state.batchById,
                    acting:    state.actingItemIds,
                    onRefresh: notifier.refresh,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final int    count;
  final double totalImpact;
  final Future<void> Function() onRefresh;
  const _Toolbar({required this.count, required this.totalImpact, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon:  Icons.pending_actions_rounded,
          label: '$count pending',
          color: AppColor.warning,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon:  Icons.payments_outlined,
          label: 'Impact Rs ${totalImpact.pkrFormat}',
          color: AppColor.primary,
        ),
        const Spacer(),
        InkWell(
          onTap: onRefresh,
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
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.primary)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _QueueTable extends StatelessWidget {
  final List<BalanceItemModel> items;
  final Map<String, BalanceBatchModel> batchById;
  final Set<String> acting;
  final Future<void> Function() onRefresh;
  const _QueueTable({
    required this.items, required this.batchById,
    required this.acting, required this.onRefresh,
  });

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
                      final isLast = i == _kHeaders.length - 1;
                      return SizedBox(
                        width: _kWidths[i],
                        child: Text(
                          _kHeaders[i],
                          textAlign: isLast ? TextAlign.center : TextAlign.left,
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
                    itemBuilder: (_, i) => _QueueRow(
                      item:   items[i],
                      batch:  batchById[items[i].batchId],
                      acting: acting.contains(items[i].id),
                    ),
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

class _QueueRow extends ConsumerWidget {
  final BalanceItemModel item;
  final BalanceBatchModel? batch;
  final bool acting;
  const _QueueRow({required this.item, required this.batch, required this.acting});

  String _fmtNum(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  Future<bool> _confirmApply(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stock Adjust Karein?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text(
          '${item.productName}\n\n'
          'Delta ${item.delta >= 0 ? '+' : ''}${item.delta.toStringAsFixed(0)} '
          'aapki live stock mein apply hoga. Yeh action wapas nahi ho sakta.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Haan, Apply Karo'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(branchBalanceQueueProvider.notifier);

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
          // Batch
          SizedBox(
            width: _kWidths[1],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch?.batchNumber ?? '—',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary)),
                if (batch != null)
                  Text(batch!.createdAt.timeAgo,
                      style: const TextStyle(fontSize: 10, color: AppColor.textSecondary)),
              ],
            ),
          ),
          // System
          SizedBox(
            width: _kWidths[2],
            child: Text(_fmtNum(item.systemStockAtCount),
                style: const TextStyle(fontSize: 12.5, color: AppColor.textPrimary)),
          ),
          // Physical
          SizedBox(
            width: _kWidths[3],
            child: Text(_fmtNum(item.physicalStock),
                style: const TextStyle(fontSize: 12.5, color: AppColor.textPrimary)),
          ),
          // Delta
          SizedBox(
            width: _kWidths[4],
            child: DeltaText(delta: item.delta, fontSize: 12.5),
          ),
          // Impact
          SizedBox(
            width: _kWidths[5],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rs ${item.rupeeImpact.pkrFormat}',
                    style: const TextStyle(fontSize: 12, color: AppColor.textPrimary)),
                if (item.isHighVariance) ...[
                  const SizedBox(height: 3),
                  const _HighBadge(),
                ],
              ],
            ),
          ),
          // Actions
          SizedBox(
            width: _kWidths[6],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  onTap: () async {
                    final ok = await _confirmApply(context);
                    if (ok) await notifier.acceptItem(item);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighBadge extends StatelessWidget {
  const _HighBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColor.errorLight,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.warning_amber_rounded, size: 10, color: AppColor.error),
      SizedBox(width: 3),
      Text('HIGH',
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800, color: AppColor.error)),
    ]),
  );
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
              Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ]),
        ),
      ),
    );
  }
}
