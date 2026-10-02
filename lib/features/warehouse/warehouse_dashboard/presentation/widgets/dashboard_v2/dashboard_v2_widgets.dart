// Updated on 2026-10-02 09:31 AM
// =============================================================
// dashboard_v2_widgets.dart
// Warehouse Dashboard v2 (Stitch design) ke widgets:
//   DashCard · DashKpiCard · NeedsAttentionCard · PurchaseCashChartCard
//   SupplierDuesCard · LowStockCard · MovementsCard
// (purani warehouse_dashboard_widgets.dart reports bhi use karti hain —
//  usko nahi chhera)
// =============================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:jan_ghani_final/core/color/app_color.dart';
import 'package:jan_ghani_final/core/extension/app_extention.dart';
import 'package:jan_ghani_final/features/warehouse/warehouse_dashboard/domain/warehouse_dashboard_models.dart';

// ── Formatting ──────────────────────────────────────────────
String rs(double v) => 'Rs ${v.roundToDouble().pkrFormat}';

String _rsCompact(double v) {
  final a = v.abs(), s = v < 0 ? '-' : '';
  if (a >= 100000) return '${s}Rs ${(a / 100000).toStringAsFixed(a % 100000 == 0 ? 0 : 1)}L';
  if (a >= 1000)   return '${s}Rs ${(a / 1000).toStringAsFixed(0)}k';
  return '${s}Rs ${a.toStringAsFixed(0)}';
}

String _qty(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

// ─────────────────────────────────────────────────────────────
// CARD SHELL — white, 14 radius, grey border, title + subtitle
// ─────────────────────────────────────────────────────────────
class DashCard extends StatelessWidget {
  final String?  title;
  final String?  subtitle;
  final Widget?  leading;   // title se pehle (jaise red dot)
  final Widget?  trailing;  // title row ke right
  final Widget   child;
  final Widget?  footer;
  final EdgeInsets padding;

  const DashCard({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.child,
    this.footer,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title!,
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          )),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColor.textSecondary)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
          ],
          Expanded(child: child),
          if (footer != null) ...[
            const Divider(height: 24, color: AppColor.grey200),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Footer ka "View all →" link (right aligned)
class DashLink extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const DashLink({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  )),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: AppColor.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chhota rangeen chip — "23 Items Critical", "5 action items"
class DashChip extends StatelessWidget {
  final String text;
  final Color  color;
  final Color  bg;
  const DashChip({super.key, required this.text, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// KPI CARD
// ─────────────────────────────────────────────────────────────
class DashKpiCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  final Color    bg;
  final Widget   sub;

  const DashKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 18, 14),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: AppColor.textPrimary,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary, letterSpacing: -0.5,
                )),
          ),
          const SizedBox(height: 6),
          DefaultTextStyle(
            style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: sub,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NEEDS ATTENTION
// ─────────────────────────────────────────────────────────────
class AttentionItem {
  final String title;
  final String hint;
  final int    count;
  final Color  color;
  final Color  bg;
  final VoidCallback? onTap;

  const AttentionItem({
    required this.title,
    required this.hint,
    required this.count,
    required this.color,
    required this.bg,
    this.onTap,
  });
}

class NeedsAttentionCard extends StatelessWidget {
  final List<AttentionItem> items;
  final bool narrow;
  const NeedsAttentionCard({super.key, required this.items, this.narrow = false});

  @override
  Widget build(BuildContext context) {
    final actionCount = items.where((i) => i.count > 0).length;

    Widget tile(AttentionItem it) => _AttentionTile(item: it);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppColor.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: actionCount > 0 ? AppColor.error : AppColor.success,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Needs attention',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  )),
              const SizedBox(width: 12),
              actionCount > 0
                  ? DashChip(
                      text:  '$actionCount action items',
                      color: AppColor.error, bg: AppColor.errorLight)
                  : const DashChip(
                      text:  'All clear',
                      color: AppColor.success, bg: AppColor.successLight),
            ],
          ),
          const SizedBox(height: 16),
          if (narrow)
            Wrap(
              spacing: 12, runSpacing: 12,
              children: items
                  .map((it) => SizedBox(width: 240, child: tile(it)))
                  .toList(),
            )
          else
            Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: tile(items[i])),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  final AttentionItem item;
  const _AttentionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final active = item.count > 0;
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: AppColor.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.title,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: active ? item.bg : AppColor.grey100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${item.count}',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: active ? item.color : AppColor.textSecondary,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(item.hint,
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColor.textPrimary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PURCHASES VS CASH OUT — 2 line chart
// ─────────────────────────────────────────────────────────────
class PurchaseCashChartCard extends StatelessWidget {
  final List<DashboardTrendPoint> points;
  final PurchaseDateFilter filter;

