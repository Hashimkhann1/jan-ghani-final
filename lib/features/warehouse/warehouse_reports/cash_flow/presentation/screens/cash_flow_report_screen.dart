// =============================================================
// cash_flow_report_screen.dart
// Simplified + responsive Cash Flow Report — 6 summary cards (3/2/1 per
// row), Monthly In vs Out (grouped bar) + Expense Breakdown by Category
// (donut) — side-by-side on wide, stacked on mobile.
// =============================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/widgets/warehouse_dashboard_widgets/warehouse_dashboard_widgets.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/cash_flow/data/datasources/cash_flow_report_local_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/cash_flow/presentation/providers/cash_flow_report_provider.dart';

// ─────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────

const _kMonths = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

const _kPieColors = [
  AppColor.error,
  AppColor.warning,
  AppColor.info,
  AppColor.primary,
  AppColor.success,
  Color(0xFF9C27B0),
  Color(0xFF00BCD4),
  Color(0xFFFF5722),
];

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class CashFlowReportScreen extends StatelessWidget {
  const CashFlowReportScreen({super.key});

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
    final state = ref.watch(cashFlowReportProvider);

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
            const Text('Data load nahi hua',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
            const SizedBox(height: 6),
            Text(state.error!, style: const TextStyle(fontSize: 11, color: AppColor.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref.read(cashFlowReportProvider.notifier).refresh(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(8)),
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
          // ── Summary Cards (6) ─────────────────────
          if (state.summary != null)
            _SummaryCards(
              summary:    state.summary!,
              filterMode: state.filterMode,
              types:      state.typeBreakdown,
            ),
          const SizedBox(height: 16),

          // ── Monthly In vs Out  +  Expense Breakdown by Category ──
          _TwoBarChartsRow(
            data:       state.monthlyData,
            categories: state.expenseBreakdown,
          ),
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
    final notifier = ref.read(cashFlowReportProvider.notifier);
    final st       = ref.read(cashFlowReportProvider);

    final now       = DateTime.now();
    final firstDate = DateTime(2020);
    final lastDate  = DateTime(now.year, now.month, now.day);

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
    final state    = ref.watch(cashFlowReportProvider);
    final notifier = ref.read(cashFlowReportProvider.notifier);

    final now     = DateTime.now();
    final dateStr = '${now.day} ${_kMonths[now.month - 1]} ${now.year}';

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
              color: AppColor.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColor.success),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cash Flow Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
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

          // ── Refresh ───────────────────────────────────────
          GestureDetector(
            onTap: notifier.refresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColor.grey100, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColor.grey200),
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
        child: Text(label,
            style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      selected ? AppColor.white : AppColor.grey600,
            )),
      ),
    );
  }
}

class _CustomPill extends StatelessWidget {
  final CashFlowReportState state;
  final VoidCallback onTap;
  const _CustomPill({required this.state, required this.onTap});

