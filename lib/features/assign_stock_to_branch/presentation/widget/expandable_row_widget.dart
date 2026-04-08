import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jan_ghani_final/features/assign_stock_to_branch/presentation/widget/status_chip_widget.dart';
import '../../data/model/stock_transfer_model.dart';
import '../screen/branch_transfer_list_screen.dart';
import 'expanded_panel_widget.dart';

class ExpandableRow extends StatelessWidget {
  final StockTransfer transfer;
  final int index;
  final bool isExpanded;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onAccept;

  const ExpandableRow({
    required this.transfer,
    required this.index,
    required this.isExpanded,
    required this.isLast,
    required this.onTap,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = transfer.status == TransferStatus.pending;
    final rowBg = isExpanded
        ? const Color(0xFFF5F3FF)
        : index.isEven
        ? Colors.white
        : const Color(0xFFFAFAFC);

    return Column(
      children: [
        // ── Main row ──
        InkWell(
          onTap: onTap,
          child: Container(
            color: rowBg,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Chevron
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isExpanded
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 8),

                // Transfer No
                Expanded(
                  flex: 2,
                  child: Text(
                    transfer.transferId,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isExpanded ? const Color(0xFF6366F1) : const Color(0xFF1A1D23),
                    ),
                  ),
                ),

                // Date
                Expanded(
                  flex: 2,
                  child: Text(
                    DateFormat('dd MMM yyyy').format(transfer.transferDate),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6C7280)),
                  ),
                ),

                // Warehouse
                Expanded(
                  flex: 3,
                  child: Text(
                    transfer.warehouseName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1D23),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                // Products
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${transfer.items.length}",
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

                // Amount
                Expanded(
                  child: Text(
                    "Rs.${transfer.grandTotal.toStringAsFixed(0)}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23),
                    ),
                  ),
                ),

                // Status
                Expanded(
                  child: Center(child: StatusChip(status: transfer.status)),
                ),
              ],
            ),
          ),
        ),

        // ── Expanded Panel ──
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: ExpandedPanel(
            transfer: transfer,
            isPending: isPending,
            onAccept: onAccept,
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),

        if (!isLast) const Divider(height: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }
}
