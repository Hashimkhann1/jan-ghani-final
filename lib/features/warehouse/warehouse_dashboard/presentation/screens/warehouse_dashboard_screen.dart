// =============================================================
// warehouse_dashboard_screen.dart
// Layout:
//   TopBar
//   → PurchaseFilterBar
//   → 4 Stat Cards
//   → PurchaseTrendChart      (full width)
//   → Row(Recent POs + Pending Transfers)
//   → Row(SupplierOutstandingChart + Supplier Dues)
//   → Row(Low Stock + Stock Movements)
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/domain/warehouse_dashboard_models.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/widgets/dashboard_chart_widgets/dashboard_chart_widgets.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/widgets/purchase_filter_bar/purchase_filter_bar.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/widgets/warehouse_dashboard_widgets/warehouse_dashboard_widgets.dart';
import '../../../../branch/authentication/presentation/provider/auth_provider.dart';
import '../provider/warehouse_dashboard_provider.dart';

class WarehouseDashboardScreen extends ConsumerStatefulWidget {
  const WarehouseDashboardScreen({super.key});

  @override
  ConsumerState<WarehouseDashboardScreen> createState() =>
      _WarehouseDashboardScreenState();
}

class _WarehouseDashboardScreenState
    extends ConsumerState<WarehouseDashboardScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(warehouseDashboardProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(warehouseDashboardProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
          ? _ErrorState(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(warehouseDashboardProvider.notifier).refresh(),
      )
          : Column(
        children: [
          // ── Top bar ────────────────────────────────
          _TopBar(stats: state.stats),

          // ── Scrollable content ─────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 4),

                  // ── Filter bar ─────────────────────
                  const PurchaseFilterBar(),
                  const SizedBox(height: 12),

                  // ── 4 stat cards ───────────────────
                  _StatCardsRow(stats: state.stats),
                  const SizedBox(height: 16),

                  // ── Purchase Trend Chart ────────────
                  PurchaseTrendChart(
                    points:    state.purchaseTrend,
                    filter:    state.activeFilter,
                    isLoading: state.isChartLoading,
                  ),
                  const SizedBox(height: 16),

                  // ── POs + Transfers ─────────────────
                  _PoAndTransferRow(
                    recentPOs:        state.recentPOs,
                    pendingTransfers: state.pendingTransfers,
                  ),
                  const SizedBox(height: 16),

                  // ── Supplier Chart + Supplier Dues ──
                  _SupplierRow(
                    bars:         state.supplierOutstandingBars,
                    supplierDues: state.supplierDues,
                    stockMovements: state.stockMovements,
                  ),
                  const SizedBox(height: 16),

                  // ── Low Stock + Stock Movements ─────
                  _LowStockAndMovementsRow(
                    lowStockItems:  state.lowStockItems,
                    stockMovements: state.stockMovements,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final stats;
  const _TopBar({this.stats});

  @override
  Widget build(BuildContext context) {
    final now     = DateTime.now();
    final weekday = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
    [now.weekday - 1];
    final month   = ['Jan','Feb','Mar','Apr','May','Jun','Jul',
      'Aug','Sep','Oct','Nov','Dec'][now.month - 1];
    final dateStr = '$weekday, ${now.day} $month ${now.year}';

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color:  AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.warehouse_outlined,
                size: 18, color: AppColor.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jan Ghani — Warehouse',
                  style: TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w700,
                      color:      AppColor.textPrimary)),
              Text('$dateStr  •  WH-MAIN',
                  style: TextStyle(
                      fontSize: 11, color: AppColor.textSecondary)),
            ],
          ),
          const Spacer(),

          // Unsynced pill
          if (stats != null && stats.unsyncedRecords > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:        AppColor.errorLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColor.error.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.error)),
                  const SizedBox(width: 5),
                  Text('${stats.unsyncedRecords} unsynced',
                      style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      AppColor.error)),
                ],
              ),
            ),
          const SizedBox(width: 10),

          // User pill
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border:       Border.all(color: AppColor.grey200),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ahmad',
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.textPrimary)),
                const SizedBox(width: 5),
                Container(
                    width: 4, height: 4,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.success)),
                const SizedBox(width: 4),
                Text('Owner',
                    style: TextStyle(
                        fontSize: 11,
                        color:    AppColor.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STAT CARDS ROW
// ─────────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  final DashboardStats? stats;
  const _StatCardsRow({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox();
    return Row(
      children: [
        DashStatCard(
          label:      'Total products',
          value:      _fmt(stats!.totalProducts.toDouble()),
          badge:      '${stats!.activeSuppliers} suppliers',
          icon:       Icons.inventory_2_outlined,
          color:      AppColor.primary,
          barPercent: (stats!.totalProducts / 2000).clamp(0.0, 1.0),
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'Low stock alerts',
          value:      '${stats!.lowStockCount}',
          badge:      stats!.lowStockCount > 0 ? 'Urgent' : 'All good',
          icon:       Icons.warning_amber_rounded,
          color:      stats!.lowStockCount > 0
              ? AppColor.error : AppColor.success,
          barPercent: (stats!.lowStockCount / 50).clamp(0.0, 1.0),
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'Supplier outstanding',
          value:      stats!.totalOutstanding.toStringAsFixed(2),
          badge:      '${stats!.activeSuppliers} active',
          icon:       Icons.account_balance_wallet_outlined,
          color:      AppColor.info,
          barPercent: (stats!.totalOutstanding / 200000).clamp(0.0, 1.0),
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'Total purchase amount',
          value:      stats!.totalPurchaseAmount.toStringAsFixed(2),
          badge:      '${stats!.totalOrdersCount} orders',
          icon:       Icons.receipt_long_outlined,
          color:      AppColor.textPrimary,
          barPercent: (stats!.totalPurchaseAmount / 500000).clamp(0.0, 1.0),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K+';
    return v.toStringAsFixed(0);
  }

  String _fmtRs(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────
// PO + TRANSFERS ROW
// ─────────────────────────────────────────────────────────────

class _PoAndTransferRow extends StatelessWidget {
  final recentPOs;
  final pendingTransfers;
  const _PoAndTransferRow({
    required this.recentPOs,
    required this.pendingTransfers,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SectionCard(
            headerIcon: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color:        AppColor.infoLight,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.receipt_long_outlined,
                  size: 13, color: AppColor.info),
            ),
            title: 'Recent purchase orders',
            headerTrailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        AppColor.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Latest 5',
                  style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.info)),
            ),
            children: recentPOs.isEmpty
                ? [const _EmptyState(
              icon:    Icons.receipt_long_outlined,
              message: 'No purchase orders yet',
            )]
                : [
              ...recentPOs.asMap().entries.map((e) {
                return _PoRow(
                    po:     e.value,
                    isLast: e.key == recentPOs.length - 1);
              }),
            ],
            footerLeft:  '${recentPOs.length} orders shown',
            footerRight: 'View all →',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: SectionCard(
            headerIcon: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color:        AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.swap_horiz_rounded,
                  size: 14, color: AppColor.primary),
            ),
            title: 'Pending transfers',
            headerTrailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${pendingTransfers.length} pending',
                  style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.primary)),
            ),
            children: pendingTransfers.isEmpty
                ? [const _EmptyState(
              icon:    Icons.swap_horiz_rounded,
              message: 'No pending transfers',
            )]
                : [
              ...pendingTransfers.asMap().entries.map((e) {
                return _TransferRow(
                    transfer: e.value,
                    isLast:   e.key == pendingTransfers.length - 1);
              }),
            ],
            footerLeft:  'Assigned transfers',
            footerRight: 'Manage →',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPLIER ROW — Chart (left) + Dues detail (right)
// ─────────────────────────────────────────────────────────────

class _SupplierRow extends StatelessWidget {
  final List<SupplierOutstandingBar> bars;
  final supplierDues;
  final stockMovements;

  const _SupplierRow({
    required this.bars,
    required this.supplierDues,
    required this.stockMovements
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Outstanding chart — left
        // Expanded(
        //   child: SupplierOutstandingChart(bars: bars),
        // ),
        // const SizedBox(width: 16),

        // Supplier dues detail — right
        SizedBox(width: MediaQuery.of(context).size.width * 0.45,
          child: SectionCard(
            headerIcon: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color:        AppColor.errorLight,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.account_balance_wallet_outlined,
                  size: 13, color: AppColor.error),
            ),
            title: 'Supplier dues',
            headerTrailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        AppColor.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_totalDues(),
                  style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.error)),
            ),
            children: supplierDues.isEmpty
                ? [const _EmptyState(
              icon:      Icons.account_balance_wallet_outlined,
              message:   'No outstanding dues',
              isSuccess: true,
            )]
                : [
              ...supplierDues.asMap().entries.map((e) {
                return SupplierDueRow(
                  key:    ValueKey(e.value.supplierId),
                  item:   e.value,
                  isLast: e.key == supplierDues.length - 1,
                );
              }),
            ],
            footerLeft:  'Supplier balances',
            footerRight: 'Pay all →',
          ),
        ),

        // Stock Movements
        Expanded(
          child: SectionCard(
            headerIcon: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color:        AppColor.successLight,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.swap_vert_rounded,
                  size: 14, color: AppColor.success),
            ),
            title: 'Stock movements',
            headerTrailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        AppColor.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Today',
                  style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.success)),
            ),
            children: stockMovements.isEmpty
                ? [const _EmptyState(
              icon:    Icons.swap_vert_rounded,
              message: 'No movements today',
            )]
                : [
              ...stockMovements.asMap().entries.map((e) {
                return MovementRow(
                  key:    ValueKey(e.value.id),
                  entry:  e.value,
                  isLast: e.key == stockMovements.length - 1,
                );
              }),
            ],
            footerLeft:  'Today\'s activity',
            footerRight: 'Full log →',
          ),
        ),
      ],
    );
  }

  String _totalDues() {
    double total = 0;
    for (final d in supplierDues) total += d.outstandingAmount;
    if (total >= 1000) return 'Rs ${(total / 1000).toStringAsFixed(0)}K total';
    return 'Rs ${total.toStringAsFixed(0)} total';
  }
}

