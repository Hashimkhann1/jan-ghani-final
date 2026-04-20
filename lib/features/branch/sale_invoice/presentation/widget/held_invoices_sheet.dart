// lib/features/branch/sale_invoice/presentation/widget/held_invoices_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/color/app_color.dart';
import '../../data/model/held_invoice_model.dart';
import '../provider/held_invoice_provider.dart';
import '../provider/sale_invoice_provider.dart';

/// F4 ya Hold button daba ke held invoices dialog show karo
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width:      500,
        height:     520,
        child: Column(children: [
          const SizedBox(height: 4),

          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        AppColor.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pause_circle_outline_rounded,
                    color: AppColor.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Held Invoices',
                    style: TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.w800,
                        color:      AppColor.textPrimary)),
                Text('${holds.length} invoice hold mein hai',
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textSecondary)),
              ]),
              const Spacer(),
              if (holds.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _confirmDiscardAll(context, ref),
                  icon:  const Icon(Icons.delete_sweep_outlined,
                      size: 16, color: AppColor.error),
                  label: const Text('Sab hatao',
                      style: TextStyle(fontSize: 12, color: AppColor.error)),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColor.grey200, height: 1),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: holds.isEmpty
                ? _EmptyHolds()
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount:   holds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _HoldCard(
                hold:    holds[i],
                timeFmt: timeFmt,
                onResume: () {
                  Navigator.pop(context);
                  ref
                      .read(saleInvoiceProvider.notifier)
                      .resumeHeldInvoice(holds[i]);
                },
                onDiscard: () => _confirmDiscard(context, ref, holds[i]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmDiscard(
      BuildContext context, WidgetRef ref, HeldInvoice hold) {
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title:   const Text('Invoice Discard?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('"${hold.displayLabel}" permanently delete ho jayega.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              ref.read(heldInvoicesProvider.notifier)
                  .releaseHold(hold.id, discard: true);
              Navigator.pop(d);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _confirmDiscardAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title:   const Text('Sab Holds Hatao?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Saare held invoices permanently delete ho jayenge.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.error,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              final holds = ref.read(heldInvoicesProvider);
              for (final h in holds) {
                ref.read(heldInvoicesProvider.notifier)
                    .releaseHold(h.id, discard: true);
              }
              Navigator.pop(d);      // confirm dialog close
              Navigator.pop(context); // held invoices dialog close
            },
            child: const Text('Sab Hatao'),
          ),
        ],
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColor.warning.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color:  AppColor.warning.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        // ── Icon ────────────────────────────────────────────────
        Container(
          width:  44, height: 44,
          decoration: BoxDecoration(
            color:        AppColor.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              hold.shortLabel.isNotEmpty
                  ? hold.shortLabel[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w800,
                  color:      AppColor.warning),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ── Info ─────────────────────────────────────────────────
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hold.displayLabel,
                    style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                        color:      AppColor.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.access_time_rounded,
                      size: 11, color: AppColor.textHint),
                  const SizedBox(width: 3),
                  Text(timeFmt.format(hold.heldAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.textHint)),
                  const SizedBox(width: 10),
                  const Icon(Icons.shopping_bag_outlined,
                      size: 11, color: AppColor.textHint),
                  const SizedBox(width: 3),
                  Text('${hold.cartItems.length} items',
                      style: const TextStyle(
                          fontSize: 11, color: AppColor.textHint)),
                ]),
              ]),
        ),

        // ── Amount ───────────────────────────────────────────────
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            'Rs ${hold.grandTotal.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w800,
                color:      AppColor.warning),
          ),
          const SizedBox(height: 8),
          Row(children: [
            // Discard
            GestureDetector(
              onTap: onDiscard,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:        AppColor.errorLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(7),
                  border:       Border.all(color: AppColor.error.withOpacity(0.3)),
                ),
                child: const Icon(Icons.delete_outline,
                    size: 14, color: AppColor.error),
              ),
            ),
            const SizedBox(width: 6),
            // Resume
            GestureDetector(
              onTap: onResume,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:        AppColor.primary,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Row(children: [
                  Icon(Icons.play_arrow_rounded,
                      size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Resume',
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color:      Colors.white)),
                ]),
              ),
            ),
          ]),
        ]),
      ]),
    );
  }
}

class _EmptyHolds extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.hourglass_empty_rounded,
            size: 40, color: AppColor.grey300),
        SizedBox(height: 10),
        Text('Koi held invoice nahi',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:    AppColor.textSecondary)),
        SizedBox(height: 4),
        Text('F3 dabao invoice hold karne ke liye',
            style: TextStyle(fontSize: 12, color: AppColor.textHint)),
      ],
    ),
  );
}