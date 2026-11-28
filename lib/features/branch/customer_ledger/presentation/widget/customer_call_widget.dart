import 'package:jan_ghani_final/core/color/branch_color.dart';
import 'package:flutter/material.dart';
import 'package:jan_ghani_final/features/branch/customer_ledger/data/model/customer_ledger_model.dart';

// ── Customer Cell ─────────────────────────────────────────────
class CustomerCell extends StatelessWidget {
  final CustomerLedgerModel l;
  const CustomerCell({super.key, required this.l});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius:          16,
          backgroundColor: BranchColor.navy.withValues(alpha: 0.1),
          child: Text(
            l.customerName.isNotEmpty
                ? l.customerName[0].toUpperCase()
                : '?',
            style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w700,
                color:      BranchColor.navy),
          ),
        ),
        const SizedBox(width: 10),
        Text(l.customerName,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize:   13)),
      ],
    );
  }
}
