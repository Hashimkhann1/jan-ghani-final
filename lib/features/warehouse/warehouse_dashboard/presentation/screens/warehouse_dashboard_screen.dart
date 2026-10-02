// Updated on 2026-10-02 09:31 AM
// =============================================================
// warehouse_dashboard_screen.dart — Dashboard v2 (Stitch design)
// Layout:
//   TopBar (title · code chip · unsynced · user · refresh)
//   → Filter pills (Today / Week / Month / 3 Months / Custom)
//   → 5 KPI cards
//   → Needs attention (5 tiles → sidebar screens)
//   → Row(Purchases vs Cash out chart 60% + Top supplier dues 40%)
//   → Row(Low stock — reorder 50% + Recent stock movements 50%)
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/config/app_config.dart';
import 'package:jan_ghani_final/features/warehouse/auth/presentation/provider/auth_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_cash_requests/presentation/provider/warehouse_cash_requests_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_cash_requests/presentation/screen/warehouse_cash_requests_screen.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/domain/warehouse_dashboard_models.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/widgets/dashboard_v2/dashboard_v2_widgets.dart';
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

  // Sidebar ko us screen par bhejo (label = sidebar item ka naam)
  void _goTo(String label) =>
      ref.read(dashboardNavRequestProvider.notifier).state = label;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(warehouseDashboardProvider);
    final s     = state.summary;

    return Scaffold(
      backgroundColor: AppColor.grey100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            unsynced:     s?.unsyncedRecords ?? 0,
            isRefreshing: state.isRefreshing,
            onRefresh:    () =>
                ref.read(warehouseDashboardProvider.notifier).refresh(),
          ),
          Expanded(
            child: state.isLoading || (s == null && state.errorMessage == null)
                ? const Center(child: CircularProgressIndicator())
                : s == null
                    ? _ErrorState(
                        message: state.errorMessage!,
                        onRetry: () => ref
                            .read(warehouseDashboardProvider.notifier)
                            .loadDashboard(),
                      )
                    : _Body(state: state, summary: s, goTo: _goTo),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────
class _Body extends ConsumerWidget {
  final WarehouseDashboardState state;
  final DashboardSummary        summary;
  final void Function(String)   goTo;

  const _Body({required this.state, required this.summary, required this.goTo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s            = summary;
    final cashRequests = ref.watch(pendingCashRequestsProvider)
        .valueOrNull?.length ?? 0;
    final period       = state.activeFilter.shortLabel;

    return LayoutBuilder(builder: (context, c) {
      final w      = c.maxWidth - 48; // padding 24 + 24
      final wide   = w >= 1000;
      const gap    = 20.0;

      // ── KPI cards ────────────────────────────────────────
      final kpis = <Widget>[
        DashKpiCard(
          label: 'Cash in hand',
          value: rs(s.cashInHand),
          icon:  Icons.account_balance_wallet_outlined,
          color: AppColor.primary,
          bg:    AppColor.primary.withOpacity(0.1),
          sub: Text.rich(TextSpan(children: [
            TextSpan(text: '+${rs(s.periodCashIn)} in',
                style: const TextStyle(color: AppColor.success)),
            const TextSpan(text: '  ·  '),
            TextSpan(text: '−${rs(s.periodCashOut)} out',
                style: const TextStyle(color: AppColor.error)),
          ])),
        ),
        DashKpiCard(
          label: 'Purchases ($period)',
          value: rs(s.purchaseAmount),
          icon:  Icons.shopping_bag_outlined,
          color: AppColor.info,
          bg:    AppColor.infoLight,
          sub: Text.rich(TextSpan(children: [
            TextSpan(text: '${s.purchaseCount} POs',
                style: const TextStyle(color: AppColor.textPrimary)),
            const TextSpan(text: ' received'),
          ])),
        ),
        DashKpiCard(
          label: 'Supplier outstanding',
          value: rs(s.supplierOutstanding),
          icon:  Icons.receipt_long_outlined,
          color: AppColor.error,
          bg:    AppColor.errorLight,
          sub: Text.rich(TextSpan(children: [
            TextSpan(text: '${s.suppliersWithDues} suppliers',
                style: const TextStyle(color: AppColor.error)),
            const TextSpan(text: ' with dues'),
          ])),
        ),
        DashKpiCard(
          label: 'Expenses ($period)',
          value: rs(s.expenseAmount),
          icon:  Icons.money_off_rounded,
          color: AppColor.warningDark,
          bg:    AppColor.warningLight,
          sub:   Text('incl. salary ${rs(s.salaryAmount)}'),
        ),
        DashKpiCard(
          label: 'Inventory value',
          value: rs(s.inventoryValue),
          icon:  Icons.inventory_2_outlined,
          color: AppColor.success,
          bg:    AppColor.successLight,
          sub:   Text('${s.activeProducts} products at purchase price'),
        ),
      ];

      Widget kpiRow;
      if (w >= 1150) {
        kpiRow = Row(children: [
          for (var i = 0; i < kpis.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: kpis[i]),
          ],
        ]);
      } else {
        final cols = w >= 760 ? 3 : (w >= 480 ? 2 : 1);
        final cw   = (w - 16 * (cols - 1)) / cols;
        kpiRow = Wrap(
          spacing: 16, runSpacing: 16,
          children: kpis.map((k) => SizedBox(width: cw, child: k)).toList(),
        );
      }

      // ── Needs attention ──────────────────────────────────
      final attention = NeedsAttentionCard(
        narrow: w < 1150,
        items: [
          AttentionItem(
            title: 'Low stock', hint: 'reorder now', count: s.lowStockCount,
            color: AppColor.error, bg: AppColor.errorLight,
            onTap: () => goTo('Stock'),
          ),
          AttentionItem(
            title: 'Out of stock', hint: 'critical shortage',
            count: s.outOfStockCount,
            color: AppColor.error, bg: AppColor.errorLight,
            onTap: () => goTo('Stock'),
          ),
          AttentionItem(
            title: 'Pending POs', hint: 'draft / ordered / partial',
            count: s.pendingPOs,
            color: AppColor.info, bg: AppColor.infoLight,
            onTap: () => goTo('Purchase Order'),
          ),
          AttentionItem(
            title: 'Pending transfers', hint: 'awaiting store accept',
            count: s.pendingTransfers,
            color: AppColor.primary, bg: AppColor.primary.withOpacity(0.1),
            onTap: () => goTo('Assign Stock'),
          ),
          AttentionItem(
            title: 'Cash requests', hint: 'accountant se aayi cash',
            count: cashRequests,
            color: AppColor.warningDark, bg: AppColor.warningLight,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const WarehouseCashRequestsScreen())),
          ),
        ],
      );

      // ── Row 3: chart + dues ──────────────────────────────
      const row3H = 450.0;
      final chart = SizedBox(
        height: row3H,
        child: PurchaseCashChartCard(
            points: state.trend, filter: state.activeFilter),
      );
      final dues = SizedBox(
        height: row3H,
        child: SupplierDuesCard(
            dues: state.supplierDues, onViewAll: () => goTo('Supplier')),
      );

      // ── Row 4: low stock + movements ─────────────────────
      const row4H = 580.0;
      final low = SizedBox(
        height: row4H,
        child: LowStockCard(
          rows:       state.lowStock,
          totalCount: s.lowStockCount,
          onViewAll:  () => goTo('Stock'),
        ),
      );
      final moves = SizedBox(
        height: row4H,
        child: MovementsCard(movements: state.movements),
      );

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterBar(state: state),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(
                message: state.errorMessage!,
                onRetry: () =>
                    ref.read(warehouseDashboardProvider.notifier).refresh(),
              ),
            ],
            const SizedBox(height: gap),
            kpiRow,
            const SizedBox(height: gap),
            attention,
            const SizedBox(height: gap),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: chart),
                const SizedBox(width: gap),
                Expanded(flex: 2, child: dues),
              ])
            else ...[chart, const SizedBox(height: gap), dues],
            const SizedBox(height: gap),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: low),
                const SizedBox(width: gap),
                Expanded(child: moves),
              ])
            else ...[low, const SizedBox(height: gap), moves],
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  final int          unsynced;
  final bool         isRefreshing;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.unsynced,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final now  = DateTime.now();
    final wd   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][now.weekday - 1];
    final mo   = ['Jan','Feb','Mar','Apr','May','Jun','Jul',
                  'Aug','Sep','Oct','Nov','Dec'][now.month - 1];
    final code = AppConfig.warehouseCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color:  AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.warehouse_outlined,
                size: 20, color: AppColor.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  const Flexible(
                    child: Text('Jan Ghani — Warehouse',
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (code.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    DashChip(text: code,
                        color: AppColor.success, bg: AppColor.successLight),
                  ],
                ]),
                const SizedBox(height: 2),
                Text('$wd, ${now.day} $mo ${now.year}  •  ${AppConfig.warehouseName}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (unsynced > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:        AppColor.errorLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColor.error.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColor.error)),
                const SizedBox(width: 6),
                Text('$unsynced unsynced',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColor.error)),
              ]),
            ),
            const SizedBox(width: 10),
          ],
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:        AppColor.grey100,
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: AppColor.grey200),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.account_circle_outlined,
                    size: 16, color: AppColor.textSecondary),
                const SizedBox(width: 8),
                Text(user.fullName.toString(),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary)),
                Container(width: 1, height: 14, color: AppColor.grey300,
                    margin: const EdgeInsets.symmetric(horizontal: 10)),
                Text(user.role.toString(),
                    style: const TextStyle(
                        fontSize: 12, color: AppColor.textSecondary)),
              ]),
            ),
            const SizedBox(width: 10),
          ],
          Tooltip(
            message: 'Refresh',
            child: InkWell(
              onTap:        isRefreshing ? null : onRefresh,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: AppColor.grey200),
                ),
                alignment: Alignment.center,
                child: isRefreshing
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded,
                        size: 20, color: AppColor.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER BAR — segmented pills + info
