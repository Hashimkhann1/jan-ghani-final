import 'package:flutter/material.dart';
import '../../data/model/stock_transfer_model.dart';

class StatusChip extends StatelessWidget {
  final TransferStatus status;
  const StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == TransferStatus.pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isPending
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPending ? "Pending" : "Accepted",
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isPending
                ? const Color(0xFFD97706)
                : const Color(0xFF059669)),
      ),
    );
  }
}