  const PurchaseCashChartCard({
    super.key,
    required this.points,
    required this.filter,
  });

  static const _purchaseColor = AppColor.info;
  static const _cashOutColor  = AppColor.error;

  @override
  Widget build(BuildContext context) {
    final totalPurchases = points.fold<double>(0, (s, p) => s + p.purchases);
    final totalCashOut   = points.fold<double>(0, (s, p) => s + p.cashOut);

    return DashCard(
      title:    'Purchases vs Cash out',
      subtitle: 'Received purchases vs cash paid out',
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Legend(color: _purchaseColor, label: 'Purchases'),
          SizedBox(width: 16),
          _Legend(color: _cashOutColor, label: 'Cash out'),
        ],
      ),
      footer: Row(
        children: [
          Text('${filter.shortLabel.toUpperCase()} VOLUME',
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColor.textPrimary, letterSpacing: 0.4,
              )),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text.rich(TextSpan(children: [
                TextSpan(text: '${rs(totalPurchases)} purchases',
                    style: const TextStyle(color: _purchaseColor)),
                const TextSpan(text: '   ·   ',
                    style: TextStyle(color: AppColor.textSecondary)),
                TextSpan(text: '${rs(totalCashOut)} paid',
                    style: const TextStyle(color: _cashOutColor)),
              ]), style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      child: points.isEmpty
          ? const _Empty(icon: Icons.show_chart_rounded, text: 'Is period mein koi data nahi')
          : _chart(),
    );
  }

