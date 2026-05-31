import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import '../../../accountant_all_orders/presentation/screen/accountant_all_orders_screen.dart';
import '../../../accountant_cash_transfer/presentation/screen/cash_transfers_screen.dart';
import '../../../accountant_stock_transfer_record/presentation/screen/accountant_stock_transfer_record_screen.dart';
import '../../../accountant_warehouse_finance/presentation/screen/accountant_warehouse_finance_screen.dart';
import '../../../accountant_warehouse_inventory/presentation/screen/accountant_warehouse_inventory_screen.dart';
import '../../../supplier/presentation/screen/all_supplier_screen.dart';
import '../../data/model/accountant_warehouse_dashboard_model.dart';
import '../provider/accountant_warehouse_dashboard_provider.dart';
import '../widget/send_cash_dialog.dart';

// =============================================================
// Accountant → Warehouse Dashboard
// Read-only: sirf Supabase se warehouse ka data dikhata hai
// (Total Suppliers + Outstanding, Total Inventory + Value,
//  Cash in Hand). Koi edit/delete option nahi.
// =============================================================
class AccountantWarehouseDashboardScreen extends ConsumerWidget {
  final String warehouseId;
  final String warehouseName;

  const AccountantWarehouseDashboardScreen({
    super.key,
    required this.warehouseId,
    this.warehouseName = 'Warehouse',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(warehouseDashboardStatsProvider(warehouseId));

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text(
          'Warehouse Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColor.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textDark),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColor.primary,
          onRefresh: () async =>
              ref.invalidate(warehouseDashboardStatsProvider(warehouseId)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: statsAsync.when(
              data: (stats) => _DashboardContent(
                stats: stats,
                warehouseId: warehouseId,
                warehouseName: warehouseName,
              ),
              loading: () => const _LoadingState(),
              error: (e, _) => const _ErrorState(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────
class _DashboardContent extends StatelessWidget {
  final WarehouseDashboardModel stats;
  final String warehouseId;
  final String warehouseName;
  const _DashboardContent({
    required this.stats,
    required this.warehouseId,
    required this.warehouseName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 13,
            color: AppColor.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          warehouseName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColor.textDark,
          ),
        ),
        const SizedBox(height: 20),

        // ── Cash in Hand (tap → warehouse finance) ────────────────────
        _CashCard(
          amount: stats.cashInHand,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccountantWarehouseFinanceScreen(
                warehouseId: warehouseId,
                warehouseName: warehouseName,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Suppliers (tap → all suppliers screen) ────────────────────
        _MetricCard(
          icon: Icons.people_alt_rounded,
          iconBg: const Color(0xFFEEF0FF),
          iconColor: AppColor.primary,
          title: 'Total Suppliers',
          value: _num(stats.totalSuppliers),
          subLabel: 'Outstanding Payable',
          subValue: _money(stats.totalOutstanding),
          subValueColor: AppColor.cashOut,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AccountantAllSupplierScreen(warehouseId: warehouseId),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Inventory (tap → warehouse inventory screen) ──────────────
        _MetricCard(
          icon: Icons.inventory_2_rounded,
          iconBg: const Color(0xFFE9FBF2),
          iconColor: AppColor.cashIn,
          title: 'Total Inventory',
          value: '${_num(stats.totalProducts)} items',
          subLabel: 'Stock Value',
          subValue: _money(stats.totalInventoryValue),
          subValueColor: AppColor.textDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AccountantWarehouseInventoryScreen(warehouseId: warehouseId),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Quantity in stock ─────────────────────────────────────────
        _MetricCard(
          icon: Icons.widgets_rounded,
          iconBg: const Color(0xFFFFF4E5),
          iconColor: Color(0xFFF59E0B),
          title: 'Stock Quantity',
          value: '${_qty(stats.totalInventoryQty)} units',
          subLabel: 'Active Products',
          subValue: _num(stats.totalProducts),
          subValueColor: AppColor.textDark,
        ),

        const SizedBox(height: 12),

        // ── Orders (tap → all orders screen) ──────────────────────────
        _MetricCard(
          icon: Icons.receipt_long_rounded,
          iconBg: const Color(0xFFEDEBFF),
          iconColor: AppColor.primary,
          title: 'Total Orders',
          value: '${_num(stats.totalOrders)} orders',
          subLabel: 'Orders Value',
          subValue: _money(stats.totalOrdersValue),
          subValueColor: AppColor.textDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AccountantAllOrdersScreen(warehouseId: warehouseId),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Stock Transfers (tap → all transfers screen) ──────────────
        _MetricCard(
          icon: Icons.swap_horiz_rounded,
          iconBg: const Color(0xFFE5F6FF),
          iconColor: Color(0xFF0EA5E9),
          title: 'Stock Transfers',
          value: '${_num(stats.totalTransfers)} transfers',
          subLabel: 'Transfer Value',
          subValue: _money(stats.totalTransfersValue),
          subValueColor: AppColor.textDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AccountantStockTransferRecordScreen(warehouseId: warehouseId),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Cash Transfers (tap → is warehouse ke cash transfers) ─────
        _MetricCard(
          icon: Icons.account_balance_wallet_rounded,
          iconBg: const Color(0xFFEFFCF3),
          iconColor: AppColor.cashIn,
          title: 'Cash Transfers',
          value: '${_num(stats.totalCashTransfers)} transfers',
          subLabel: 'Accepted Value',
          subValue: _money(stats.totalCashTransfersValue),
          subValueColor: AppColor.textDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AccountantCashTransfersScreen(warehouseId: warehouseId),
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  String _num(int v) => v.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  String _qty(double v) {
    final s = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return s.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'Rs. $s';
  }
}

// ── Cash Card ───────────────────────────────────────────────────────────────
class _CashCard extends StatelessWidget {
  final double amount;
  final VoidCallback? onTap;
  const _CashCard({required this.amount, this.onTap});

  String _money(double v) {
    final neg = v < 0;
    final s = v.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '${neg ? '- ' : ''}Rs. $s';
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Cash in Hand',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 13),
              ),
              const Spacer(),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _money(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(width: 4),
              // ── Send Cash button (abhi placeholder) ───────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SendCashDialog(),
                    );
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Send Cash',
                          style: TextStyle(
                            color: AppColor.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: card,
    );
  }
}

// ── Metric Card ─────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final String subLabel;
  final String subValue;
  final Color subValueColor;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subLabel,
    required this.subValue,
    required this.subValueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13, color: AppColor.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textDark,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                subLabel,
                style: const TextStyle(
                    fontSize: 11, color: AppColor.textMuted),
              ),
              const SizedBox(height: 3),
              Text(
                subValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: subValueColor,
                ),
              ),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColor.textMuted, size: 20),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}

// ── Loading State ───────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ShimmerBox(height: 130, radius: 20),
        const SizedBox(height: 16),
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _ShimmerBox(height: 84, radius: 16),
          ),
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double radius;
  const _ShimmerBox({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ── Error State ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Warehouse data load nahi hua — pull to refresh karein',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        ),
      );
}
