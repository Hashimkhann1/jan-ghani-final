// Updated on 2026-11-16 09:59 AM
// =============================================================
// branch_return_detail_dialog.dart — ek return ki poori detail
//
//   • Header: return no, branch, bhejne wala, date, note, totals
//   • Items table: product, SKU, unit, qty, purchase price, line total
//     — pending par har product ki local halat (deleted / missing =
//     laal message; aisi line ho to Accept band, sirf Reject)
//   • Pending: Accept (confirm) · Reject (reason lazmi)
//   • Accepted / Rejected: kisne, kab, wajah — koi button nahi
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/warehouse_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';

import '../../domain/branch_return_model.dart';
import '../provider/branch_returns_provider.dart';
import 'branch_return_parts.dart';

class BranchReturnDetailDialog extends ConsumerStatefulWidget {
  final BranchReturn ret;
  const BranchReturnDetailDialog({super.key, required this.ret});

  /// Action hua to uska nateeja, warna null.
  static Future<ReturnActionResult?> show(
      BuildContext context, BranchReturn ret) {
    return showDialog<ReturnActionResult>(
      context: context,
      builder: (_) => BranchReturnDetailDialog(ret: ret),
    );
  }

  @override
  ConsumerState<BranchReturnDetailDialog> createState() =>
      _BranchReturnDetailDialogState();
}

class _BranchReturnDetailDialogState
    extends ConsumerState<BranchReturnDetailDialog> {
  late BranchReturn _ret = widget.ret;
  bool _reloading = false;

  // Items abhi nahi aaye the (header ke foran baad khula) → taaza lao
  Future<void> _reload() async {
    setState(() => _reloading = true);
    try {
      final fresh =
          await ref.read(branchReturnRemoteProvider).fetchById(_ret.id);
      if (mounted && fresh != null) setState(() => _ret = fresh);
    } catch (_) {
      // banner wahi rehta hai
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  Future<void> _accept() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Return accept karein?',
        body: '${_ret.items.length} products · qty ${fmtReturnQty(_ret.itemsQty)} '
            'warehouse stock mein add ho jayegi.\n'
            'Ye kaam wapas nahi hota.',
        confirmLabel: 'Haan, Accept',
        color: WarehouseAppColor.success,
      ),
    );
    if (ok != true || !mounted) return;
    final res = await ref.read(branchReturnsProvider.notifier).accept(_ret);
    if (mounted) Navigator.of(context).pop(res);
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectReasonDialog(),
    );
    if (reason == null || !mounted) return;
    final res =
        await ref.read(branchReturnsProvider.notifier).reject(_ret, reason);
    if (mounted) Navigator.of(context).pop(res);
  }

  @override
  Widget build(BuildContext context) {
    final r    = _ret;
    final busy = ref.watch(
        branchReturnsProvider.select((s) => s.busyIds.contains(r.id)));

    // Product halat sirf pending par (accept ka faisla isi par)
    final statusAsync = r.isPending && r.items.isNotEmpty
        ? ref.watch(returnProductStatusProvider(r))
        : null;
    final status = statusAsync?.valueOrNull ?? const {};
    final issues = status.values
        .where((s) => s != ReturnProductStatus.ok)
        .length;

    final size = MediaQuery.of(context).size;

    String? blockReason;
    if (r.isPending) {
      if (!r.itemsComplete) {
        blockReason = 'Return ke items abhi poore nahi aaye — Refresh karein';
      } else if (statusAsync == null || statusAsync.isLoading) {
        blockReason = 'Products check ho rahe hain…';
      } else if (statusAsync.hasError) {
        blockReason = 'Products check nahi ho sake (local DB) — dobara kholein';
      } else if (issues > 0) {
        blockReason = '$issues product delete hain ya warehouse mein nahi — '
            'Accept nahi ho sakta, sirf Reject karein';
      }
    }

    return Dialog(
      backgroundColor: WarehouseAppColor.surface,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: 940, maxHeight: size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DialogHeader(ret: r, onClose: busy ? null : () => Navigator.pop(context)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoGrid(ret: r),
                    if ((r.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NoteBox(
                        icon:  Icons.sticky_note_2_outlined,
                        title: 'Branch ka note',
                        text:  r.notes!.trim(),
                        color: WarehouseAppColor.info,
                      ),
                    ],
                    if (!r.isPending) ...[
                      const SizedBox(height: 12),
                      _ResponseBox(ret: r),
                    ],
                    if (r.isPending && !r.itemsComplete) ...[
                      const SizedBox(height: 12),
                      _NoteBox(
                        icon:  Icons.hourglass_top_rounded,
                        title: 'Items abhi poore nahi aaye',
                        text:  'Branch abhi bhej rahi hogi. Thori der baad Refresh karein.',
                        color: WarehouseAppColor.warningDark,
                        action: TextButton.icon(
                          onPressed: _reloading ? null : _reload,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Refresh'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _ItemsTable(ret: r, status: status),
                  ],
                ),
              ),
            ),
            if (r.isPending)
              _ActionBar(
                busy:        busy,
                blockReason: blockReason,
                onAccept:    blockReason == null ? _accept : null,
                onReject:    _reject,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────
class _DialogHeader extends StatelessWidget {
  final BranchReturn  ret;
  final VoidCallback? onClose;
  const _DialogHeader({required this.ret, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: WarehouseAppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        WarehouseAppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.assignment_return_outlined,
                size: 20, color: WarehouseAppColor.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(ret.returnNumber,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: WarehouseAppColor.textPrimary)),
                  ),
                  const SizedBox(width: 10),
                  ReturnStatusPill(status: ret.status),
                ]),
                const SizedBox(height: 2),
                Text('${ret.fromStoreName.isEmpty ? 'Branch' : ret.fromStoreName} se wapas aaya stock',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: WarehouseAppColor.textSecondary)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Band karein',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final BranchReturn ret;
  const _InfoGrid({required this.ret});

  @override
  Widget build(BuildContext context) {
    final qty  = ret.items.isEmpty ? ret.totalItems : ret.itemsQty;
    final cost = ret.items.isEmpty ? ret.totalCost : ret.itemsCost;
    final tiles = <(IconData, String, String)>[
      (Icons.storefront_outlined, 'Branch',
          ret.fromStoreName.isEmpty ? '—' : ret.fromStoreName),
      (Icons.person_outline, 'Bheja',
          (ret.returnedByName ?? '').isEmpty ? '—' : ret.returnedByName!),
      (Icons.schedule_rounded, 'Date', fmtReturnDate(ret.returnedAt)),
      (Icons.inventory_2_outlined, 'Products / Qty',
          '${ret.items.length} · ${fmtReturnQty(qty)}'),
      (Icons.payments_outlined, 'Total cost', 'Rs ${cost.pkrFormat}'),
      (Icons.sell_outlined, 'Sale value', 'Rs ${ret.totalSalePrice.pkrFormat}'),
    ];

    return LayoutBuilder(builder: (context, c) {
      final perRow = c.maxWidth >= 760 ? 3 : (c.maxWidth >= 480 ? 2 : 1);
      final w = (c.maxWidth - (perRow - 1) * 10) / perRow;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (icon, label, value) in tiles)
            SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color:        WarehouseAppColor.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(icon, size: 18, color: WarehouseAppColor.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: WarehouseAppColor.textSecondary)),
                        const SizedBox(height: 2),
                        Text(value,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w600,
                                color: WarehouseAppColor.textPrimary)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
        ],
      );
    });
  }
}

