import 'package:flutter/material.dart';
import '../../data/model/dashboard_model.dart';

class SummaryCardsRow extends StatelessWidget {
  final DashboardData data;
  const SummaryCardsRow({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SummaryCard(
              title:   'Cash Sale',
              value:   _fmt(data.cashSale),
              icon:    Icons.payments_outlined,
              color:   const Color(0xFF3B9A5E),
              bgColor: const Color(0xFFEAF3DE),
            ),
            const SizedBox(width: 12),
            SummaryCard(
              title:   'Card Sale',
              value:   _fmt(data.cardSale),
              icon:    Icons.credit_card_outlined,
              color:   const Color(0xFF185FA5),
              bgColor: const Color(0xFFE6F1FB),
            ),
            const SizedBox(width: 12),
            SummaryCard(
              title:   'Credit Sale',
              value:   _fmt(data.creditSale),
              icon:    Icons.receipt_long_outlined,
              color:   const Color(0xFF854F0B),
              bgColor: const Color(0xFFFAEEDA),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SummaryCard(
              title:   'Installment',
              value:   _fmt(data.installment),
              icon:    Icons.calendar_month_outlined,
              color:   const Color(0xFF993556),
              bgColor: const Color(0xFFFBEAF0),
            ),
            const SizedBox(width: 12),
            SummaryCard(
              title:   'Total Sale',
              value:   _fmt(data.totalSale),
              icon:    Icons.bar_chart_rounded,
              color:   const Color(0xFF534AB7),
              bgColor: const Color(0xFFEEEDFE),
            ),
            const SizedBox(width: 12),
            SummaryCard(
              title:   'Net Amount',
              value:   _fmt(data.totalAmount),
              icon:    Icons.account_balance_wallet_outlined,
              color:   const Color(0xFF0F6E56),
              bgColor: const Color(0xFFE1F5EE),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) {
    final parts = v.toStringAsFixed(0).split('');
    final buf   = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return 'Rs $buf';
  }
}

class SummaryCard extends StatelessWidget {
  final String   title;
  final String   value;
  final IconData icon;
  final Color    color;
  final Color    bgColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize:   17,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF1A1D23))),
            const SizedBox(height: 3),
            Text(title,
                style: const TextStyle(
                    fontSize:   11,
                    color:      Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}