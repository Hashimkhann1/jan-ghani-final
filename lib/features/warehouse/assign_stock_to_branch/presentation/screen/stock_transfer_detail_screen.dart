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
    final transfers = ref.watch(stockTransferProvider);
    final transfer = transfers.firstWhere((t) => t.transferId == transferId);
    final isPending = transfer.status == TransferStatus.pending;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1D23)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transfer.transferId,
              style: const TextStyle(
                color: Color(0xFF1A1D23),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              "Stock Transfer Invoice",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: _StatusChip(status: transfer.status),
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
                  // ── Invoice Header Card ──
                  _InvoiceHeaderCard(transfer: transfer),

                  const SizedBox(height: 12),

                  // ── From / To Card ──
                  _FromToCard(transfer: transfer),

                  const SizedBox(height: 12),

                  // ── Products Table ──
                  _ProductsCard(transfer: transfer),

                  const SizedBox(height: 12),

                  // ── Amount Summary ──
                  _AmountSummaryCard(transfer: transfer),

                  if (transfer.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _NotesCard(notes: transfer.notes),
                  ],

                  const SizedBox(height: 100), // bottom padding for FAB
                ],
              ),
            ),
          ),

          // ── Accept Button ──
          if (isPending)
            _AcceptBar(
              onAccept: () => _onAccept(context, ref, transfer),
            ),

          if (!isPending)
            _AcceptedBar(transfer: transfer),
        ],
      ),
    );
  }

  void _onAccept(
      BuildContext context, WidgetRef ref, StockTransfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AcceptConfirmDialog(transfer: transfer),
    );
    if (confirmed == true) {
      ref.read(stockTransferProvider.notifier).acceptTransfer(transfer.transferId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  "${transfer.items.length} products added to branch stock",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

// ──────────────────────────────────────────────
// Invoice Header
// ──────────────────────────────────────────────
class _InvoiceHeaderCard extends StatelessWidget {
  final StockTransfer transfer;
  const _InvoiceHeaderCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Color(0xFF6366F1), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Transfer Invoice",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      transfer.transferId,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6366F1),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),

          // Info grid
          Row(
            children: [
              _InfoCell(
                label: "Transfer Date",
                value: fmt.format(transfer.transferDate),
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(width: 16),
              _InfoCell(
                label: "Time",
                value: timeFmt.format(transfer.transferDate),
                icon: Icons.access_time_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoCell(
                label: "Total Products",
                value: "${transfer.items.length} types",
                icon: Icons.inventory_2_rounded,
              ),
              const SizedBox(width: 16),
              _InfoCell(
                label: "Total Quantity",
                value: "${transfer.totalItems} units",
                icon: Icons.numbers_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoCell(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF))),
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

// ──────────────────────────────────────────────
// From / To Card
// ──────────────────────────────────────────────
class _FromToCard extends StatelessWidget {
  final StockTransfer transfer;
  const _FromToCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // From
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warehouse_rounded,
                        size: 14, color: Color(0xFF6366F1)),
                    SizedBox(width: 6),
                    Text(
                      "FROM",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  transfer.warehouseName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transfer.warehouseAddress,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6C7280), height: 1.4),
                ),
              ],
            ),
          ),

          // Arrow
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.arrow_forward_rounded,
                size: 16, color: Color(0xFF6366F1)),
          ),

          // To
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "TO",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.store_rounded,
                        size: 14, color: Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  transfer.branchName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23),
                  ),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 4),
                const Text(
                  "Current Branch",
                  style: TextStyle(fontSize: 11, color: Color(0xFF6C7280)),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Products Card
// ──────────────────────────────────────────────
class _ProductsCard extends StatelessWidget {
  final StockTransfer transfer;
  const _ProductsCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded,
                    size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text(
                  "Product List",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${transfer.items.length} items",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8F9FF),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text("Product",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C7280),
                          letterSpacing: 0.3)),
                ),
                Expanded(
                  child: Text("Qty",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C7280),
                          letterSpacing: 0.3)),
                ),
                Expanded(
                  child: Text("Price",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C7280),
                          letterSpacing: 0.3)),
                ),
                Expanded(
                  child: Text("Total",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6C7280),
                          letterSpacing: 0.3)),
                ),
              ],
            ),
          ),

          // Product Rows
          ...transfer.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isLast = i == transfer.items.length - 1;
            return _ProductRow(item: item, isLast: isLast, index: i);
          }),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final StockTransferItem item;
  final bool isLast;
  final int index;

  const _ProductRow(
      {required this.item, required this.isLast, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFAFC),
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6))),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      item.barcode,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                          fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.unit,
                        style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF6C7280),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (item.tax > 0 || item.discount > 0) ...[
                      const SizedBox(width: 4),
                      if (item.tax > 0)
                        _MiniTag(
                          label: "+${item.tax.toStringAsFixed(0)}% tax",
                          color: const Color(0xFFFEF3C7),
                          textColor: const Color(0xFFD97706),
                        ),
                      if (item.discount > 0) ...[
                        const SizedBox(width: 3),
                        _MiniTag(
                          label: "-${item.discount.toStringAsFixed(0)}%",
                          color: const Color(0xFFD1FAE5),
                          textColor: const Color(0xFF059669),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Qty
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${item.quantity}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
          ),

          // Unit Price
          Expanded(
            child: Text(
              "Rs. ${item.unitPrice.toStringAsFixed(0)}",
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6C7280)),
            ),
          ),

          // Row Total
          Expanded(
            child: Text(
              "Rs. ${item.total.toStringAsFixed(0)}",
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D23),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _MiniTag(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Amount Summary Card
// ──────────────────────────────────────────────
class _AmountSummaryCard extends StatelessWidget {
  final StockTransfer transfer;
  const _AmountSummaryCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final subtotal =
        transfer.items.fold(0.0, (s, i) => s + i.subtotal);
    final totalTax =
        transfer.items.fold(0.0, (s, i) => s + i.taxAmount);
    final totalDiscount =
        transfer.items.fold(0.0, (s, i) => s + i.discountAmount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: "Subtotal",
              value: "Rs. ${subtotal.toStringAsFixed(0)}"),
          const SizedBox(height: 8),
          _SummaryRow(
              label: "Total Tax",
              value: "+ Rs. ${totalTax.toStringAsFixed(0)}",
              valueColor: const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          _SummaryRow(
              label: "Total Discount",
              value: "- Rs. ${totalDiscount.toStringAsFixed(0)}",
              valueColor: const Color(0xFF10B981)),
          const SizedBox(height: 14),
          Container(height: 1.5, color: const Color(0xFFF3F4F6)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grand Total",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Rs. ${transfer.grandTotal.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: Color(0xFF6C7280))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1D23),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Notes Card
// ──────────────────────────────────────────────
class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, size: 15, color: Color(0xFF6C7280)),
              SizedBox(width: 8),
              Text(
                "Notes",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D23)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style:
                const TextStyle(fontSize: 13, color: Color(0xFF6C7280), height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Accept Bar (bottom)
// ──────────────────────────────────────────────
class _AcceptBar extends StatelessWidget {
  final VoidCallback onAccept;
  const _AcceptBar({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: FilledButton.icon(
        onPressed: onAccept,
        icon: const Icon(Icons.check_circle_rounded, size: 20),
        label: const Text(
          "Accept & Add to Branch Stock",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _AcceptedBar extends StatelessWidget {
  final StockTransfer transfer;
  const _AcceptedBar({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Text(
              "${transfer.totalItems} units added to branch stock",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF059669),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Confirm Dialog
// ──────────────────────────────────────────────
class _AcceptConfirmDialog extends StatelessWidget {
  final StockTransfer transfer;
  const _AcceptConfirmDialog({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_rounded,
                  color: Color(0xFF6366F1), size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              "Accept Transfer?",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23)),
            ),
            const SizedBox(height: 8),
            Text(
              "${transfer.items.length} products (${transfer.totalItems} units) will be added to your branch stock.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6C7280), height: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              "From: ${transfer.warehouseName}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w600),
            ),
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
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Yes, Accept",
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
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
  final TransferStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == TransferStatus.pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPending ? "Pending" : "Accepted",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isPending ? const Color(0xFFD97706) : const Color(0xFF059669),
        ),
      ),
    );
  }
}
