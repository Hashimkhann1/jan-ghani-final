// lib/presentation/widget/tab/cusomer_ledger_lab.dart

import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';

class CustomerLedgerTab extends StatelessWidget {
  final String customerId;
  const CustomerLedgerTab({super.key, required this.customerId});

  // Mock payment data — baad mein API se replace karna
  static const _payments = [
    _PaymentEntry(date: '28 Mar 2026', paymentType: 'Cash',          payAmount: 6000,  newBalance: 12000),
    _PaymentEntry(date: '20 Mar 2026', paymentType: 'Bank Transfer', payAmount: 12000, newBalance: 18000),
    _PaymentEntry(date: '10 Mar 2026', paymentType: 'Cheque',        payAmount: 5000,  newBalance: 30000),
    _PaymentEntry(date: '14 Feb 2026', paymentType: 'Cash',          payAmount: 8000,  newBalance: 35000),
    _PaymentEntry(date: '01 Feb 2026', paymentType: 'Bank Transfer', payAmount: 15000, newBalance: 43000),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Table Header ───────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color:        AppColor.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: AppColor.primary.withValues(alpha: 0.15)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 110, child: _HL('Date')),
              Expanded(            child: _HL('Payment Type')),
              SizedBox(width: 100, child: _HL('Pay Amount')),
              SizedBox(width: 100, child: _HL('Balance')),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Payment Rows ───────────────────────────
        ListView.separated(
          shrinkWrap:       true,
          physics:          const NeverScrollableScrollPhysics(),
          itemCount:        _payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder:      (_, i)  => _PaymentRow(entry: _payments[i]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Data class
// ─────────────────────────────────────────────────────────────
class _PaymentEntry {
  final String date;
  final String paymentType;
  final double payAmount;
  final double newBalance;

  const _PaymentEntry({
    required this.date,
    required this.paymentType,
    required this.payAmount,
    required this.newBalance,
  });
}

// ─────────────────────────────────────────────────────────────
//  Single Row
// ─────────────────────────────────────────────────────────────
class _PaymentRow extends StatelessWidget {
  final _PaymentEntry entry;
  const _PaymentRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColor.grey200),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset:     const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [

          // Date
          SizedBox(
            width: 110,
            child: Text(
              entry.date,
              style: const TextStyle(
                  fontSize: 12,
                  color:    AppColor.textSecondary),
            ),
          ),

          // Payment Type badge
          Expanded(
            child: _PaymentTypeBadge(type: entry.paymentType),
          ),

          // Pay Amount
          SizedBox(
            width: 100,
            child: Text(
              'Rs ${entry.payAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      AppColor.success),
            ),
          ),

          // New Balance
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        entry.newBalance > 0
                    ? AppColor.errorLight
                    : AppColor.successLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Rs ${entry.newBalance.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      entry.newBalance > 0
                        ? AppColor.error
                        : AppColor.success),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Payment Type Badge
// ─────────────────────────────────────────────────────────────
class _PaymentTypeBadge extends StatelessWidget {
  final String type;
  const _PaymentTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final map = {
      'Cash':          (AppColor.successLight, AppColor.success, Icons.payments_outlined),
      'Bank Transfer': (AppColor.primary.withValues(alpha: 0.1), AppColor.primary, Icons.account_balance_outlined),
      'Cheque':        (AppColor.warningLight, AppColor.warning, Icons.description_outlined),
    };

    final entry  = map[type];
    final bg     = entry?.$1 ?? AppColor.grey100;
    final fg     = entry?.$2 ?? AppColor.grey500;
    final icon   = entry?.$3 ?? Icons.payments_outlined;

    return Row(
      children: [
        Container(
          padding:    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 5),
              Text(type,
                  style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                      color:      fg)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Header Label
// ─────────────────────────────────────────────────────────────
class _HL extends StatelessWidget {
  final String text;
  const _HL(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w700,
          color:      AppColor.primary));
}