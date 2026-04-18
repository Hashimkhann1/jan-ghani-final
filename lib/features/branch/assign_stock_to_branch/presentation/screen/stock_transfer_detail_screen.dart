import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/model/stock_transfer_model.dart';
import '../provider/stock_transfer_provider.dart';

class StockTransferDetailScreen extends ConsumerWidget {
  final String transferId;
  const StockTransferDetailScreen({super.key, required this.transferId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransfers = ref.watch(stockTransferProvider);

    return asyncTransfers.when(
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text("Error: $e"))),
      data: (transfers) {
        final transfer =
        transfers.firstWhere((t) => t.id == transferId);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF1A1D23)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transfer.transferNumber,
                    style: const TextStyle(
                        color: Color(0xFF1A1D23),
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const Text("Transfer Invoice",
                    style: TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: _StatusChip(transfer: transfer),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _HeaderCard(transfer: transfer),
                      const SizedBox(height: 12),
                      _FromToCard(transfer: transfer),
                      const SizedBox(height: 12),
                      _InvoiceTable(transfer: transfer),
                      if (transfer.notes != null &&
                          transfer.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _NotesCard(notes: transfer.notes!),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
              _BottomBar(transfer: transfer),
            ],
          ),
        );
      },
    );
  }
}

// ── Header Card ──
class _HeaderCard extends StatelessWidget {
  final StockTransfer transfer;
  const _HeaderCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Transfer Invoice",
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF9CA3AF))),
                    Text(transfer.transferNumber,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6366F1))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 14),
          Row(
            children: [
              _InfoTile(
                icon: Icons.calendar_today_rounded,
                label: "Date",
                value: dateFmt.format(transfer.assignedAt),
              ),
              const SizedBox(width: 10),
              _InfoTile(
                icon: Icons.access_time_rounded,
                label: "Time",
                value: timeFmt.format(transfer.assignedAt),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoTile(
                icon: Icons.inventory_2_rounded,
                label: "Products",
                value: "${transfer.items.length} types",
              ),
              const SizedBox(width: 10),
              _InfoTile(
                icon: Icons.numbers_rounded,
                label: "Total Qty",
                value: "${transfer.totalItems} units",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF9CA3AF))),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1D23))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── From To Card ──
class _FromToCard extends StatelessWidget {
  final StockTransfer transfer;
  const _FromToCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.warehouse_rounded,
                      size: 13, color: Color(0xFF6366F1)),
                  SizedBox(width: 6),
                  Text("FROM",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                          letterSpacing: 1)),
                ]),
                const SizedBox(height: 6),
                Text(transfer.assignedByName ?? 'Warehouse',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.arrow_forward_rounded,
                size: 14, color: Color(0xFF6366F1)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("TO",
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                              letterSpacing: 1)),
                      SizedBox(width: 6),
                      Icon(Icons.store_rounded,
                          size: 13, color: Color(0xFF10B981)),
                    ]),
                const SizedBox(height: 6),
                Text(transfer.toStoreName,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Invoice Table (main UI) ──
class _InvoiceTable extends StatelessWidget {
  final StockTransfer transfer;
  const _InvoiceTable({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final subtotal = transfer.subtotal;
    final totalDiscount = transfer.totalDiscount;
    final totalTax = transfer.totalTax;
    final grandTotal = transfer.grandTotal;

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded,
                    size: 15, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text("Product List",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text("${transfer.items.length} items",
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1))),
                ),
              ],
            ),
          ),

          // Column Headers
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            color: const Color(0xFFF8F9FF),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text("Product",
                        style: _headerStyle)),
                Expanded(
                    child: Text("Qty",
                        textAlign: TextAlign.center,
                        style: _headerStyle)),
                Expanded(
                    child: Text("Rate",
                        textAlign: TextAlign.right,
                        style: _headerStyle)),
                Expanded(
                    child: Text("Disc",
                        textAlign: TextAlign.right,
                        style: _headerStyle)),
                Expanded(
                    child: Text("Total",
                        textAlign: TextAlign.right,
                        style: _headerStyle)),
              ],
            ),
          ),

          // Product Rows
          ...transfer.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final rowTotal =
                (item.purchasePrice * item.quantity) - item.discountAmount;

            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: i.isEven
                    ? Colors.white
                    : const Color(0xFFFAFAFF),
                border: i < transfer.items.length - 1
                    ? const Border(
                    bottom: BorderSide(color: Color(0xFFF3F4F6)))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name + SKU
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1D23))),
                        const SizedBox(height: 2),
                        Text(item.sku,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9CA3AF),
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  // Qty
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text("${item.quantitySent.toInt()}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1))),
                    ),
                  ),
                  // Rate
                  Expanded(
                    child: Text(
                        "Rs.${item.purchasePrice.toStringAsFixed(0)}",
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6C7280))),
                  ),
                  // Discount
                  Expanded(
                    child: Text(
                        item.discountAmount > 0
                            ? "-${item.discountAmount.toStringAsFixed(0)}"
                            : "-",
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF10B981))),
                  ),
                  // Total
                  Expanded(
                    child: Text(
                        "Rs.${rowTotal.toStringAsFixed(0)}",
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D23))),
                  ),
                ],
              ),
            );
          }),

          // Summary Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Color(0xFFF3F4F6), width: 1.5)),
            ),
            child: Column(
              children: [
                _SummaryRow("Subtotal",
                    "Rs. ${subtotal.toStringAsFixed(0)}"),
                const SizedBox(height: 6),
                _SummaryRow(
                    "Total Discount",
                    "- Rs. ${totalDiscount.toStringAsFixed(0)}",
                    color: const Color(0xFF10B981)),
                const SizedBox(height: 6),
                _SummaryRow(
                    "Total Tax",
                    "+ Rs. ${totalTax.toStringAsFixed(0)}",
                    color: const Color(0xFFF59E0B)),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Grand Total",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D23))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                          "Rs. ${grandTotal.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _SummaryRow(String label, String value, {Color? color}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF6C7280))),
      Text(value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? const Color(0xFF1A1D23))),
    ],
  );
}