  String get _label {
    if (state.filterMode != DateFilterMode.custom ||
        state.dateFrom == null || state.dateTo == null) {
      return 'Custom ▾';
    }
    final f = state.dateFrom!;
    final t = state.dateTo!;
    return '${_kMonths[f.month - 1]} ${f.day} – ${_kMonths[t.month - 1]} ${t.day} ▾';
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
        child: Text(_label,
            style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      selected ? AppColor.white : AppColor.grey600,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUMMARY CARDS
// ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final CashFlowSummary summary;
  final DateFilterMode filterMode;
  final List<TransactionTypeData> types;
  const _SummaryCards({
    required this.summary,
    required this.filterMode,
    required this.types,
  });

  double _typeAmt(String t) =>
      types.where((e) => e.type == t).fold(0.0, (s, e) => s + e.amount);

  String get _periodWord {
    switch (filterMode) {
      case DateFilterMode.overall:      return 'Overall';
      case DateFilterMode.currentMonth: return 'This Month';
      case DateFilterMode.custom:       return 'Period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final netPositive = summary.periodNet >= 0;
    final pct = summary.changePct;

    // Net Flow card ka badge — vs last period % change
    final String netBadge;
    if (pct == null) {
      netBadge = netPositive ? 'Surplus' : 'Deficit';
    } else {
      final up = pct >= 0;
      netBadge = '${up ? '↑' : '↓'} ${pct.abs().toStringAsFixed(0)}% vs last';
    }

    final totalExpense = _typeAmt('expense');
    final paidSupplier = _typeAmt('supplier_payment');
    final out          = summary.periodCashOut;

    final cards = <Widget>[
      DashStatCard(
        label:      'Cash In Hand',
        value:      'Rs ${summary.cashInHand.pkrFormat}',
        badge:      'Live balance',
        icon:       Icons.account_balance_wallet_outlined,
        color:      AppColor.primary,
        barPercent: 1.0,
      ),
      DashStatCard(
        label:      '$_periodWord In',
        value:      'Rs ${summary.periodCashIn.pkrFormat}',
        badge:      'Cash received',
        icon:       Icons.arrow_downward_rounded,
        color:      AppColor.success,
        barPercent: summary.periodCashIn == 0 ? 0 : 1.0,
      ),
      DashStatCard(
        label:      '$_periodWord Out',
        value:      'Rs ${summary.periodCashOut.pkrFormat}',
        badge:      'Total spent',
        icon:       Icons.arrow_upward_rounded,
        color:      AppColor.error,
        barPercent: summary.periodCashIn == 0
            ? 0
            : (summary.periodCashOut / summary.periodCashIn).clamp(0, 1),
      ),
      DashStatCard(
        label:      'Net Flow',
        value:      'Rs ${summary.periodNet.abs().pkrFormat}',
        badge:      netBadge,
        icon:       netPositive
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        color:      netPositive ? AppColor.success : AppColor.error,
        barPercent: 1.0,
      ),
      DashStatCard(
        label:      'Total Expense',
        value:      'Rs ${totalExpense.pkrFormat}',
        badge:      'Expenses',
        icon:       Icons.receipt_long_outlined,
        color:      AppColor.warning,
        barPercent: out == 0 ? 0 : (totalExpense / out).clamp(0, 1),
      ),
      DashStatCard(
        label:      'Paid to Supplier',
        value:      'Rs ${paidSupplier.pkrFormat}',
        badge:      'Supplier payments',
        icon:       Icons.people_outline_rounded,
        color:      AppColor.info,
        barPercent: out == 0 ? 0 : (paidSupplier / out).clamp(0, 1),
      ),
    ];

    // Responsive: wide → 3/row, medium → 2/row, mobile → 1/row
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 880 ? 3 : (c.maxWidth >= 520 ? 2 : 1);
        return _cardGrid(cards, perRow);
      },
    );
  }
}

// 6 stat cards ko responsive rows (perRow) mein arrange karo. DashStatCard
// khud Expanded return karta hai → seedha Row mein. Adhoori aakhri row ko
// Expanded(SizedBox) se pad karte hain taake card widths barabar rahein.
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
    // NOTE: crossAxisAlignment.stretch use NAHI karna — scroll view (unbounded
    // height) mein woh cards ko infinite height de kar layout crash karta hai.
    rows.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ));
  }
  return Column(children: rows);
}

// ─────────────────────────────────────────────────────────────
// MONTHLY IN/OUT  +  EXPENSE BREAKDOWN — SIDE BY SIDE ROW
// ─────────────────────────────────────────────────────────────

class _TwoBarChartsRow extends StatelessWidget {
  final List<MonthlyCashFlowData> data;
  final List<ExpenseCategoryData> categories;
  const _TwoBarChartsRow({required this.data, required this.categories});