// ─────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  final WarehouseDashboardState state;
  const _FilterBar({required this.state});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(warehouseDashboardProvider.notifier);
    final active   = state.activeFilter;

    Widget pill(String label, PurchaseDateFilter f, {IconData? icon,
        VoidCallback? onTap}) {
      final on = active == f;
      return InkWell(
        onTap: onTap ?? () => notifier.applyFilter(f),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:        on ? AppColor.primary : AppColor.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 15,
                  color: on ? AppColor.white : AppColor.textPrimary),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: on ? AppColor.white : AppColor.textPrimary,
                )),
          ]),
        ),
      );
    }

    Future<void> pickCustom() async {
      final now   = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final picked = await showDateRangePicker(
        context:   context,
        firstDate: DateTime(2020),
        lastDate:  today,
        initialDateRange: state.customFrom != null && state.customTo != null
            ? DateTimeRange(start: state.customFrom!, end: state.customTo!)
            : DateTimeRange(
                start: today.subtract(const Duration(days: 6)), end: today),
        helpText: 'Dashboard date range',
        saveText: 'Apply',
      );
      if (picked != null) notifier.applyCustomRange(picked.start, picked.end);
    }

    final customLabel = active == PurchaseDateFilter.custom &&
            state.customFrom != null && state.customTo != null
        ? '${_fmt(state.customFrom!)} – ${_fmt(state.customTo!)}'
        : 'Custom range';

    return Wrap(
      spacing: 16, runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color:        AppColor.surface,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: AppColor.grey200),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            pill('Today',         PurchaseDateFilter.today),
            pill('This Week',     PurchaseDateFilter.thisWeek),
            pill('This Month',    PurchaseDateFilter.thisMonth),
            pill('Last 3 Months', PurchaseDateFilter.last3Months),
            pill(customLabel,     PurchaseDateFilter.custom,
                icon: Icons.calendar_today_outlined, onTap: pickCustom),
          ]),
        ),
        const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.info_outline_rounded,
              size: 15, color: AppColor.textSecondary),
          SizedBox(width: 6),
          Text('Filter applies to purchases, cash, expenses and movements',
              style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
        ]),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERRORS
// ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColor.errorLight,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColor.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 18, color: AppColor.error),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: const TextStyle(fontSize: 12, color: AppColor.error),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColor.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColor.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
