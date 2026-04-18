import 'package:flutter/material.dart';
import '../../data/model/stock_transfer_model.dart';
import 'expandable_row_widget.dart';
import 'hdr_widget.dart';

class TransferTable extends StatelessWidget {
  final List<StockTransfer> transfers;
  final bool isPending;
  final String? expandedId;
  final void Function(String) onToggle;
  final void Function(StockTransfer) onAccept;

  const TransferTable({
    required this.transfers,
    required this.isPending,
    required this.expandedId,
    required this.onToggle,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FF), shape: BoxShape.circle),
              child: Icon(
                isPending
                    ? Icons.pending_actions_rounded
                    : Icons.check_circle_outline_rounded,
                size: 40,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? "No pending transfers" : "No accepted transfers",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D23)),
            ),
            const SizedBox(height: 6),
            Text(
              isPending
                  ? "All warehouse stock has been received"
                  : "No transfers accepted yet",
              style: const TextStyle(fontSize: 13, color: Color(0xFF6C7280)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // ── Table Header ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                color: const Color(0xFFF8F9FF),
                child: const Row(
                  children: [
                    SizedBox(width: 28),
                    Expanded(
                      flex: 2,
                      child: Hdr(label: "Transfer No"),
                    ),
                    Expanded(
                      flex: 2,
                      child: Hdr(label: "Date"),
                    ),
                    Expanded(
                      flex: 3,
                      child: Hdr(label: "Warehouse"),
                    ),
                    Expanded(
                      child: Hdr(label: "Products", center: true),
                    ),
                    Expanded(
                      child: Hdr(label: "Amount", right: true),
                    ),
                    Expanded(
                      child: Hdr(label: "Status", center: true),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // ── Rows ──
              ...transfers.asMap().entries.map((entry) {
                final i = entry.key;
                final t = entry.value;
                return ExpandableRow(
                  transfer: t,
                  index: i,
                  isExpanded: expandedId == t.transferId,
                  isLast: i == transfers.length - 1,
                  onTap: () => onToggle(t.transferId),
                  onAccept: () => onAccept(t),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
