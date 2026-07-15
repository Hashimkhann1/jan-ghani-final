// =============================================================
// supplier_report_screen.dart
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/widgets/warehouse_dashboard_widgets/warehouse_dashboard_widgets.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/supplier/data/datasources/supplier_report_local_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/supplier/presentation/providers/supplier_report_provider.dart';

// ─────────────────────────────────────────────────────────────
// CHART COLORS
// ─────────────────────────────────────────────────────────────

const _kChartColors = [
  AppColor.primary,
  AppColor.success,
  AppColor.warning,
  AppColor.error,
  AppColor.info,
  Color(0xFF9C27B0),
];

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class SupplierReportScreen extends StatelessWidget {
  const SupplierReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [
          _TopBar(),
          Expanded(child: _Body()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supplierReportProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColor.error, size: 36),
            const SizedBox(height: 12),
            const Text('Data load nahi hua', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
            const SizedBox(height: 6),
            Text(state.error!, style: const TextStyle(fontSize: 11, color: AppColor.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref.read(supplierReportProvider.notifier).refresh(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Retry', style: TextStyle(color: AppColor.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary cards ─────────────────────────
          if (state.summary != null) _SummaryCardsRow(summary: state.summary!),
          const SizedBox(height: 16),

          // ── Top suppliers by Outstanding (horizontal bar) ──
          _TopOutstandingChart(items: state.topByBalance),
          const SizedBox(height: 16),

          // ── Supplier balance table ────────────────
          _SupplierBalanceTable(suppliers: state.allSuppliers),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends ConsumerStatefulWidget {
  const _TopBar();

  @override
  ConsumerState<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<_TopBar> {
  Future<void> _showCustomPicker() async {
    final notifier = ref.read(supplierReportProvider.notifier);
    final st       = ref.read(supplierReportProvider);

    final now       = DateTime.now();
    final firstDate = DateTime(2020);
    final lastDate  = DateTime(now.year, now.month, now.day);

    // initial range ko firstDate..lastDate ke andar clamp karo,
    // warna picker assert karke crash karta hai (end > lastDate).
    DateTime clamp(DateTime d) {
      if (d.isBefore(firstDate)) return firstDate;
      if (d.isAfter(lastDate))   return lastDate;
      return d;
    }

    DateTime start = clamp(st.dateFrom ?? now.subtract(const Duration(days: 30)));
    DateTime end   = clamp(st.dateTo ?? now);
    if (start.isAfter(end)) start = end;

    final picked = await showDateRangePicker(
      context: context,
      firstDate:        firstDate,
      lastDate:         lastDate,
      initialDateRange: DateTimeRange(start: start, end: end),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColor.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      notifier.setCustomRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(supplierReportProvider);
    final notifier = ref.read(supplierReportProvider.notifier);

    final now     = DateTime.now();
    const months  = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
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
            child: const Icon(Icons.people_outline, size: 18, color: AppColor.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Supplier Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
              Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
            ],
          ),
          const Spacer(),

          // ── Date filter pills ─────────────────────────────
          _FilterPill(
            label:    'Overall',
            selected: state.filterMode == DateFilterMode.overall,
            onTap:    notifier.setOverall,
          ),
          const SizedBox(width: 6),
          _FilterPill(
            label:    'This Month',
            selected: state.filterMode == DateFilterMode.currentMonth,
            onTap:    notifier.setCurrentMonth,
          ),
          const SizedBox(width: 6),
          _CustomPill(state: state, onTap: _showCustomPicker),

          const SizedBox(width: 10),

          // ── Refresh button ────────────────────────────────
          GestureDetector(
            onTap: notifier.refresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:        AppColor.grey100,
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: AppColor.grey200),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 13, color: AppColor.grey600),
                  SizedBox(width: 5),
                  Text('Refresh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColor.grey700)),
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
// FILTER PILLS
// ─────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? AppColor.primary : AppColor.grey100,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: selected ? AppColor.primary : AppColor.grey200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      selected ? AppColor.white : AppColor.grey600,
          ),
        ),
      ),
    );
  }
}

class _CustomPill extends StatelessWidget {
  final SupplierReportState state;
  final VoidCallback onTap;

  const _CustomPill({required this.state, required this.onTap});

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  String get _label {
    if (state.filterMode != DateFilterMode.custom ||
        state.dateFrom == null || state.dateTo == null) {
      return 'Custom ▾';
    }
    final f = state.dateFrom!;
    final t = state.dateTo!;
    return '${_months[f.month - 1]} ${f.day} – ${_months[t.month - 1]} ${t.day} ▾';
  }

  @override
  Widget build(BuildContext context) {
    final selected = state.filterMode == DateFilterMode.custom;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        selected ? AppColor.primary : AppColor.grey100,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: selected ? AppColor.primary : AppColor.grey200),
        ),
        child: Text(
          _label,
          style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      selected ? AppColor.white : AppColor.grey600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUMMARY CARDS ROW (4 cards)
// ─────────────────────────────────────────────────────────────

class _SummaryCardsRow extends StatelessWidget {
  final SupplierSummaryData summary;
  const _SummaryCardsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      DashStatCard(
        label:      'Total Suppliers',
        value:      summary.totalActive.toString(),
        badge:      'Active',
        icon:       Icons.people_outline,
        color:      AppColor.primary,
        barPercent: 1.0,
      ),
      DashStatCard(
        label:      'Total Outstanding',
        value:      'Rs ${summary.totalOutstanding.pkrFormat}',
        badge:      '${summary.hasBalanceCount} suppliers',
        icon:       Icons.account_balance_wallet_outlined,
        color:      AppColor.error,
        barPercent: summary.hasBalanceCount / (summary.totalActive == 0 ? 1 : summary.totalActive),
      ),
      DashStatCard(
        label:      'Clear Balance',
        value:      summary.clearCount.toString(),
        badge:      'Suppliers',
        icon:       Icons.check_circle_outline,
        color:      AppColor.success,
        barPercent: summary.clearCount / (summary.totalActive == 0 ? 1 : summary.totalActive),
      ),
      DashStatCard(
        label:      'Total Purchased',
        value:      'Rs ${summary.totalPurchased.pkrFormat}',
        badge:      'All time',
        icon:       Icons.shopping_cart_outlined,
        color:      AppColor.info,
        barPercent: 1.0,
      ),
    ];

    // Responsive: wide → 4/row, medium → 2/row, mobile → 1/row
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 760 ? 4 : (c.maxWidth >= 480 ? 2 : 1);
        return _cardGrid(cards, perRow);
      },
    );
  }
}

