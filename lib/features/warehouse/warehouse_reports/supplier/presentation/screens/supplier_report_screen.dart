// =============================================================
// supplier_report_screen.dart
// =============================================================

import 'package:fl_chart/fl_chart.dart';
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

class SupplierReportScreen extends ConsumerWidget {
  const SupplierReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supplierReportProvider);

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
              Text('Data load nahi hua', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Column(
        children: [
          _TopBar(onRefresh: () => ref.read(supplierReportProvider.notifier).refresh()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary cards ─────────────────────────
                  if (state.summary != null) _SummaryCardsRow(summary: state.summary!),
                  const SizedBox(height: 16),

                  // ── Pie + Bar charts row ──────────────────
                  _PieBarChartsRow(state: state),
                  const SizedBox(height: 16),

                  // ── Line chart — monthly trend ────────────
                  _MonthlyTrendSection(trend: state.monthlyTrend),
                  const SizedBox(height: 16),

                  // ── Supplier balance table ────────────────
                  _SupplierBalanceTable(suppliers: state.allSuppliers),
                  const SizedBox(height: 16),

                  // ── Recent ledger entries ─────────────────
                  _RecentLedgerSection(entries: state.recentLedger),
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
    final now    = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
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
          GestureDetector(
            onTap: onRefresh,
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
// SUMMARY CARDS ROW (4 cards)
// ─────────────────────────────────────────────────────────────

class _SummaryCardsRow extends StatelessWidget {
  final SupplierSummaryData summary;
  const _SummaryCardsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DashStatCard(
          label:      'Total Suppliers',
          value:      summary.totalActive.toString(),
          badge:      'Active',
          icon:       Icons.people_outline,
          color:      AppColor.primary,
          barPercent: 1.0,
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'Total Outstanding',
          value:      'Rs ${summary.totalOutstanding.pkrFormat}',
          badge:      '${summary.hasBalanceCount} suppliers',
          icon:       Icons.account_balance_wallet_outlined,
          color:      AppColor.error,
          barPercent: summary.hasBalanceCount / (summary.totalActive == 0 ? 1 : summary.totalActive),
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'Clear Balance',
          value:      summary.clearCount.toString(),
          badge:      'Suppliers',
          icon:       Icons.check_circle_outline,
          color:      AppColor.success,
          barPercent: summary.clearCount / (summary.totalActive == 0 ? 1 : summary.totalActive),
        ),
        const SizedBox(width: 12),
        DashStatCard(
          label:      'Total Purchased',
          value:      'Rs ${summary.totalPurchased.pkrFormat}',
          badge:      'All time',
          icon:       Icons.shopping_cart_outlined,
          color:      AppColor.info,
          barPercent: 1.0,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PIE + BAR CHARTS ROW
// ─────────────────────────────────────────────────────────────

class _PieBarChartsRow extends StatelessWidget {
  final SupplierReportState state;
  const _PieBarChartsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _BalancePieChart(items: state.topByBalance)),
        const SizedBox(width: 12),
        Expanded(child: _PurchaseBarChart(items: state.topByPurchase)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BALANCE PIE CHART
// ─────────────────────────────────────────────────────────────

class _BalancePieChart extends StatefulWidget {
  final List<SupplierBalanceItem> items;
  const _BalancePieChart({required this.items});

  @override
  State<_BalancePieChart> createState() => _BalancePieChartState();
}

class _BalancePieChartState extends State<_BalancePieChart> {
  int _touchIndex = -1;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      headerIcon: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: AppColor.errorLight, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Icon(Icons.pie_chart_outline, size: 14, color: AppColor.error),
      ),
      title: 'Outstanding Balance',
      children: [
        if (widget.items.isEmpty)
          const _EmptyState(message: 'Koi outstanding balance nahi')
        else ...[
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
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
                      sections: widget.items.asMap().entries.map((e) {
                        final isTouched = e.key == _touchIndex;
                        final color     = _kChartColors[e.key % _kChartColors.length];
                        return PieChartSectionData(
                          color:      color,
                          value:      e.value.outstandingBalance,
                          title:      isTouched ? 'Rs ${e.value.outstandingBalance.pkrFormat}' : '',
                          radius:     isTouched ? 65 : 54,
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.white),
                        );
                      }).toList(),
                      sectionsSpace:    3,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.items.asMap().entries.map((e) {
                    final color = _kChartColors[e.key % _kChartColors.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 80,
                            child: Text(
                              e.value.name,
                              style: const TextStyle(fontSize: 10, color: AppColor.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PURCHASE BAR CHART
// ─────────────────────────────────────────────────────────────

class _PurchaseBarChart extends StatelessWidget {
  final List<SupplierPurchaseItem> items;
  const _PurchaseBarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      headerIcon: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: AppColor.infoLight, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Icon(Icons.bar_chart_rounded, size: 14, color: AppColor.info),
      ),
      title: 'Top by Purchase Volume',
      children: [
        if (items.isEmpty)
          const _EmptyState(message: 'Koi purchase data nahi')
        else
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment:       BarChartAlignment.spaceAround,
                maxY:            items.map((e) => e.totalPurchased).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData:    BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${items[group.x].name}\nRs ${rod.toY.pkrFormat}',
                        const TextStyle(fontSize: 10, color: AppColor.white, fontWeight: FontWeight.w600),
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
                        if (i < 0 || i >= items.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            items[i].name.length > 6 ? '${items[i].name.substring(0, 6)}..' : items[i].name,
                            style: const TextStyle(fontSize: 9, color: AppColor.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData:    const FlGridData(show: false),
                borderData:  FlBorderData(show: false),
                barGroups:   items.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY:          e.value.totalPurchased,
                        color:        AppColor.primary,
                        width:        18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
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
// MONTHLY TREND — LINE CHART
// ─────────────────────────────────────────────────────────────

class _MonthlyTrendSection extends StatelessWidget {
  final List<MonthlyPurchaseData> trend;
  const _MonthlyTrendSection({required this.trend});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      headerIcon: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: AppColor.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Icon(Icons.show_chart_rounded, size: 14, color: AppColor.primary),
      ),
      title: 'Monthly Purchase Trend (Last 6 Months)',
      children: [
        if (trend.isEmpty)
          const _EmptyState(message: 'Is period mein koi purchase nahi')
        else
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      return LineTooltipItem(
                        'Rs ${spot.y.pkrFormat}',
                        const TextStyle(fontSize: 11, color: AppColor.white, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                gridData: FlGridData(
                  show:                    true,
                  drawVerticalLine:        false,
                  horizontalInterval:      _gridInterval(trend),
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
                        if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                        final m = trend[i].month;
                        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('${months[m.month - 1]} ${m.year.toString().substring(2)}',
                              style: const TextStyle(fontSize: 9, color: AppColor.textSecondary)),
                        );
                      },
                    ),
                  ),
                  leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: trend.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(), e.value.total)).toList(),
                    isCurved:       true,
                    color:          AppColor.primary,
                    barWidth:       2.5,
                    dotData:        const FlDotData(show: true),
                    belowBarData:   BarAreaData(
                      show:  true,
                      color: AppColor.primary.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  double _gridInterval(List<MonthlyPurchaseData> data) {
    if (data.isEmpty) return 1;
    final max = data.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    if (max == 0) return 1;
    return (max / 4).ceilToDouble();
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPLIER BALANCE TABLE
// ─────────────────────────────────────────────────────────────

class _SupplierBalanceTable extends StatelessWidget {
  final List<SupplierBalanceItem> suppliers;
  const _SupplierBalanceTable({required this.suppliers});

  @override
  Widget build(BuildContext context) {
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
// RECENT LEDGER SECTION
// ─────────────────────────────────────────────────────────────

class _RecentLedgerSection extends StatelessWidget {
  final List<RecentLedgerEntry> entries;
  const _RecentLedgerSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      headerIcon: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: AppColor.successLight, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Icon(Icons.receipt_long_outlined, size: 14, color: AppColor.success),
      ),
      title: 'Recent Ledger Entries',
      headerTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColor.infoLight, borderRadius: BorderRadius.circular(12)),
        child: Text('Last ${entries.length}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColor.info)),
      ),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color:  AppColor.grey100,
            border: Border(bottom: BorderSide(color: AppColor.grey200)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Supplier', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary))),
              Expanded(flex: 2, child: Text('Type', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary))),
              Expanded(flex: 3, child: Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary), textAlign: TextAlign.right)),
              Expanded(flex: 3, child: Text('Balance After', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary), textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary), textAlign: TextAlign.right)),
            ],
          ),
        ),

        if (entries.isEmpty)
          const _EmptyState(message: 'Koi ledger entry nahi mili')
        else
          ...entries.asMap().entries.map((e) {
            final entry  = e.value;
            final isLast = e.key == entries.length - 1;
            final isCredit = entry.isCredit;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: AppColor.grey100)),
              ),
              child: Row(
                children: [
                  // Supplier name
                  Expanded(
                    flex: 3,
                    child: Text(entry.supplierName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  // Type badge
                  Expanded(
                    flex: 2,
                    child: _LedgerTypeBadge(type: entry.entryType),
                  ),
                  // Amount
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${isCredit ? '−' : '+'}Rs ${entry.amount.abs().pkrFormat}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isCredit ? AppColor.success : AppColor.error),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  // Balance after
                  Expanded(
                    flex: 3,
                    child: Text('Rs ${entry.balanceAfter.pkrFormat}',
                        style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
                        textAlign: TextAlign.right),
                  ),
                  // Date
                  Expanded(
                    flex: 2,
                    child: Text(entry.createdAt.timeAgo,
                        style: const TextStyle(fontSize: 10, color: AppColor.textHint),
                        textAlign: TextAlign.right),
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
// LEDGER TYPE BADGE
// ─────────────────────────────────────────────────────────────

class _LedgerTypeBadge extends StatelessWidget {
  final String type;
  const _LedgerTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;

    switch (type) {
      case 'purchase':
        bg    = AppColor.errorLight;
        fg    = AppColor.error;
        label = 'Purchase';
        break;
      case 'payment':
        bg    = AppColor.successLight;
        fg    = AppColor.success;
        label = 'Payment';
        break;
      case 'return':
        bg    = AppColor.infoLight;
        fg    = AppColor.info;
        label = 'Return';
        break;
      case 'opening':
        bg    = AppColor.warningLight;
        fg    = AppColor.warning;
        label = 'Opening';
        break;
      default:
        bg    = AppColor.grey100;
        fg    = AppColor.grey600;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fg)),
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
