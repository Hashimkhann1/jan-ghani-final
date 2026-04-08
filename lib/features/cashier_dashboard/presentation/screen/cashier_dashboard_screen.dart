import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/widget/figure_card_widget.dart';
import '../../model/cashier_dashboard_model.dart';

class CashierDashboardScreen extends StatelessWidget {
  const CashierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = CashierData.dummy();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cashier Dashboard',
              style: TextStyle(
                color: Color(0xFF1A1D23),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text('Today, ${DateTime.now().day} Apr ${DateTime.now().year}',
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined,
                color: Color(0xFF6B7280), size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Counter Cash
            Row(
              children: [
                SummaryCard(
                  title: "Counter Cash",
                  value: 20000.toString(),
                  icon: Icons.wallet,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section label
            const Text('SALES BREAKDOWN',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),

            GridView.count(
              crossAxisCount: 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 10,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SummaryCard(
                        title: 'Cash Sale',
                        value: data.cashSale.toString(),
                        color: const Color(0xFF3B6D11),
                        icon: Icons.attach_money,
                      ),
                      const SizedBox(width: 10),
                      SummaryCard(
                        title: 'Card Sale',
                        value: data.cardSale.toString(),
                        color: const Color(0xFF185FA5),
                        icon: Icons.credit_card_outlined,
                      ),
                      const SizedBox(width: 10),
                      SummaryCard(
                        title: 'Credit Sale',
                        value: data.creditSale.toString(),
                        color: const Color(0xFF854F0B),
                        icon: Icons.description_outlined,
                      ),
                      const SizedBox(width: 10),
                      SummaryCard(
                        title: 'Installment',
                        value: data.installment.toString(),
                        color: const Color(0xFF534AB7),
                        icon: Icons.trending_up,
                      ),
                      const SizedBox(width: 10),
                      SummaryCard(
                        title: 'Total Sale',
                        value: data.totalSales.toStringAsFixed(0),
                        color: const Color(0xFF9F4AB7),
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                ],
            ),

            const SizedBox(height: 16),

            // Cash Withdrawals to Manager
            const Text('COUNTER CASH WITHDRAWALS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),

            data.withdrawals.isEmpty
                ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
              ),
              child: const Center(
                child: Text('No withdrawals yet',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
              ),
            )
                : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
              ),
              child: Column(
                children: data.withdrawals
                    .asMap()
                    .entries
                    .map((e) => _WithdrawalRow(
                  w: e.value,
                  isLast: e.key == data.withdrawals.length - 1,
                ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _WithdrawalRow extends StatelessWidget {
  final CashierWithdrawal w;
  final bool isLast;

  const _WithdrawalRow({required this.w, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 0.5)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFCEBEB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_upward_rounded,
                color: Color(0xFFA32D2D), size: 18),
          ),
          const SizedBox(width: 12),

          // Name + Note
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.managerName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1D23))),
                const SizedBox(height: 2),
                Text(w.note,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),

          // Time + Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(w.time,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 2),
              Text(
                '-Rs ${w.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA32D2D)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}