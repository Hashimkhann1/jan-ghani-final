// =============================================================
// warehouse_dashboard_screen.dart
// Warehouse Home Screen
// Layout:
//   TopBar → 4 Stat Cards → Row(Recent POs + Pending Transfers)
//         → Row(Low Stock + Supplier Dues + Stock Movements)
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse_dashboard/presentation/widgets/warehouse_dashboard_widgets/warehouse_dashboard_widgets.dart';
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
        onRetry: () => ref
            .read(warehouseDashboardProvider.notifier)
            .refresh(),
      )
          : Column(
        children: [
          // ── Top bar ──────────────────────────────
          _TopBar(stats: state.stats),

          // ── Scrollable content ───────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── 4 stat cards ─────────────────
                  _StatCardsRow(stats: state.stats),
                  const SizedBox(height: 16),

                  // ── POs + Transfers ──────────────
                  _PoAndTransferRow(
                    recentPOs:       state.recentPOs,
                    pendingTransfers: state.pendingTransfers,
                  ),
                  const SizedBox(height: 16),

                  // ── Low Stock + Dues + Movements ─
                  _BottomRow(
                    lowStockItems:  state.lowStockItems,
                    supplierDues:   state.supplierDues,
                    stockMovements: state.stockMovements,
                  ),
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
          // Brand
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
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary)),
              Text('$dateStr  •  WH-MAIN',
                  style: TextStyle(fontSize: 11,
                      color: AppColor.textSecondary)),
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
                border:       Border.all(
                    color: AppColor.error.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.error)),
                  const SizedBox(width: 5),
                  Text('${stats.unsyncedRecords} unsynced',
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColor.error)),
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
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color:  AppColor.primary.withOpacity(0.1),
                    shape:  BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('AO',
                      style: TextStyle(fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary)),
                ),
                const SizedBox(width: 7),
                Text('Ahmed',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary)),
                const SizedBox(width: 5),
                Container(width: 4, height: 4,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.success)),
                const SizedBox(width: 4),
                Text('Owner',
                    style: TextStyle(fontSize: 11,
                        color: AppColor.textSecondary)),
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
  final stats;
  const _StatCardsRow({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox();
    return Row(
      children: [
        DashStatCard(
          label:      'Total products',
          value:      _fmt(stats.totalProducts.toDouble()),
          badge:      '+12 today',
          icon:       Icons.inventory_2_outlined,
          color:      AppColor.primary,
          barPercent: 0.78,
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'Low stock alerts',
          value:      '${stats.lowStockCount}',
          badge:      'Urgent',
          icon:       Icons.warning_amber_rounded,
          color:      AppColor.error,
          barPercent: stats.lowStockCount / 100,
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'Supplier outstanding',
          value:      _fmtRs(stats.totalOutstanding),
          badge:      '${stats.activeSuppliers} active',
          icon:       Icons.account_balance_wallet_outlined,
          color:      AppColor.info,
          barPercent: 0.56,
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'Purchase orders',
          value:      '${stats.pendingPOs}',
          badge:      '${stats.pendingPOs} pending',
          icon:       Icons.receipt_long_outlined,
          color:      AppColor.warning,
          barPercent: stats.pendingPOs / 20,
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
        // Recent POs — wider
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
            title:        'Recent purchase orders',
            headerTrailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        AppColor.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('purchase_orders',
                  style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColor.info)),
            ),
            children: [
              ...recentPOs.asMap().entries.map((e) {
                final po     = e.value;
                final isLast = e.key == recentPOs.length - 1;
                return _PoRow(po: po, isLast: isLast);
              }),
            ],
            footerLeft:  '${recentPOs.length} of 21 orders',
            footerRight: 'View all →',
          ),
        ),
        const SizedBox(width: 16),

        // Pending Transfers
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
              child: Text(
                  '${pendingTransfers.length} pending',
                  style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColor.primary)),
            ),
            children: [
              ...pendingTransfers.asMap().entries.map((e) {
                final t      = e.value;
                final isLast = e.key == pendingTransfers.length - 1;
                return _TransferRow(transfer: t, isLast: isLast);
              }),
            ],
            footerLeft:  'v_pending_transfers',
            footerRight: 'Manage →',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PO ROW (inside _PoAndTransferRow)
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
          // PO icon
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

          // PO number + supplier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(po.poNumber,
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primary)),
                Text(
                  '${po.supplierName}  •  ${_fmtDate(po.orderDate)}',
                  style: TextStyle(fontSize: 11,
                      color: AppColor.textSecondary),
                ),
              ],
            ),
          ),

          // Status + amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PoStatusBadge(status: po.status),
              const SizedBox(height: 3),
              Text(_fmtRs(po.totalAmount),
                  style: TextStyle(fontSize: 11,
                      color: AppColor.textSecondary)),
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
              // From → To
              Icon(Icons.warehouse_outlined,
                  size: 13, color: AppColor.primary),
              const SizedBox(width: 4),
              Text(transfer.fromLocation,
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 12, color: AppColor.textSecondary),
              ),
              Icon(Icons.storefront_outlined,
                  size: 13, color: AppColor.success),
              const SizedBox(width: 4),
              Text(transfer.toLocation,
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary)),
              const Spacer(),
              TransferStatusBadge(status: transfer.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${transfer.transferNumber}  •  '
                '${transfer.totalItems} items  •  '
                '${_fmtRs(transfer.totalCost)}',
            style: TextStyle(fontSize: 11,
                color: AppColor.textSecondary),
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
// BOTTOM ROW — Low Stock + Dues + Movements
// ─────────────────────────────────────────────────────────────

class _BottomRow extends StatelessWidget {
  final lowStockItems;
  final supplierDues;
  final stockMovements;

  const _BottomRow({
    required this.lowStockItems,
    required this.supplierDues,
    required this.stockMovements,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Low Stock
        Expanded(
          child: SectionCard(
            headerIcon: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color:        AppColor.errorLight,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.warning_amber_rounded,
                  size: 13, color: AppColor.error),
            ),
            title: 'Low stock',
            headerTrailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        AppColor.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${lowStockItems.length} items',
                  style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColor.error)),
            ),
            children: [
              ...lowStockItems.asMap().entries.take(4).map((e) {
                return StockProgressRow(
                  key:    ValueKey(e.value.productId),
                  item:   e.value,
                  isLast: e.key == 3 ||
                      e.key == lowStockItems.length - 1,
                );
              }),
            ],
            footerLeft:  'v_reorder_needed',
            footerRight: 'View all →',
          ),
        ),
        const SizedBox(width: 16),

        // Supplier Dues
        Expanded(
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
                  style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColor.error)),
            ),
            children: [
              ...supplierDues.asMap().entries.map((e) {
                return SupplierDueRow(
                  key:    ValueKey(e.value.supplierId),
                  item:   e.value,
                  isLast: e.key == supplierDues.length - 1,
                );
              }),
            ],
            footerLeft:  'v_supplier_balances',
            footerRight: 'Pay all →',
          ),
        ),
        const SizedBox(width: 16),

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
                  style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColor.success)),
            ),
            children: [
              ...stockMovements.asMap().entries.map((e) {
                return MovementRow(
                  key:    ValueKey(e.value.id),
                  entry:  e.value,
                  isLast: e.key == stockMovements.length - 1,
                );
              }),
            ],
            footerLeft:  'stock_movements',
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