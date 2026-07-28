// =============================================================
// purchase_report_screen.dart
// =============================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/presentation/widgets/warehouse_dashboard_widgets/warehouse_dashboard_widgets.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/purchase/data/datasources/purchase_report_local_datasource.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_reports/purchase/presentation/providers/purchase_report_provider.dart';

// ─────────────────────────────────────────────────────────────
// STATUS COLORS
// ─────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'received':  return AppColor.success;
    case 'ordered':   return AppColor.info;
    case 'partial':   return AppColor.warning;
    case 'draft':     return AppColor.grey400;
    case 'cancelled': return AppColor.error;
    default:          return AppColor.grey400;
  }
}

Color _statusBg(String status) {
  switch (status) {
    case 'received':  return AppColor.successLight;
    case 'ordered':   return AppColor.infoLight;
    case 'partial':   return AppColor.warningLight;
    case 'draft':     return AppColor.grey100;
    case 'cancelled': return AppColor.errorLight;
    default:          return AppColor.grey100;
  }
}

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class PurchaseReportScreen extends StatelessWidget {
  const PurchaseReportScreen({super.key});

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
    final state = ref.watch(purchaseReportProvider);

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
            Text(state.error!,
                style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ref.read(purchaseReportProvider.notifier).refresh(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(8)),
                child: const Text('Retry',
                    style: TextStyle(color: AppColor.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
          if (state.summary != null) _SummaryCardsRow(summary: state.summary!),
          const SizedBox(height: 16),
          _TopSuppliersBarChart(data: state.topSuppliers),
          const SizedBox(height: 16),
          _SupplierCompletionSection(data: state.supplierCompletion),
          const SizedBox(height: 16),
          _PendingPoSection(entries: state.pendingPos),
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
    final notifier = ref.read(purchaseReportProvider.notifier);
    final st       = ref.read(purchaseReportProvider);

    final now        = DateTime.now();
    final firstDate  = DateTime(2020);
    final lastDate   = DateTime(now.year, now.month, now.day);

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
      firstDate:          firstDate,
      lastDate:           lastDate,
      initialDateRange:   DateTimeRange(start: start, end: end),
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
    final state    = ref.watch(purchaseReportProvider);
    final notifier = ref.read(purchaseReportProvider.notifier);

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
          // ── Icon + title ─────────────────────────────────
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color:        AppColor.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.receipt_long_outlined, size: 18, color: AppColor.info),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Purchase Report',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.textPrimary)),
              Text(dateStr,
                  style: const TextStyle(fontSize: 11, color: AppColor.textSecondary)),
            ],
          ),
          const Spacer(),

          // ── Filter pills ──────────────────────────────────
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
  final PurchaseReportState state;
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
// SUMMARY CARDS (4)
// ─────────────────────────────────────────────────────────────

class _SummaryCardsRow extends StatelessWidget {
  final PurchaseSummaryData summary;
  const _SummaryCardsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      DashStatCard(
        label:      'Total POs',
        value:      summary.totalPos.toString(),
        badge:      'All time',
        icon:       Icons.receipt_long_outlined,
        color:      AppColor.primary,
        barPercent: 1.0,
      ),
      DashStatCard(
        label:      'Received Value',
        value:      'Rs ${summary.totalReceivedValue.pkrFormat}',
        badge:      'Completed',
        icon:       Icons.check_circle_outline,
        color:      AppColor.success,
        barPercent: summary.totalPos == 0 ? 0 :
            (summary.totalPos - summary.pendingCount) / summary.totalPos,
      ),
      DashStatCard(
        label:      'Pending POs',
        value:      summary.pendingCount.toString(),
        badge:      'Draft / Ordered / Partial',
        icon:       Icons.hourglass_empty_rounded,
        color:      AppColor.warning,
        barPercent: summary.totalPos == 0 ? 0 :
            summary.pendingCount / summary.totalPos,
      ),
      DashStatCard(
        label:      'This Month',
        value:      'Rs ${summary.thisMonthValue.pkrFormat}',
        badge:      'Received only',
        icon:       Icons.calendar_month_outlined,
        color:      AppColor.info,
        barPercent: summary.totalReceivedValue == 0 ? 0 :
            (summary.thisMonthValue / summary.totalReceivedValue).clamp(0, 1),
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

// Stat cards ko responsive rows (perRow) mein arrange karo. DashStatCard
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
// TOP SUPPLIERS BAR CHART
// ─────────────────────────────────────────────────────────────

class _TopSuppliersBarChart extends StatelessWidget {
  final List<SupplierPoValue> data;
  const _TopSuppliersBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      headerIcon: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
            color: AppColor.successLight,
            borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Icon(Icons.bar_chart_rounded, size: 14, color: AppColor.success),
      ),
      title: 'Top Suppliers by PO Value',
      children: [
        if (data.isEmpty)
          const _EmptyState(message: 'Koi data nahi')
        else
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment:   BarChartAlignment.spaceAround,
                maxY:        data.map((e) => e.totalValue).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${data[group.x].supplierName}\nRs ${rod.toY.pkrFormat}',
                          const TextStyle(
                              fontSize: 10,
                              color: AppColor.white,
                              fontWeight: FontWeight.w600),
                        ),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final name = data[i].supplierName;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            name.length > 6 ? '${name.substring(0, 6)}..' : name,
                            style: const TextStyle(
                                fontSize: 9, color: AppColor.textSecondary),
                          ),
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
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY:          e.value.totalValue,
                        color:        AppColor.success,
                        width:        18,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
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
// SUPPLIER COMPLETION — PROGRESS BARS
// ─────────────────────────────────────────────────────────────

class _SupplierCompletionSection extends StatelessWidget {
  final List<SupplierCompletionData> data;
  const _SupplierCompletionSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      headerIcon: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
            color: AppColor.warningLight,
            borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Icon(Icons.track_changes_rounded, size: 14, color: AppColor.warning),
      ),
      title: 'Supplier Delivery Completion Rate',
      children: [
        if (data.isEmpty)
          const _EmptyState(message: 'Koi supplier data nahi')
        else
          ...data.asMap().entries.map((e) {
            final item   = e.value;
            final isLast = e.key == data.length - 1;
            final pct    = item.completionRate;
            final color  = pct >= 0.9
                ? AppColor.success
                : pct >= 0.5
                    ? AppColor.warning
                    : AppColor.error;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColor.grey100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.supplierName,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.receivedPos}/${item.totalPos} POs',
                        style: const TextStyle(
                            fontSize: 10, color: AppColor.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:        color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
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
                  const SizedBox(height: 4),
                  Text(
                    '${item.totalReceived.toStringAsFixed(0)} of ${item.totalOrdered.toStringAsFixed(0)} items received',
                    style: const TextStyle(
                        fontSize: 9, color: AppColor.textHint),
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
// PENDING POs SECTION
// ─────────────────────────────────────────────────────────────

class _PendingPoSection extends StatelessWidget {
  final List<RecentPoEntry> entries;
  const _PendingPoSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      headerIcon: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
            color: AppColor.warningLight,
            borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Icon(Icons.hourglass_empty_rounded, size: 14, color: AppColor.warning),
      ),
      title: 'Pending POs',
      headerTrailing: entries.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColor.warningLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('${entries.length}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColor.warning)),
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
              Expanded(flex: 2, child: Text('PO#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary))),
              Expanded(flex: 3, child: Text('Supplier', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary))),
              Expanded(flex: 2, child: Text('Order Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary))),
              Expanded(flex: 3, child: Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColor.textSecondary), textAlign: TextAlign.right)),
            ],
          ),
        ),

        if (entries.isEmpty)
          const _EmptyState(message: 'Koi pending PO nahi — sab received!')
        else
          ...entries.asMap().entries.map((e) {
            final po     = e.value;
            final isLast = e.key == entries.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(bottom: BorderSide(color: AppColor.grey100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(po.poNumber,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(po.supplierName ?? '—',
                        style: const TextStyle(
                            fontSize: 11, color: AppColor.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 2,
                    child: _PoStatusBadge(status: po.status),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(po.orderDate.timeAgo,
                        style: const TextStyle(
                            fontSize: 10, color: AppColor.textHint)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Rs ${po.totalAmount.pkrFormat}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary),
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
// PO STATUS BADGE
// ─────────────────────────────────────────────────────────────

class _PoStatusBadge extends StatelessWidget {
  final String status;
  const _PoStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color:        _statusBg(status),
          borderRadius: BorderRadius.circular(10)),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: _statusColor(status)),
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'received':  return 'Received';
      case 'ordered':   return 'Ordered';
      case 'partial':   return 'Partial';
      case 'draft':     return 'Draft';
      case 'cancelled': return 'Cancelled';
      default:          return s;
    }
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
            Text(message,
                style: const TextStyle(fontSize: 12, color: AppColor.textHint)),
          ],
        ),
      ),
    );
  }
}