  Widget _chart() {
    final values = [
      for (final p in points) ...[p.purchases, p.cashOut],
    ];
    final maxV = values.fold<double>(0, (m, v) => v > m ? v : m);
    final minV = values.fold<double>(0, (m, v) => v < m ? v : m);
    final topY = maxV <= 0 ? 1000.0 : (maxV * 1.15);
    final botY = minV < 0 ? minV * 1.15 : 0.0;
    final step = (topY - botY) / 4;
    final n    = points.length;
    final labelEvery = n <= 8 ? 1 : (n / 8).ceil();

    LineChartBarData line(List<double> ys, Color c) => LineChartBarData(
      spots:            [for (var i = 0; i < n; i++) FlSpot(i.toDouble(), ys[i])],
      isCurved:         true,
      curveSmoothness:  0.3,
      preventCurveOverShooting: true,
      color:            c,
      barWidth:         2.5,
      isStrokeCapRound: true,
      dotData:          const FlDotData(show: false),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (n - 1).clamp(1, 1 << 30).toDouble(),
          minY: botY,
          maxY: topY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: step,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColor.grey200, strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(bottom: BorderSide(color: AppColor.grey300)),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 60,
                interval:     step,
                getTitlesWidget: (v, _) => Text(_rsCompact(v),
                    style: const TextStyle(
                        fontSize: 11, color: AppColor.textSecondary)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 28,
                interval:     1,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (v != i.toDouble() || i < 0 || i >= n || i % labelEvery != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(points[i].label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColor.textSecondary)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColor.textPrimary,
              getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                '${s.barIndex == 0 ? 'Purchases' : 'Cash out'}: ${rs(s.y)}',
                TextStyle(
                  color: s.barIndex == 0 ? AppColor.infoLight : AppColor.errorLight,
                  fontSize: 11, fontWeight: FontWeight.w600,
                ),
              )).toList(),
            ),
          ),
          lineBarsData: [
            line([for (final p in points) p.purchases], _purchaseColor),
            line([for (final p in points) p.cashOut],   _cashOutColor),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: AppColor.textPrimary,
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP SUPPLIER DUES — bar list (1st red, 2nd amber, baaki grey)
// ─────────────────────────────────────────────────────────────
class SupplierDuesCard extends StatelessWidget {
  final List<SupplierDue> dues;
  final VoidCallback? onViewAll;
  const SupplierDuesCard({super.key, required this.dues, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final maxAmt = dues.fold<double>(0, (m, d) =>
        d.outstandingAmount > m ? d.outstandingAmount : m);

    return DashCard(
      title:    'Top supplier dues',
      trailing: const Text('Credit terms',
          style: TextStyle(fontSize: 12, color: AppColor.textSecondary)),
      footer:   DashLink(text: 'All suppliers', onTap: onViewAll),
      child: dues.isEmpty
          ? const _Empty(icon: Icons.check_circle_outline_rounded,
              text: 'Kisi supplier ka baqaya nahi', success: true)
          : Column(
              children: [
                for (var i = 0; i < dues.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _DueRow(
                      due:   dues[i],
                      ratio: maxAmt <= 0 ? 0 : dues[i].outstandingAmount / maxAmt,
                      color: i == 0 ? AppColor.error
                           : i == 1 ? AppColor.warning
                           : AppColor.grey500,
                      badgeColor: i == 0 ? AppColor.error
                                : i == 1 ? AppColor.warningDark
                                : AppColor.textSecondary,
                      badgeBg: i == 0 ? AppColor.errorLight
                             : i == 1 ? AppColor.warningLight
                             : AppColor.grey100,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DueRow extends StatelessWidget {
  final SupplierDue due;
  final double ratio;
  final Color color, badgeColor, badgeBg;
  const _DueRow({
    required this.due, required this.ratio, required this.color,
    required this.badgeColor, required this.badgeBg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(due.supplierName,
                  style: const TextStyle(
                      fontSize: 13, color: AppColor.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            DashChip(text: '${due.paymentTerms} days',
                color: badgeColor, bg: badgeBg),
            const Spacer(),
            Text(rs(due.outstandingAmount),
                style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                )),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value:           ratio.clamp(0.0, 1.0),
            minHeight:       5,
            backgroundColor: AppColor.grey100,
            valueColor:      AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOW STOCK — REORDER table
// ─────────────────────────────────────────────────────────────
class LowStockCard extends StatelessWidget {
  final List<DashboardLowStockRow> rows;
  final int totalCount;
  final VoidCallback? onViewAll;
  const LowStockCard({
    super.key,
    required this.rows,
    required this.totalCount,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textSecondary,
    );

    return DashCard(
      title:    'Low stock — reorder',
      subtitle: 'Reorder point se neeche ya barabar (available stock)',
      trailing: totalCount > 0
          ? DashChip(text: '$totalCount Items Critical',
              color: AppColor.error, bg: AppColor.errorLight)
          : null,
      footer: DashLink(
        text:  totalCount > 0 ? 'View all $totalCount' : 'View stock',
        onTap: onViewAll,
      ),
      child: rows.isEmpty
          ? const _Empty(icon: Icons.check_circle_outline_rounded,
              text: 'Sab products theek stock mein hain', success: true)
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Expanded(flex: 5, child: Text('Product', style: head)),
                    Expanded(flex: 3, child: Text('SKU', style: head)),
                    Expanded(flex: 2, child: Text('Stock', style: head, textAlign: TextAlign.right)),
                    Expanded(flex: 3, child: Text('Reorder Pt', style: head, textAlign: TextAlign.right)),
                    Expanded(flex: 3, child: Text('Level', style: head, textAlign: TextAlign.right)),
                  ]),
                ),
                const Divider(height: 1, color: AppColor.grey200),
                for (var i = 0; i < rows.length; i++)
                  _LowStockRow(row: rows[i], isLast: i == rows.length - 1),
              ],
            ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  final DashboardLowStockRow row;
  final bool isLast;
  const _LowStockRow({required this.row, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final pct   = row.level;
    final color = pct < 0.30 ? AppColor.error : AppColor.warningDark;
    final bar   = pct < 0.30 ? AppColor.error : AppColor.warning;
    final unit  = row.unit.isEmpty ? '' : ' ${row.unit}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null
            : const Border(bottom: BorderSide(color: AppColor.grey100)),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(row.productName,
              style: const TextStyle(fontSize: 13, color: AppColor.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(row.sku,
              style: const TextStyle(
                  fontSize: 12, color: AppColor.textSecondary,
                  fontFamily: 'monospace'),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text('${_qty(row.available)}$unit',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text('${row.reorderPoint}$unit',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: AppColor.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${(pct * 100).round()}%',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value:           pct,
                      minHeight:       5,
                      backgroundColor: bar.withOpacity(0.15),
                      valueColor:      AlwaysStoppedAnimation(bar),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RECENT STOCK MOVEMENTS
// ─────────────────────────────────────────────────────────────
class MovementsCard extends StatelessWidget {
  final List<DashboardMovement> movements;
  const MovementsCard({super.key, required this.movements});

  @override
  Widget build(BuildContext context) {
    return DashCard(
      title:    'Recent stock movements',
      subtitle: 'Purchase, transfer, return aur adjustment log',
      trailing: const Icon(Icons.history_rounded,
          size: 22, color: AppColor.textSecondary),
      child: movements.isEmpty
          ? const _Empty(icon: Icons.swap_vert_rounded,
              text: 'Is period mein koi stock movement nahi')
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: movements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _MovementTile(m: movements[i]),
            ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final DashboardMovement m;
  const _MovementTile({required this.m});

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun',
                          'Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, Color bg) = switch (m.movementType) {
      'purchase_in' || 'opening' || 'return_in' =>
          (Icons.south_rounded, AppColor.success, AppColor.successLight),
      'transfer_out' =>
          (Icons.east_rounded, AppColor.primary, AppColor.primary.withOpacity(0.1)),
      'return_out' =>
          (Icons.undo_rounded, AppColor.error, AppColor.errorLight),
      _ => (Icons.tune_rounded, AppColor.textSecondary, AppColor.grey200),
    };

    final qtyColor = m.signedQty > 0
        ? AppColor.success
        : m.movementType == 'transfer_out'
            ? AppColor.primary
            : m.movementType == 'adjustment'
                ? AppColor.textPrimary
                : AppColor.error;

    final ref  = m.reference ?? _typeLabel(m.movementType);
    final sign = m.signedQty > 0 ? '+' : (m.signedQty < 0 ? '−' : '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColor.grey100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.productName,
                    style: const TextStyle(
                        fontSize: 13, color: AppColor.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Ref: $ref  •  ${_when(m.createdAt)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColor.textSecondary,
                        fontFamily: 'monospace'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$sign${_qty(m.signedQty.abs())}',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: qtyColor)),
        ],
      ),
    );
  }

  static String _typeLabel(String t) => switch (t) {
    'purchase_in'  => 'Purchase',
    'transfer_out' => 'Transfer',
    'return_in'    => 'Return in',
    'return_out'   => 'Return',
    'opening'      => 'Opening',
    _              => 'Adjustment',
  };

  // timestamptz → local; aaj ka ho to sirf time, warna date + time
  static String _when(DateTime d) {
    final l   = d.toLocal();
    final n   = DateTime.now();
    final h12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final t   = '$h12:${l.minute.toString().padLeft(2, '0')} ${l.hour < 12 ? 'AM' : 'PM'}';
    final sameDay = l.year == n.year && l.month == n.month && l.day == n.day;
    return sameDay ? t : '${l.day} ${_months[l.month - 1]}, $t';
  }
}

// ─────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  final IconData icon;
  final String   text;
  final bool     success;
  const _Empty({required this.icon, required this.text, this.success = false});

  @override
  Widget build(BuildContext context) {
    final c = success ? AppColor.success : AppColor.grey400;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: c),
          ),
          const SizedBox(height: 10),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColor.textSecondary)),
        ],
      ),
    );
  }
}