class _NoteBox extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   text;
  final Color    color;
  final Widget?  action;

  const _NoteBox({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 2),
                Text(text,
                    style: const TextStyle(
                        fontSize: 13, color: WarehouseAppColor.textPrimary)),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _ResponseBox extends StatelessWidget {
  final BranchReturn ret;
  const _ResponseBox({required this.ret});

  @override
  Widget build(BuildContext context) {
    final accepted = ret.isAccepted;
    final who  = (ret.respondedByName ?? '').isEmpty ? '—' : ret.respondedByName!;
    final when = ret.respondedAt == null ? '' : ' · ${fmtReturnDate(ret.respondedAt!)}';
    return _NoteBox(
      icon:  accepted ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
      title: accepted ? 'Accept kiya: $who$when' : 'Reject kiya: $who$when',
      text:  accepted
          ? 'Is return ki qty warehouse stock mein add ho chuki hai.'
          : 'Wajah: ${(ret.rejectReason ?? '').trim().isEmpty ? '—' : ret.rejectReason!.trim()}'
            '\nBranch apna stock khud wapas le leti hai.',
      color: accepted ? WarehouseAppColor.success : WarehouseAppColor.error,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ITEMS TABLE
// ─────────────────────────────────────────────────────────────
class _ItemsTable extends StatelessWidget {
  final BranchReturn                     ret;
  final Map<String, ReturnProductStatus> status;
  const _ItemsTable({required this.ret, required this.status});

  static const _th = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: WarehouseAppColor.textSecondary, letterSpacing: 0.6);

  @override
  Widget build(BuildContext context) {
    Widget th(String t, int flex, [TextAlign a = TextAlign.left]) =>
        Expanded(flex: flex, child: Text(t, textAlign: a, style: _th));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: WarehouseAppColor.grey200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFF8FAFC),
            child: Row(children: [
              const SizedBox(width: 28, child: Text('#', style: _th)),
              th('PRODUCT', 34),
              th('UNIT', 8),
              th('QTY', 10, TextAlign.right),
              th('PURCHASE', 13, TextAlign.right),
              th('LINE TOTAL', 14, TextAlign.right),
            ]),
          ),
          if (ret.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Koi item nahi',
                  style: TextStyle(color: WarehouseAppColor.textSecondary)),
            )
          else
            for (var i = 0; i < ret.items.length; i++)
              _ItemRow(
                index:  i + 1,
                item:   ret.items[i],
                status: status[ret.items[i].productId],
                last:   i == ret.items.length - 1,
              ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int                  index;
  final BranchReturnItem     item;
  final ReturnProductStatus? status;
  final bool                 last;

  const _ItemRow({
    required this.index,
    required this.item,
    required this.status,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final issue = status?.message;
    const cell = TextStyle(fontSize: 13, color: WarehouseAppColor.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: issue != null ? WarehouseAppColor.errorLight.withOpacity(0.6) : null,
        border: last
            ? null
            : const Border(bottom: BorderSide(color: WarehouseAppColor.grey100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$index',
                style: const TextStyle(
                    fontSize: 12, color: WarehouseAppColor.textSecondary)),
          ),
          Expanded(
            flex: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: cell.copyWith(fontWeight: FontWeight.w600)),
                if ((item.sku ?? '').isNotEmpty)
                  Text('SKU ${item.sku}',
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: WarehouseAppColor.textSecondary)),
                if (issue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 14, color: WarehouseAppColor.error),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(issue,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: WarehouseAppColor.error)),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
          Expanded(flex: 8, child: Text(item.unit, style: cell)),
          Expanded(
            flex: 10,
            child: Text(fmtReturnQty(item.quantityReturned),
                textAlign: TextAlign.right,
                style: cell.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 13,
            child: Text('Rs ${item.purchasePrice.pkrFormat}',
                textAlign: TextAlign.right, style: cell),
          ),
          Expanded(
            flex: 14,
            child: Text('Rs ${item.totalCost.pkrFormat}',
                textAlign: TextAlign.right,
                style: cell.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTION BAR (sirf pending)
// ─────────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final bool          busy;
  final String?       blockReason;
  final VoidCallback? onAccept;
  final VoidCallback  onReject;

  const _ActionBar({
    required this.busy,
    required this.blockReason,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: WarehouseAppColor.grey200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: blockReason == null
                ? const Text('Accept = poori qty warehouse stock mein add · Reject = branch ko wapas',
                    style: TextStyle(
                        fontSize: 12.5, color: WarehouseAppColor.textSecondary))
                : Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: WarehouseAppColor.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(blockReason!,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600,
                              color: WarehouseAppColor.error)),
                    ),
                  ]),
          ),
          const SizedBox(width: 12),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4)),
            )
          else ...[
            SizedBox(
              height: 42,
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  minimumSize:   Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  foregroundColor: WarehouseAppColor.error,
                  side: BorderSide(
                      color: WarehouseAppColor.error.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  minimumSize:   Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  backgroundColor: WarehouseAppColor.success,
                  foregroundColor: WarehouseAppColor.white,
                  disabledBackgroundColor: WarehouseAppColor.grey300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONFIRM + REJECT REASON
// ─────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final Color  color;

  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: WarehouseAppColor.surface,
      title: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 380,
        child: Text(body, style: const TextStyle(fontSize: 14, height: 1.4)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Nahi'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            backgroundColor: color,
            foregroundColor: WarehouseAppColor.white,
            elevation: 0,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _ctrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState?.validate() ?? false) {
      Navigator.pop(context, _ctrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: WarehouseAppColor.surface,
      title: const Text('Return reject karein?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Warehouse stock nahi badlega — branch ko uska stock wapas mil jayega.',
                  style: TextStyle(
                      fontSize: 13, color: WarehouseAppColor.textSecondary)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ctrl,
                autofocus:  true,
                maxLines:   3,
                maxLength:  300,
                decoration: const InputDecoration(
                  labelText: 'Wajah *',
                  hintText:  'Reject kyun kar rahe hain?',
                  border:    OutlineInputBorder(),
                ),
                validator: (v) => (v ?? '').trim().length < 5
                    ? 'Wajah likhein (kam az kam 5 huroof)'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Wapas'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            backgroundColor: WarehouseAppColor.error,
            foregroundColor: WarehouseAppColor.white,
            elevation: 0,
          ),
          child: const Text('Reject karein'),
        ),
      ],
    );
  }
}
