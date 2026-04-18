import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../provider/dashboard_provider.dart';
import '../widget/dashboard_chart_widget.dart';
import '../widget/summary_card_row_widget.dart';
import '../widget/top_list_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final auth  = ref.watch(authProvider);
    final data  = state.data;

    final isManager = auth.role == 'store_owner' || auth.role == 'store_manager';

    ref.listen<DashboardState>(dashboardProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text(next.errorMessage!),
          backgroundColor: const Color(0xFFEF4444),
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label:     'OK',
            textColor: Colors.white,
            onPressed: () =>
                ref.read(dashboardProvider.notifier).clearError(),
          ),
        ));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Branch Dashboard',
          style: TextStyle(
            color: Color(0xFF1A1D23),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280), size: 20),
            onPressed: () => ref.read(dashboardProvider.notifier).load(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading ?
      const Center(child: CircularProgressIndicator()) :
      RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              // ── Summary Cards ─────────────────────
              SummaryCardsRow(data: data),
              const SizedBox(height: 16),

              // ── Charts Row ────────────────────────
              if (data.weeklySales.any((s) => s.amount > 0)) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: WeeklySalesChart(
                            data: data.weeklySales)),
                    const SizedBox(width: 12),
                    if (data.topProducts.length >= 2)
                      Expanded(
                          child: TopProductsLineChart(
                              products: data.topProducts)),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // ── Top Lists ─────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.topProducts.isNotEmpty)
                    Expanded(
                        child: TopProductsList(
                            products: data.topProducts)),
                  if (data.topProducts.isNotEmpty &&
                      data.topCustomers.isNotEmpty)
                    const SizedBox(width: 12),
                  if (data.topCustomers.isNotEmpty)
                    Expanded(
                        child: TopCustomersList(
                            customers: data.topCustomers)),
                ],
              ),

              // ── Empty State ───────────────────────
              if (data.topProducts.isEmpty &&
                  data.topCustomers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_outlined,
                            size:  64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Aaj koi sale nahi hui',
                            style: TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500)),
                        const SizedBox(height: 6),
                        Text(
                            'Sales ke baad yahan data show hoga',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}