  @override
  Widget build(BuildContext context) {
    // Left: Monthly In vs Out (grouped bar). Right: Expense Breakdown (donut).
    // Wide → side-by-side; narrow (mobile) → stack (dono full-width).
    return LayoutBuilder(
      builder: (context, c) {
        final bar   = _GroupedBarChart(data: data);
        final donut = _DonutExpenseChart(categories: categories);
        if (c.maxWidth >= 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: bar),
              const SizedBox(width: 12),
              Expanded(child: donut),
            ],
          );
        }
        return Column(
          children: [
            bar,
            const SizedBox(height: 12),
            donut,
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GROUPED BAR CHART — In vs Out per Month (2 bars)
// ─────────────────────────────────────────────────────────────

class _GroupedBarChart extends StatelessWidget {
  final List<MonthlyCashFlowData> data;
  const _GroupedBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final allVals = data.expand((e) => [e.cashIn, e.cashOut]);
    final maxY    = allVals.isEmpty ? 10.0 : allVals.reduce((a, b) => a > b ? a : b) * 1.25;

    return SectionCard(
      headerIcon: _headerIcon(Icons.bar_chart_rounded, AppColor.info, AppColor.infoLight),
      title: 'Monthly In vs Out',
      headerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(AppColor.success), const SizedBox(width: 4),
          const Text('In', style: TextStyle(fontSize: 9, color: AppColor.textSecondary)),
          const SizedBox(width: 8),
          _dot(AppColor.error), const SizedBox(width: 4),
          const Text('Out', style: TextStyle(fontSize: 9, color: AppColor.textSecondary)),
        ],
      ),
      children: [
        if (data.isEmpty)
          const _EmptyState(message: 'Koi data nahi')
        else
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment:   BarChartAlignment.spaceAround,
                maxY:        maxY == 0 ? 10 : maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) {
                      final label = ri == 0 ? 'Cash In' : 'Cash Out';
                      return BarTooltipItem(
                        '$label\nRs ${rod.toY.pkrFormat}',
                        TextStyle(fontSize: 10, color: ri == 0 ? AppColor.success : AppColor.error, fontWeight: FontWeight.w700),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox.shrink();
                        final m = data[i].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_kMonths[m.month - 1],
                              style: const TextStyle(fontSize: 8, color: AppColor.textSecondary)),
                        );
                      },
                    ),
                  ),
                  leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData:   const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups:  data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x:         e.key,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY:          e.value.cashIn,
                        color:        AppColor.success,
                        width:        10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY:          e.value.cashOut,
                        color:        AppColor.error,
                        width:        10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DONUT PIE CHART — Expense Breakdown
// Center mein total amount — Stack se overlay
// ─────────────────────────────────────────────────────────────

class _DonutExpenseChart extends StatefulWidget {
  final List<ExpenseCategoryData> categories;
  const _DonutExpenseChart({required this.categories});

  @override
  State<_DonutExpenseChart> createState() => _DonutExpenseChartState();
}

class _DonutExpenseChartState extends State<_DonutExpenseChart> {
  int _touchIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.categories.fold<double>(0, (s, e) => s + e.amount);

    return SectionCard(
      headerIcon: _headerIcon(Icons.donut_large_rounded, AppColor.error, AppColor.errorLight),
      title: 'Expense Breakdown by Category',
      headerTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColor.errorLight, borderRadius: BorderRadius.circular(12)),
        child: Text('Rs ${total.pkrFormat}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.error)),
      ),
      children: [
        if (widget.categories.isEmpty)
          const _EmptyState(message: 'Koi expense nahi')
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut chart with center overlay
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: SizedBox(
                  width:  240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response?.touchedSection == null) {
                                  _touchIndex = -1;
                                  return;
                                }
                                _touchIndex = response!.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: widget.categories.asMap().entries.map((e) {
                            final isTouched = e.key == _touchIndex;
                            final color     = _kPieColors[e.key % _kPieColors.length];
                            final pct       = total == 0 ? 0.0 : e.value.amount / total * 100;
                            return PieChartSectionData(
                              color:      color,
                              value:      e.value.amount,
                              title:      isTouched ? '${pct.toStringAsFixed(0)}%' : '',
                              radius:     isTouched ? 70 : 58,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColor.white),
                            );
                          }).toList(),
                          sectionsSpace:     3,
                          centerSpaceRadius: 52, // donut hole
                        ),
                      ),
                      // Center text overlay — donut ke andar
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 10, color: AppColor.textHint)),
                          Text(
                            'Rs ${total.pkrFormat}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800, color: AppColor.textPrimary),
                          ),
                          Text('${widget.categories.length} heads',
                              style: const TextStyle(fontSize: 9, color: AppColor.textHint)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Rich legend with amounts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.categories.asMap().entries.map((e) {
                    final color  = _kPieColors[e.key % _kPieColors.length];
                    final pct    = total == 0 ? 0.0 : e.value.amount / total * 100;
                    final isActive = e.key == _touchIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color:        color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.value.category,
                                    style: TextStyle(
                                      fontSize:   11,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                      color:      isActive ? color : AppColor.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                                Row(
                                  children: [
                                    Text('Rs ${e.value.amount.pkrFormat}',
                                        style: const TextStyle(fontSize: 10, color: AppColor.textSecondary)),
                                    const SizedBox(width: 6),
                                    Text('${pct.toStringAsFixed(1)}%',
                                        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────

Widget _headerIcon(IconData icon, Color iconColor, Color bgColor) {
  return Container(
    width: 26, height: 26,
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
    alignment: Alignment.center,
    child: Icon(icon, size: 14, color: iconColor),
  );
}

Widget _dot(Color color) {
  return Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

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

