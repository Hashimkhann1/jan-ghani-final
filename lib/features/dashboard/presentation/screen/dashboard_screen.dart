import 'package:flutter/material.dart';
import '../../data/model/dashboard_model.dart';
import '../widget/dashboard_chart_widget.dart';
import '../widget/summary_card_row_widget.dart';
import '../widget/top_list_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = DashboardData.dummy();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Branch Dashboard',
          style: TextStyle(
            color: Color(0xFF1A1D23),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
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
            // ── Summary Cards ──
            SummaryCardsRow(data: data),

            const SizedBox(height: 16),

            // ── Charts Row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: WeeklySalesChart(data: data.weeklySales)),
                const SizedBox(width: 12),
                Expanded(
                    child: TopProductsLineChart(products: data.topProducts)),
              ],
            ),

            const SizedBox(height: 16),

            // ── Top Lists Row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: TopProductsList(products: data.topProducts)),
                const SizedBox(width: 12),
                Expanded(child: TopCustomersList(customers: data.topCustomers)),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}