// 4 stat cards ko responsive rows (perRow) mein arrange karo. DashStatCard
// khud Expanded return karta hai → seedha Row mein. Adhoori aakhri row ko
// Expanded(SizedBox) se pad karte hain taake widths barabar rahein.
// NOTE: Row par crossAxisAlignment.stretch NAHI (scroll view mein infinite
// height crash karta hai) — default/start use karo.
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

// ─────────────────────────────────────────────────────────────
// TOP SUPPLIERS BY OUTSTANDING — horizontal bar (pie ki jagah)
// ─────────────────────────────────────────────────────────────

class _TopOutstandingChart extends StatelessWidget {
  final List<SupplierBalanceItem> items;
  const _TopOutstandingChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final top = items.take(5).toList();
    final maxVal = top.isEmpty
        ? 0.0
        : top.map((e) => e.outstandingBalance).reduce((a, b) => a > b ? a : b);

    return SectionCard(
      headerIcon: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
            color: AppColor.errorLight, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Icon(Icons.trending_up_rounded,
            size: 14, color: AppColor.error),
      ),
      title: 'Top Suppliers by Outstanding',
      children: [
        if (top.isEmpty)
          const _EmptyState(message: 'Koi outstanding balance nahi')
        else
          ...List.generate(top.length, (i) {
            final it    = top[i];
            final frac  = maxVal == 0
                ? 0.0
                : (it.outstandingBalance / maxVal).clamp(0.0, 1.0);
            final color = _kChartColors[i % _kChartColors.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(it.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      Text('Rs ${it.outstandingBalance.pkrFormat}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColor.error)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 8,
                      color: AppColor.grey200,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: frac == 0 ? 0.02 : frac,
                        child: Container(color: color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPLIER BALANCE TABLE
// ─────────────────────────────────────────────────────────────

class _SupplierBalanceTable extends ConsumerWidget {
  final List<SupplierBalanceItem> suppliers;
  const _SupplierBalanceTable({required this.suppliers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status   = ref.watch(supplierReportProvider.select((s) => s.balanceStatus));
    final notifier = ref.read(supplierReportProvider.notifier);
    final totalBalance = suppliers.fold<double>(0, (sum, s) => sum + (s.outstandingBalance > 0 ? s.outstandingBalance : 0));

    return SectionCard(
      headerIcon: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: AppColor.warningLight, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Icon(Icons.list_alt_outlined, size: 14, color: AppColor.warning),
      ),
      title: 'Supplier Balance Overview',
      headerTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColor.errorLight, borderRadius: BorderRadius.circular(12)),
        child: Text('Rs ${totalBalance.pkrFormat}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.error)),
      ),
      children: [
        // ── Balance status filter ─────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 2),
          child: Row(
            children: [
              _BalancePill(
                label:    'All',
                selected: status == BalanceStatusFilter.all,
                onTap:    () => notifier.setBalanceStatus(BalanceStatusFilter.all),
              ),
              const SizedBox(width: 6),
              _BalancePill(
                label:    'Outstanding',
                selected: status == BalanceStatusFilter.outstanding,
                onTap:    () => notifier.setBalanceStatus(BalanceStatusFilter.outstanding),
              ),
              const SizedBox(width: 6),
              _BalancePill(
                label:    'Clear',
                selected: status == BalanceStatusFilter.clear,
                onTap:    () => notifier.setBalanceStatus(BalanceStatusFilter.clear),
              ),
            ],
          ),
        ),

        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color:  AppColor.grey100,
            border: Border(bottom: BorderSide(color: AppColor.grey200)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Supplier', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary))),
              Expanded(flex: 2, child: Text('Code', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary))),
              Expanded(flex: 2, child: Text('POs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary), textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text('Total Purchased', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary), textAlign: TextAlign.right)),
              Expanded(flex: 3, child: Text('Outstanding', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary), textAlign: TextAlign.right)),
            ],
          ),
        ),

        if (suppliers.isEmpty)
          const _EmptyState(message: 'Koi supplier nahi mila')
        else
          ...suppliers.asMap().entries.map((e) {
            final s      = e.value;
            final isLast = e.key == suppliers.length - 1;
            final hasDue = s.outstandingBalance > 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: AppColor.grey100)),
              ),
              child: Row(
                children: [
                  // Name + phone
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary), overflow: TextOverflow.ellipsis),
                        if (s.phone != null)
                          Text(s.phone!, style: const TextStyle(fontSize: 10, color: AppColor.textHint)),
                      ],
                    ),
                  ),
                  // Code
                  Expanded(
                    flex: 2,
                    child: Text(s.code ?? '—', style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
                  ),
                  // POs
                  Expanded(
                    flex: 2,
                    child: Text(s.totalOrders.toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColor.textPrimary),
                        textAlign: TextAlign.center),
                  ),
                  // Total purchased
                  Expanded(
                    flex: 3,
                    child: Text('Rs ${s.totalPurchased.pkrFormat}',
                        style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
                        textAlign: TextAlign.right),
                  ),
                  // Outstanding badge
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color:        hasDue ? AppColor.errorLight : AppColor.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          hasDue ? 'Rs ${s.outstandingBalance.pkrFormat}' : 'Clear',
                          style: TextStyle(
                            fontSize:   10,
                            fontWeight: FontWeight.w600,
                            color:      hasDue ? AppColor.error : AppColor.success,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BALANCE STATUS PILL
// ─────────────────────────────────────────────────────────────

class _BalancePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BalancePill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color:        selected ? AppColor.warning : AppColor.grey100,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: selected ? AppColor.warning : AppColor.grey200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      selected ? AppColor.white : AppColor.grey600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 28, color: AppColor.grey300),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 12, color: AppColor.textHint)),
          ],
        ),
      ),
    );
  }
}
