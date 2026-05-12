// lib/features/branch/sale_invoice/presentation/widget/held_invoices_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/held_invoice_model.dart';
import '../provider/held_invoice_provider.dart';
import '../provider/sale_invoice_provider.dart';

/// Show held invoices dialog (F4 or Hold button)
Future<void> showHeldInvoicesSheet(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    builder: (_) => const _HeldInvoicesDialog(),
  );
}

class _HeldInvoicesDialog extends ConsumerWidget {
  const _HeldInvoicesDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holds   = ref.watch(heldInvoicesProvider);
    final timeFmt = DateFormat('hh:mm a');

    final double grandTotal = holds.fold(0, (sum, h) => sum + h.grandTotal);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: SizedBox(
        width:  480,
        height: 540,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Row(
                children: [
                  Container(
                    width:  40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:        const Color(0xFFFAEEDA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.pause_circle_outline_rounded,
                          color: Color(0xFFBA7517), size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Held Invoices',
                        style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.w600,
                          color:      AppColor.textPrimary,
                        ),
                      ),
                      Text(
                        '${holds.length} invoice${holds.length == 1 ? '' : 's'} on hold',
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (holds.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor:
                        AppColor.errorLight.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9)),
                      ),
                      onPressed: () => _confirmDiscardAll(context, ref),
                      icon: const Icon(Icons.delete_sweep_outlined,
                          size: 15, color: AppColor.error),
                      label: const Text(
                        'Discard All',
                        style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w500,
                            color:      AppColor.error),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Divider(color: AppColor.grey200, height: 1, thickness: 0.5),

            // ── List ──────────────────────────────────────────────
            Expanded(
              child: holds.isEmpty
                  ? const _EmptyHolds()
                  : ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: holds.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _HoldCard(
                  hold:    holds[i],
                  timeFmt: timeFmt,
                  onResume: () {
                    Navigator.pop(context);
                    ref
                        .read(saleInvoiceProvider.notifier)
                        .resumeHeldInvoice(holds[i]);
                  },
                  onDiscard: () =>
                      _confirmDiscard(context, ref, holds[i]),
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────
            if (holds.isNotEmpty) ...[
              const Divider(
                  color: AppColor.grey200, height: 1, thickness: 0.5),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'F4 = view  •  F3 = new hold',
                      style: TextStyle(
                          fontSize: 11, color: AppColor.textHint),
                    ),
                    Text(
                      'Total: Rs ${grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Confirm single discard ─────────────────────────────────────
  void _confirmDiscard(
      BuildContext context, WidgetRef ref, HeldInvoice hold) {
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        titlePadding:   const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: const Text(
          'Discard Invoice?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '"${hold.displayLabel}" will be permanently deleted.',
          style: const TextStyle(
              fontSize: 13, color: AppColor.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel',
                style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
              elevation:       0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
            ),
            onPressed: () {
              ref
                  .read(heldInvoicesProvider.notifier)
                  .releaseHold(hold.id, discard: true);
              Navigator.pop(d);
            },
            child: const Text('Discard',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Confirm discard all ────────────────────────────────────────
  void _confirmDiscardAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        titlePadding:   const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: const Text(
          'Discard All Holds?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'All held invoices will be permanently deleted.',
          style: TextStyle(fontSize: 13, color: AppColor.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel',
                style: TextStyle(color: AppColor.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              foregroundColor: Colors.white,
              elevation:       0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
            ),
            onPressed: () {
              final holds = ref.read(heldInvoicesProvider);
              for (final h in holds) {
                ref
                    .read(heldInvoicesProvider.notifier)
                    .releaseHold(h.id, discard: true);
              }
              Navigator.pop(d);       // close confirm dialog
              Navigator.pop(context); // close held invoices dialog
            },
            child: const Text('Discard All',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Hold Card ──────────────────────────────────────────────────────
class _HoldCard extends StatelessWidget {
  final HeldInvoice  hold;
  final DateFormat   timeFmt;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _HoldCard({
    required this.hold,
    required this.timeFmt,
    required this.onResume,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFFAC775), width: 0.5),
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────────
          Container(
            width:  42,
            height: 42,
            decoration: BoxDecoration(
              color:        const Color(0xFFFAEEDA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                hold.shortLabel.isNotEmpty
                    ? hold.shortLabel[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize:   17,
                  fontWeight: FontWeight.w600,
                  color:      Color(0xFFBA7517),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Info ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hold.displayLabel,
                  style: const TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                    color:      AppColor.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: AppColor.textHint),
                    const SizedBox(width: 3),
                    Text(
                      timeFmt.format(hold.heldAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.textHint),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.shopping_bag_outlined,
                        size: 11, color: AppColor.textHint),
                    const SizedBox(width: 3),
                    Text(
                      '${hold.cartItems.length} item${hold.cartItems.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Amount + Actions ─────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${hold.grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w600,
                  color:      Color(0xFFBA7517),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Discard button
                  InkWell(
                    onTap:        onDiscard,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width:  30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColor.errorLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColor.error.withOpacity(0.25),
                            width: 0.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.delete_outline,
                            size: 14, color: AppColor.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Resume button
                  // Fix: removed SizedBox(height:30) wrapper — it caused
                  // BoxConstraints(w=Infinity, h=30) crash.
                  // Use minimumSize + tapTargetSize.shrinkWrap instead.
                  ElevatedButton.icon(
                    onPressed: onResume,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.textPrimary,
                      foregroundColor: Colors.white,
                      elevation:       0,
                      minimumSize:     const Size(0, 30),
                      tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded,
                        size: 13, color: Colors.white),
                    label: const Text(
                      'Resume',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────
class _EmptyHolds extends StatelessWidget {
  const _EmptyHolds();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty_rounded,
              size: 36, color: AppColor.grey300),
          SizedBox(height: 10),
          Text(
            'No held invoices',
            style: TextStyle(
              fontSize:   14,
              fontWeight: FontWeight.w600,
              color:      AppColor.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Press F3 to hold an invoice',
            style: TextStyle(fontSize: 12, color: AppColor.textHint),
          ),
        ],
      ),
    );
  }
}