// ─────────────────────────────────────────────────────────────
// LOW STOCK + MOVEMENTS ROW
// ─────────────────────────────────────────────────────────────

class _LowStockAndMovementsRow extends StatelessWidget {
  final lowStockItems;
  final stockMovements;

  const _LowStockAndMovementsRow({
    required this.lowStockItems,
    required this.stockMovements,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Low Stock
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          child: SectionCard(
            headerIcon: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: lowStockItems.isEmpty
                    ? AppColor.successLight : AppColor.errorLight,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(
                lowStockItems.isEmpty
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                size:  13,
                color: lowStockItems.isEmpty
                    ? AppColor.success : AppColor.error,
              ),
            ),
            title: 'Low stock',
            headerTrailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: lowStockItems.isEmpty
                    ? AppColor.successLight : AppColor.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                lowStockItems.isEmpty
                    ? 'All stocked' : '${lowStockItems.length} items',
                style: TextStyle(
                  fontSize:   10,
                  fontWeight: FontWeight.w600,
                  color: lowStockItems.isEmpty
                      ? AppColor.success : AppColor.error,
                ),
              ),
            ),
            children: lowStockItems.isEmpty
                ? [const _EmptyState(
              icon:      Icons.check_circle_outline_rounded,
              message:   'All products well stocked',
              isSuccess: true,
            )]
                : [
              ...lowStockItems.asMap().entries.take(4).map((e) {
                return StockProgressRow(
                  key:    ValueKey(e.value.productId),
                  item:   e.value,
                  isLast: e.key == 3 ||
                      e.key == lowStockItems.length - 1,
                );
              }),
            ],
            footerLeft:  'Reorder list',
            footerRight: 'View all →',
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PO ROW
// ─────────────────────────────────────────────────────────────

class _PoRow extends StatelessWidget {
  final po;
  final bool isLast;
  const _PoRow({required this.po, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: isLast ? null
            : Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color:        AppColor.grey100,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_outlined,
                size: 14, color: AppColor.grey500),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(po.poNumber,
                    style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      AppColor.primary)),
                Text(
                  '${po.supplierName}  •  ${_fmtDate(po.orderDate)}',
                  style: TextStyle(
                      fontSize: 11, color: AppColor.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PoStatusBadge(status: po.status),
              const SizedBox(height: 3),
              Text(po.totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontSize: 11, color: AppColor.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _fmtRs(double v) {
    if (v >= 100000) return 'Rs ${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────
// TRANSFER ROW
// ─────────────────────────────────────────────────────────────

class _TransferRow extends StatelessWidget {
  final transfer;
  final bool isLast;
  const _TransferRow({required this.transfer, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: isLast ? null
            : Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warehouse_outlined,
                  size: 13, color: AppColor.primary),
              const SizedBox(width: 4),
              Text(transfer.fromLocation,
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.textPrimary)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 12, color: AppColor.textSecondary),
              ),
              Icon(Icons.storefront_outlined,
                  size: 13, color: AppColor.success),
              const SizedBox(width: 4),
              Text(transfer.toLocation,
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      AppColor.textPrimary)),
              const Spacer(),
              TransferStatusBadge(status: transfer.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${transfer.transferNumber}  •  '
                '${transfer.totalItems} items  •  '
                '${_fmtRs(transfer.totalCost)}',
            style: TextStyle(
                fontSize: 11, color: AppColor.textSecondary),
          ),
        ],
      ),
    );
  }

  String _fmtRs(double v) {
    if (v >= 1000) return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE WIDGET
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;
  final bool     isSuccess;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppColor.success : AppColor.grey400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:   12,
              color:      AppColor.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: AppColor.error),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(color: AppColor.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}