const _headerStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w700,
  color: Color(0xFF6C7280),
  letterSpacing: 0.3,
);

// ── Notes ──
class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.notes_rounded, size: 14, color: Color(0xFF6C7280)),
            SizedBox(width: 8),
            Text("Notes",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23))),
          ]),
          const SizedBox(height: 8),
          Text(notes,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6C7280),
                  height: 1.5)),
        ],
      ),
    );
  }
}

// ── Bottom Bar: Accept / Reject / Already Accepted ──
class _BottomBar extends ConsumerWidget {
  final StockTransfer transfer;
  const _BottomBar({required this.transfer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (transfer.isAccepted) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
        decoration: _bottomDecoration(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 20),
              SizedBox(width: 10),
              Text("Transfer Accepted & Added to Stock",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669))),
            ],
          ),
        ),
      );
    }

    if (transfer.isRejected) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
        decoration: _bottomDecoration(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel_rounded,
                  color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 10),
              Text("Transfer Rejected",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626))),
            ],
          ),
        ),
      );
    }

    // Pending — Accept & Reject buttons
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: _bottomDecoration(),
      child: Row(
        children: [
          // Reject button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _onReject(context, ref),
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: Color(0xFFEF4444)),
              label: const Text("Reject",
                  style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Accept button
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => _onAccept(context, ref),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text("Accept & Add to Stock",
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onAccept(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: "Accept Transfer?",
        message:
        "${transfer.items.length} products (${transfer.totalItems} units) will be added to your branch stock.\n\nFrom: ${transfer.assignedByName ?? 'Warehouse'}",
        confirmLabel: "Yes, Accept",
        confirmColor: const Color(0xFF6366F1),
        icon: Icons.inventory_rounded,
        iconBg: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF6366F1),
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(stockTransferProvider.notifier)
          .acceptTransfer(transfer.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              success
                  ? "${transfer.items.length} products added to branch stock"
                  : "Something went wrong. Try again.",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ]),
          backgroundColor:
          success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  void _onReject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: "Reject Transfer?",
        message:
        "This transfer will be marked as rejected. Products will NOT be added to stock.",
        confirmLabel: "Yes, Reject",
        confirmColor: const Color(0xFFEF4444),
        icon: Icons.cancel_rounded,
        iconBg: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFEF4444),
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(stockTransferProvider.notifier)
          .rejectTransfer(transfer.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            success ? "Transfer rejected." : "Something went wrong.",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: success
              ? const Color(0xFFEF4444)
              : const Color(0xFF1A1D23),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }
}

// ── Confirm Dialog ──
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23))),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C7280),
                    height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cancel",
                        style: TextStyle(
                            color: Color(0xFF6C7280),
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: confirmColor,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Chip ──
class _StatusChip extends StatelessWidget {
  final StockTransfer transfer;
  const _StatusChip({required this.transfer});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    String label;

    if (transfer.isPending) {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFD97706);
      label = "Pending";
    } else if (transfer.isAccepted) {
      bg = const Color(0xFFD1FAE5);
      text = const Color(0xFF059669);
      label = "Accepted";
    } else {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFDC2626);
      label = "Rejected";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: text)),
    );
  }
}

// ── Helpers ──
BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: const Color(0xFFE5E7EB)),
);

BoxDecoration _bottomDecoration() => const BoxDecoration(
  color: Colors.white,
  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
);