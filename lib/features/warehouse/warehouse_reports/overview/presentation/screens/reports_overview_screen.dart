// =============================================================
// reports_overview_screen.dart
//
// Reports ka LANDING dashboard — saari reports ka data ek nazar mein
// cards ke roop mein. Har card tap karne par us report par navigate
// hota hai (shell ke `onOpenReport` callback se).
//
// NOTE: Ye screen koi nayi query/datasource nahi chalati — sirf pehle se
// maujood report PROVIDERS ka state parhti hai (platform-aware pehle se).
// Isliye web support automatically milta hai. Har group apne provider ke
// `isLoading` par react karta hai (progressive load — poori screen block nahi).
//
// ⚠️ Time-windows (providers ke default filter ke hisaab se, honest labels):
//   • Inventory (Total Products / Value)     → all-time
//   • Suppliers (count / Outstanding)        → live
//   • Cash in Hand                           → live
//   • Purchases / Cash In-Out / Paid / Expense / Transfers → is mahine (This month)
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/cash_flow/presentation/providers/cash_flow_report_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/expense/presentation/providers/expense_report_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/inventory/presentation/providers/inventory_report_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/purchase/presentation/providers/purchase_report_provider.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/supplier/presentation/providers/supplier_report_provider.dart';

// ─────────────────────────────────────────────────────────────
// SHELL ke report indices (warehouse_reports_shell.dart ka _reports order).
// 0 = Dashboard (yehi screen). Baaki reports ke navigation targets:
// ─────────────────────────────────────────────────────────────
class ReportTab {
  static const dashboard = 0;
  static const inventory = 1;
  static const purchases = 2;
  static const transfers = 3; // abhi coming soon → transfer card inventory par bhejta hai
  static const suppliers = 4;
  static const cashFlow  = 5;
  static const expenses  = 6;
}

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class ReportsOverviewScreen extends ConsumerWidget {
  // Shell ka _selectReport — card tap par report kholne ke liye.
  final void Function(int reportIndex) onOpenReport;
  const ReportsOverviewScreen({super.key, required this.onOpenReport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [
          _TopBar(onRefreshAll: () => _refreshAll(ref)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InventorySection(onOpenReport: onOpenReport),
                  const SizedBox(height: 18),
                  _PurchaseSection(onOpenReport: onOpenReport),
                  const SizedBox(height: 18),
                  _SupplierSection(onOpenReport: onOpenReport),
                  const SizedBox(height: 18),
                  _CashExpenseSection(onOpenReport: onOpenReport),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Har report provider ko dobara load karao.
  void _refreshAll(WidgetRef ref) {
    ref.read(purchaseReportProvider.notifier).refresh();
    ref.read(supplierReportProvider.notifier).refresh();
    ref.read(cashFlowReportProvider.notifier).refresh();
    ref.read(expenseReportProvider.notifier).refresh();
    ref.invalidate(inventoryTransfersProvider);
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onRefreshAll;
  const _TopBar({required this.onRefreshAll});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.grey200)),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.dashboard_rounded, size: 18, color: AppColor.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reports Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
              Text('As of $dateStr  •  Sab reports ka khulasa',
                  style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onRefreshAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColor.grey100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColor.grey200),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 13, color: AppColor.grey600),
                  SizedBox(width: 5),
                  Text('Refresh',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColor.grey700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// SECTIONS
// ═════════════════════════════════════════════════════════════

// ── Inventory ────────────────────────────────────────────────
class _InventorySection extends ConsumerWidget {
  final void Function(int) onOpenReport;
  const _InventorySection({required this.onOpenReport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv       = ref.watch(inventoryReportProvider);
    final transfers = ref.watch(inventoryTransfersProvider);

    // This-month transfers (list se compute)
    final now = DateTime.now();
    final monthTransfers = transfers.transfers
        .where((t) => t.assignedAt.year == now.year && t.assignedAt.month == now.month)
        .toList();
    final trfCost = monthTransfers.fold<double>(0, (s, t) => s + t.totalCost);

    return _Section(
      title: 'Inventory',
      icon: Icons.inventory_2_outlined,
      color: AppColor.primary,
      onViewReport: () => onOpenReport(ReportTab.inventory),
      cards: [
        _OverviewCard(
          label: 'Total Products',
          value: '${inv.totalActive}',
          badge: 'Active',
          icon: Icons.inventory_2_outlined,
          color: AppColor.primary,
          loading: inv.isLoading,
          onTap: () => onOpenReport(ReportTab.inventory),
        ),
        _OverviewCard(
          label: 'Inventory Value',
          value: 'Rs ${inv.totalPurchaseValue.pkrFormat}',
          badge: 'Purchase cost',
          icon: Icons.currency_rupee_rounded,
          color: AppColor.success,
          loading: inv.isLoading,
          onTap: () => onOpenReport(ReportTab.inventory),
        ),
        _OverviewCard(
          label: 'Transfers',
          value: '${monthTransfers.length}',
          badge: 'This month • Rs ${trfCost.pkrFormat}',
          icon: Icons.local_shipping_outlined,
          color: AppColor.info,
          loading: transfers.isLoading,
          onTap: () => onOpenReport(ReportTab.inventory),
        ),
      ],
    );
  }
}

// ── Purchases ────────────────────────────────────────────────
class _PurchaseSection extends ConsumerWidget {
  final void Function(int) onOpenReport;
  const _PurchaseSection({required this.onOpenReport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(purchaseReportProvider);
    final s  = st.summary;

    return _Section(
      title: 'Purchases',
      icon: Icons.receipt_long_outlined,
      color: AppColor.info,
      onViewReport: () => onOpenReport(ReportTab.purchases),
      cards: [
        _OverviewCard(
          label: 'Total POs',
          value: '${s?.totalPos ?? 0}',
          badge: 'This month',
          icon: Icons.receipt_long_outlined,
          color: AppColor.primary,
          loading: st.isLoading,
          onTap: () => onOpenReport(ReportTab.purchases),
        ),
        _OverviewCard(
          label: 'Purchased',
          value: 'Rs ${(s?.thisMonthValue ?? 0).pkrFormat}',
          badge: 'This month • received',
          icon: Icons.shopping_cart_checkout_rounded,
          color: AppColor.success,
          loading: st.isLoading,
          onTap: () => onOpenReport(ReportTab.purchases),
        ),
        _OverviewCard(
          label: 'Pending POs',
          value: '${s?.pendingCount ?? 0}',
          badge: 'Awaiting',
          icon: Icons.hourglass_empty_rounded,
          color: AppColor.warning,
          loading: st.isLoading,
          onTap: () => onOpenReport(ReportTab.purchases),
        ),
      ],
    );
  }
}

// ── Suppliers ────────────────────────────────────────────────
class _SupplierSection extends ConsumerWidget {
  final void Function(int) onOpenReport;
  const _SupplierSection({required this.onOpenReport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(supplierReportProvider);
    final s  = st.summary;

    // "Paid to Supplier" — cash flow ke typeBreakdown se (is mahine)
    final cf = ref.watch(cashFlowReportProvider);
    final paidToSupplier = cf.typeBreakdown
        .where((t) => t.type == 'supplier_payment')
        .fold<double>(0, (sum, t) => sum + t.amount);

    return _Section(
      title: 'Suppliers',
      icon: Icons.people_outline,
      color: AppColor.warning,
      onViewReport: () => onOpenReport(ReportTab.suppliers),
      cards: [
        _OverviewCard(
          label: 'Total Suppliers',
          value: '${s?.totalActive ?? 0}',
          badge: 'Active',
          icon: Icons.people_outline,
          color: AppColor.primary,
          loading: st.isLoading,
          onTap: () => onOpenReport(ReportTab.suppliers),
        ),
        _OverviewCard(
          label: 'Total Outstanding',
          value: 'Rs ${(s?.totalOutstanding ?? 0).pkrFormat}',
          badge: 'Payable',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColor.error,
          loading: st.isLoading,
          onTap: () => onOpenReport(ReportTab.suppliers),
        ),
        _OverviewCard(
          label: 'Paid to Supplier',
          value: 'Rs ${paidToSupplier.pkrFormat}',
          badge: 'This month',
          icon: Icons.payments_outlined,
          color: AppColor.success,
          loading: cf.isLoading,
          onTap: () => onOpenReport(ReportTab.suppliers),
        ),
      ],
    );
  }
}

// ── Cash & Expense ───────────────────────────────────────────
class _CashExpenseSection extends ConsumerWidget {
  final void Function(int) onOpenReport;
  const _CashExpenseSection({required this.onOpenReport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cf  = ref.watch(cashFlowReportProvider);
    final exp = ref.watch(expenseReportProvider);
    final cs  = cf.summary;

    return _Section(
      title: 'Cash & Expense',
      icon: Icons.account_balance_wallet_outlined,
      color: AppColor.success,
      onViewReport: () => onOpenReport(ReportTab.cashFlow),
      cards: [
        _OverviewCard(
          label: 'Cash in Hand',
          value: 'Rs ${(cs?.cashInHand ?? 0).pkrFormat}',
          badge: 'Live balance',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColor.primary,
          loading: cf.isLoading,
          onTap: () => onOpenReport(ReportTab.cashFlow),
        ),
        _OverviewCard(
          label: 'Cash In',
          value: 'Rs ${(cs?.periodCashIn ?? 0).pkrFormat}',
          badge: 'This month',
          icon: Icons.south_west_rounded,
          color: AppColor.success,
          loading: cf.isLoading,
          onTap: () => onOpenReport(ReportTab.cashFlow),
        ),
        _OverviewCard(
          label: 'Cash Out',
          value: 'Rs ${(cs?.periodCashOut ?? 0).pkrFormat}',
          badge: 'This month',
          icon: Icons.north_east_rounded,
          color: AppColor.error,
          loading: cf.isLoading,
          onTap: () => onOpenReport(ReportTab.cashFlow),
        ),
        _OverviewCard(
          label: 'Total Expense',
          value: 'Rs ${(exp.summary?.totalAmount ?? 0).pkrFormat}',
          badge: 'This month',
          icon: Icons.receipt_long_outlined,
          color: AppColor.warning,
          loading: exp.isLoading,
          onTap: () => onOpenReport(ReportTab.expenses),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// SECTION WRAPPER (header + responsive card grid)
// ═════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onViewReport;
  final List<Widget> cards;

  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.onViewReport,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (tap → report)
        GestureDetector(
          onTap: onViewReport,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
                const Spacer(),
                Text('View report',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                Icon(Icons.chevron_right_rounded, size: 16, color: color),
              ],
            ),
          ),
        ),
        // Responsive grid
        LayoutBuilder(
          builder: (context, c) {
            final perRow = c.maxWidth >= 760 ? 3 : (c.maxWidth >= 480 ? 2 : 1);
            return _cardGrid(cards, perRow);
          },
        ),
      ],
    );
  }
}

// Cards ko responsive rows mein arrange karo. _OverviewCard khud Expanded
// return karta hai → seedha Row mein. Adhoori aakhri row ko Expanded(SizedBox)
// se pad karte hain. NOTE: Row par crossAxisAlignment.stretch NAHI (scroll
// view mein infinite height crash) — start use karo.
Widget _cardGrid(List<Widget> cards, int perRow) {
  final rows = <Widget>[];
  for (int i = 0; i < cards.length; i += perRow) {
    final end   = (i + perRow) > cards.length ? cards.length : i + perRow;
    final chunk = cards.sublist(i, end);
    final children = <Widget>[];
    for (int j = 0; j < chunk.length; j++) {
      if (j > 0) children.add(const SizedBox(width: 12));
      children.add(chunk[j]);
    }
    for (int k = chunk.length; k < perRow; k++) {
      children.add(const SizedBox(width: 12));
      children.add(const Expanded(child: SizedBox()));
    }
    if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
    rows.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ));
  }
  return Column(children: rows);
}

// ═════════════════════════════════════════════════════════════
// OVERVIEW CARD (tappable)
// ═════════════════════════════════════════════════════════════

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.badge,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColor.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 15, color: color),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColor.grey400),
                  ],
                ),
                const SizedBox(height: 12),
                loading
                    ? Container(
                        width: 72, height: 18,
                        decoration: BoxDecoration(
                          color: AppColor.grey100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(value,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColor.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(badge,
                    style: const TextStyle(fontSize: 10, color: AppColor.textHint),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
