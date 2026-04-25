// =============================================================
// dashboard_chart_widgets.dart
// =============================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/domain/warehouse_dashboard_models.dart';

// ─────────────────────────────────────────────────────────────
// PURCHASE TREND CHART
// ─────────────────────────────────────────────────────────────

class PurchaseTrendChart extends StatelessWidget {
  final List<PurchaseTrendPoint> points;
  final PurchaseDateFilter       filter;
  final bool                     isLoading;

  const PurchaseTrendChart({
    super.key,
    required this.points,
    required this.filter,
    this.isLoading = false,
  });

  String get _title {
    switch (filter) {
      case PurchaseDateFilter.today:       return 'Today\'s purchases (hourly)';
      case PurchaseDateFilter.thisWeek:    return 'This week\'s purchases';
      case PurchaseDateFilter.thisMonth:   return 'This month\'s purchases';
      case PurchaseDateFilter.last3Months: return 'Last 3 months (weekly)';
      case PurchaseDateFilter.custom:      return 'Custom range purchases';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color:        AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.show_chart_rounded,
                    size: 14, color: AppColor.primary),
              ),
              const SizedBox(width: 8),
              Text(
                _title,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      AppColor.textPrimary,
                ),
              ),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color:       AppColor.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Chart ya empty state ──────────────────────────
          if (points.isEmpty)
            _buildEmptyState()
          else
            SizedBox(
              height: 180,
              child:  _buildLineChart(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart_rounded,
                size: 32, color: AppColor.grey300),
            const SizedBox(height: 8),
            Text(
              'No purchase data for this period',
              style: TextStyle(
                fontSize: 12,
                color:    AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final maxAmount = points
        .map((p) => p.amount)
        .reduce((a, b) => a > b ? a : b);
    final topY = maxAmount == 0 ? 1000.0 : maxAmount * 1.25;

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.amount);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show:             true,
          drawVerticalLine: false,
          horizontalInterval: topY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color:       AppColor.grey100,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles:   true,
              reservedSize: 52,
              interval:     topY / 4,
              getTitlesWidget: (value, _) => Text(
                _fmtRs(value),
                style: TextStyle(
                  fontSize: 9,
                  color:    AppColor.textSecondary,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles:   true,
              reservedSize: 22,
              interval:     _bottomInterval(),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    points[idx].label,
                    style: TextStyle(
                      fontSize: 9,
                      color:    AppColor.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: topY,
        lineBarsData: [
          LineChartBarData(
            spots:            spots,
            isCurved:         true,
            curveSmoothness:  0.35,
            color:            AppColor.primary,
            barWidth:         2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                    radius:      3.5,
                    color:       AppColor.surface,
                    strokeWidth: 2,
                    strokeColor: AppColor.primary,
                  ),
            ),
            belowBarData: BarAreaData(
              show:  true,
              color: AppColor.primary.withOpacity(0.07),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColor.textPrimary,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                _fmtRsFull(spot.y),
                const TextStyle(
                  color:      Colors.white,
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  double _bottomInterval() {
    if (points.length <= 7)  return 1;
    if (points.length <= 14) return 2;
    if (points.length <= 30) return 5;
    return (points.length / 6).ceilToDouble();
  }

  String _fmtRs(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtRsFull(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(1)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPLIER OUTSTANDING CHART — horizontal bars
// ─────────────────────────────────────────────────────────────

class SupplierOutstandingChart extends StatelessWidget {
  final List<SupplierOutstandingBar> bars;

  const SupplierOutstandingChart({
    super.key,
    required this.bars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color:        AppColor.errorLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.bar_chart_rounded,
                    size: 14, color: AppColor.error),
              ),
              const SizedBox(width: 8),
              Text(
                'Outstanding by supplier',
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      AppColor.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        AppColor.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${bars.length} suppliers',
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.w600,
                    color:      AppColor.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Bars ya empty state ───────────────────────────
          bars.isEmpty ? _buildEmptyState() : _buildBars(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 32, color: AppColor.success),
            const SizedBox(height: 8),
            Text(
              'No outstanding dues',
              style: TextStyle(
                fontSize: 12,
                color:    AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBars() {
    final maxAmount = bars
        .map((b) => b.outstandingAmount)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: bars.asMap().entries.map((entry) {
        final idx   = entry.key;
        final bar   = entry.value;
        final pct   = maxAmount == 0
            ? 0.0
            : (bar.outstandingAmount / maxAmount).clamp(0.0, 1.0);
        final color = idx == 0 ? AppColor.error : AppColor.warning;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(bar.supplierName),
                      style: TextStyle(
                        fontSize:   8,
                        fontWeight: FontWeight.w700,
                        color:      color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      bar.supplierName,
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w500,
                        color:      AppColor.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _fmtRs(bar.outstandingAmount),
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color:      color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           pct,
                  minHeight:       6,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor:      AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  String _fmtRs(double v) {
    if (v >= 1000000) return 'Rs ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'Rs ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rs ${v.toStringAsFixed(0)}';
  }
}