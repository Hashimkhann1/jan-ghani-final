// =============================================================
// cash_flow_report_screen.dart
// Advanced Cash Flow Report — Triple LineChart, Grouped BarChart,
// Net Flow BarChart, Donut PieChart, Progress Bars
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

class CashFlowReportScreen extends ConsumerWidget {
  const CashFlowReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashFlowReportProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColor.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: AppColor.background,
        body: Center(
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [
          _TopBar(onRefresh: () => ref.read(cashFlowReportProvider.notifier).refresh()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 4 Summary Cards ──────────────────────
                  if (state.summary != null) _SummaryCards(summary: state.summary!),
                  const SizedBox(height: 16),

                  // ── STAR: Triple Line Chart ───────────────
                  _TripleLineChart(data: state.monthlyData),
                  const SizedBox(height: 16),

                  // ── Grouped Bar + Net Flow Bar ─────────────
                  _TwoBarChartsRow(data: state.monthlyData),
                  const SizedBox(height: 16),

                  // ── Donut PieChart — Expense Breakdown ────
                  _DonutExpenseChart(categories: state.expenseBreakdown),
                  const SizedBox(height: 16),

                  // ── Progress Bars — Type Breakdown ────────
                  _TypeBreakdownSection(types: state.typeBreakdown),
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
  final VoidCallback onRefresh;
  const _TopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
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
          GestureDetector(
            onTap: onRefresh,
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
// SUMMARY CARDS
// ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final CashFlowSummary summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final netPositive = summary.thisMonthNet >= 0;
    return Row(
      children: [
        DashStatCard(
          label:      'Cash In Hand',
          value:      'Rs ${summary.cashInHand.pkrFormat}',
          badge:      'Current balance',
          icon:       Icons.account_balance_wallet_outlined,
          color:      AppColor.primary,
          barPercent: 1.0,
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'This Month In',
          value:      'Rs ${summary.thisMonthCashIn.pkrFormat}',
          badge:      'Cash received',
          icon:       Icons.arrow_downward_rounded,
          color:      AppColor.success,
          barPercent: summary.thisMonthCashIn == 0 ? 0 : 1.0,
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'This Month Out',
          value:      'Rs ${summary.thisMonthCashOut.pkrFormat}',
          badge:      'Total spent',
          icon:       Icons.arrow_upward_rounded,
          color:      AppColor.error,
          barPercent: summary.thisMonthCashIn == 0
              ? 0
              : (summary.thisMonthCashOut / summary.thisMonthCashIn).clamp(0, 1),
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'Net Flow',
          value:      'Rs ${summary.thisMonthNet.abs().pkrFormat}',
          badge:      netPositive ? 'Surplus' : 'Deficit',
          icon:       netPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color:      netPositive ? AppColor.success : AppColor.error,
          barPercent: 1.0,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ⭐ STAR: TRIPLE LINE CHART
// Cash In (green) + Cash Out (red) + Balance (purple) — 3 lines
// ─────────────────────────────────────────────────────────────

class _TripleLineChart extends StatefulWidget {
  final List<MonthlyCashFlowData> data;
  const _TripleLineChart({required this.data});

  @override
  State<_TripleLineChart> createState() => _TripleLineChartState();
}

class _TripleLineChartState extends State<_TripleLineChart> {
  // Which line is touched — for highlight
  int _touchedSpotIndex = -1;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    if (d.isEmpty) {
      return SectionCard(
        headerIcon: _headerIcon(Icons.show_chart_rounded, AppColor.primary, AppColor.primary.withOpacity(0.1)),
        title: 'Cash Flow Trend (Last 6 Months)',
        children: const [_EmptyState(message: 'Koi transaction data nahi')],
      );
    }

    // Max value across all 3 lines
    final allValues = [
      ...d.map((e) => e.cashIn),
      ...d.map((e) => e.cashOut),
      ...d.map((e) => e.endBalance),
    ];
    final maxY = allValues.reduce((a, b) => a > b ? a : b) * 1.25;
    final interval = maxY == 0 ? 1.0 : (maxY / 4).ceilToDouble();

    return SectionCard(
      headerIcon: _headerIcon(Icons.multiline_chart_rounded, AppColor.primary, AppColor.primary.withOpacity(0.1)),
      title: 'Cash Flow Trend (Last 6 Months)',
      headerTrailing: _tripleLegend(),
      children: [
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY == 0 ? 10 : maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically:   true,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final labels = ['Cash In', 'Cash Out', 'Balance'];
                    final colors = [AppColor.success, AppColor.error, AppColor.primary];
                    final idx    = spot.barIndex.clamp(0, 2);
                    return LineTooltipItem(
                      '${labels[idx]}\nRs ${spot.y.pkrFormat}',
                      TextStyle(fontSize: 10, color: colors[idx], fontWeight: FontWeight.w700),
                    );
                  }).toList(),
                ),
                touchCallback: (event, response) {
                  setState(() {
                    _touchedSpotIndex = response?.lineBarSpots?.first.spotIndex ?? -1;
                  });
                },
              ),
              gridData: FlGridData(
                show:                    true,
                drawVerticalLine:        false,
                horizontalInterval:      interval,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppColor.grey100, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show:   true,
                border: const Border(
                  bottom: BorderSide(color: AppColor.grey200),
                  left:   BorderSide(color: AppColor.grey200),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles:   true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= d.length) return const SizedBox.shrink();
                      final m = d[i].month;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${_kMonths[m.month - 1]} ${m.year.toString().substring(2)}',
                            style: const TextStyle(fontSize: 9, color: AppColor.textSecondary)),
                      );
                    },
                  ),
                ),
                leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              // ── 3 Lines ──────────────────────────────────
              lineBarsData: [
                // Line 1: Cash In — green
                LineChartBarData(
                  spots:       d.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.cashIn)).toList(),
                  isCurved:    true,
                  color:       AppColor.success,
                  barWidth:    2,
                  dotData:     FlDotData(
                    show:             true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius:      index == _touchedSpotIndex ? 5 : 3,
                      color:       AppColor.success,
                      strokeWidth: 1.5,
                      strokeColor: AppColor.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show:  true,
                    color: AppColor.success.withOpacity(0.06),
                  ),
                ),
                // Line 2: Cash Out — red
                LineChartBarData(
                  spots:    d.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.cashOut)).toList(),
                  isCurved: true,
                  color:    AppColor.error,
                  barWidth: 2,
                  dotData:  FlDotData(
                    show:          true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius:      index == _touchedSpotIndex ? 5 : 3,
                      color:       AppColor.error,
                      strokeWidth: 1.5,
                      strokeColor: AppColor.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show:  true,
                    color: AppColor.error.withOpacity(0.04),
                  ),
                ),
                // Line 3: Running Balance — purple (thicker, most important)
                LineChartBarData(
                  spots:    d.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.endBalance)).toList(),
                  isCurved: true,
                  color:    AppColor.primary,
                  barWidth: 3,
                  dotData:  FlDotData(
                    show:          true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius:      index == _touchedSpotIndex ? 6 : 4,
                      color:       AppColor.primary,
                      strokeWidth: 2,
                      strokeColor: AppColor.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show:  true,
                    color: AppColor.primary.withOpacity(0.05),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Legend — teen colors explain karo
  Widget _tripleLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendDot(AppColor.success, 'In'),
        const SizedBox(width: 10),
        _legendDot(AppColor.error, 'Out'),
        const SizedBox(width: 10),
        _legendDot(AppColor.primary, 'Balance'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColor.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GROUPED BAR + NET FLOW BAR — SIDE BY SIDE ROW
// ─────────────────────────────────────────────────────────────

class _TwoBarChartsRow extends StatelessWidget {
  final List<MonthlyCashFlowData> data;
  const _TwoBarChartsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _GroupedBarChart(data: data)),
        const SizedBox(width: 12),
        Expanded(child: _NetFlowBarChart(data: data)),
      ],
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
// NET FLOW BAR CHART — Positive green / Negative red
// ─────────────────────────────────────────────────────────────

class _NetFlowBarChart extends StatelessWidget {
  final List<MonthlyCashFlowData> data;
  const _NetFlowBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SectionCard(
        headerIcon: _headerIcon(Icons.waterfall_chart_rounded, AppColor.warning, AppColor.warningLight),
        title: 'Net Flow per Month',
        children: const [_EmptyState(message: 'Koi data nahi')],
      );
    }

    final nets  = data.map((e) => e.netFlow).toList();
    final maxAbs = nets.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    final maxY  = maxAbs * 1.3 == 0 ? 10.0 : maxAbs * 1.3;

    return SectionCard(
      headerIcon: _headerIcon(Icons.waterfall_chart_rounded, AppColor.warning, AppColor.warningLight),
      title: 'Net Flow per Month',
      headerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(AppColor.success), const SizedBox(width: 4),
          const Text('Surplus', style: TextStyle(fontSize: 9, color: AppColor.textSecondary)),
          const SizedBox(width: 8),
          _dot(AppColor.error), const SizedBox(width: 4),
          const Text('Deficit', style: TextStyle(fontSize: 9, color: AppColor.textSecondary)),
        ],
      ),
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY:      -maxY,
              maxY:       maxY,
              baselineY:  0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rod, ri) {
                    final net   = data[group.x].netFlow;
                    final label = net >= 0 ? 'Surplus' : 'Deficit';
                    return BarTooltipItem(
                      '$label\nRs ${net.abs().pkrFormat}',
                      TextStyle(
                        fontSize: 10,
                        color: net >= 0 ? AppColor.success : AppColor.error,
                        fontWeight: FontWeight.w700,
                      ),
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
                // Zero line label on left
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles:   true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) {
                        return const Text('0', style: TextStyle(fontSize: 8, color: AppColor.grey400));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show:                    true,
                drawVerticalLine:        false,
                horizontalInterval:      maxY,
                getDrawingHorizontalLine: (val) => FlLine(
                  color:       val == 0 ? AppColor.grey300 : AppColor.grey100,
                  strokeWidth: val == 0 ? 1.5 : 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                final net   = e.value.netFlow;
                final color = net >= 0 ? AppColor.success : AppColor.error;
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      fromY: net < 0 ? net : 0,
                      toY:   net > 0 ? net : 0,
                      color: color,
                      width: 18,
                      borderRadius: net >= 0
                          ? const BorderRadius.vertical(top: Radius.circular(5))
                          : const BorderRadius.vertical(bottom: Radius.circular(5)),
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
// TYPE BREAKDOWN — PROGRESS BARS
// ─────────────────────────────────────────────────────────────

class _TypeBreakdownSection extends StatelessWidget {
  final List<TransactionTypeData> types;
  const _TypeBreakdownSection({required this.types});

  @override
  Widget build(BuildContext context) {
    final grandTotal = types.fold<double>(0, (s, e) => s + e.amount);

    return SectionCard(
      headerIcon: _headerIcon(Icons.stacked_bar_chart_rounded, AppColor.primary, AppColor.primary.withOpacity(0.1)),
      title: 'Transaction Type Breakdown',
      children: [
        if (types.isEmpty)
          const _EmptyState(message: 'Koi transaction nahi')
        else
          ...types.asMap().entries.map((e) {
            final item   = e.value;
            final isLast = e.key == types.length - 1;
            final pct    = grandTotal == 0 ? 0.0 : item.amount / grandTotal;
            final color  = item.isCashIn ? AppColor.success : AppColor.error;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: AppColor.grey100)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Type dot + label
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.label,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                      ),
                      Text('Rs ${item.amount.pkrFormat}',
                          style: const TextStyle(fontSize: 11, color: AppColor.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:        color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value:           pct,
                      minHeight:       5,
                      backgroundColor: AppColor.grey100,
                      valueColor:      AlwaysStoppedAnimation<Color>(color),
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
