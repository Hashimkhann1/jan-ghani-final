import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/color/app_color.dart';
import '../../data/datasource/top_products_datasource.dart';
import '../../data/model/accountant_dashboard_model.dart';
import '../../data/model/top_product_model.dart';
import 'dashboard_trend_charts.dart';

enum _TopChart { selling, profit, lowStock }

/// Dashboard ke 3 product graphs: Top Selling, Top Profit, aur
/// "zyada sale + kam stock" (restock alert). Har ek ka apna Weekly/Monthly.
/// Weekly = pichle 7 din, Monthly = pichle 30 din ([endDate] tak).
class TopProductsSection extends StatefulWidget {
  final String branchId;
  final DateTime endDate;
  final bool desktop;
  const TopProductsSection({
    super.key,
    required this.branchId,
    required this.endDate,
    required this.desktop,
  });

  @override
  State<TopProductsSection> createState() => _TopProductsSectionState();
}

class _TopProductsSectionState extends State<TopProductsSection> {
  late final _ds = TopProductsDatasource(branchId: widget.branchId);
  final _periods = {for (final c in _TopChart.values) c: DashboardTrendPeriod.weekly};
  final _cache = <DashboardTrendPeriod, TopProductsResult>{};
  final _loading = <DashboardTrendPeriod>{};
  final _failed = <DashboardTrendPeriod>{};
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _ensure(DashboardTrendPeriod.weekly);
  }

  @override
  void didUpdateWidget(TopProductsSection old) {
    super.didUpdateWidget(old);
    if (old.endDate != widget.endDate || old.branchId != widget.branchId) {
      _gen++;
      _cache.clear();
      _loading.clear();
      _failed.clear();
      for (final p in _periods.values.toSet()) {
        _ensure(p);
      }
    }
  }

  Future<void> _ensure(DashboardTrendPeriod p) async {
    if (_cache.containsKey(p) || _loading.contains(p)) return;
    final gen = _gen;
    setState(() {
      _loading.add(p);
      _failed.remove(p);
    });
    final end = widget.endDate;
    final days = p == DashboardTrendPeriod.weekly ? 6 : 29;
    final from = DateTime(end.year, end.month, end.day - days);
    try {
      final r = await _ds.load(from, end);
      if (!mounted || gen != _gen) return;
      setState(() {
        _cache[p] = r;
        _loading.remove(p);
      });
    } catch (_) {
      if (!mounted || gen != _gen) return;
      setState(() {
        _loading.remove(p);
        _failed.add(p);
      });
    }
  }

  void _setPeriod(_TopChart c, DashboardTrendPeriod p) {
    setState(() => _periods[c] = p);
    _ensure(p);
  }

  @override
  Widget build(BuildContext context) {
    Widget panel(_TopChart c, String title, Color color,
        List<RankRow> Function(TopProductsResult) rows,
        {String? subtitle}) {
      final p = _periods[c]!;
      return RankedBarPanel(
        title: title,
        subtitle: subtitle,
        color: color,
        isLoading: _loading.contains(p) || (!_cache.containsKey(p) && !_failed.contains(p)),
        error: _failed.contains(p),
        onRetry: () => _ensure(p),
        rows: _cache[p] == null ? const [] : rows(_cache[p]!),
        trailing: TrendPeriodToggle(value: p, onChanged: (v) => _setPeriod(c, v)),
      );
    }

    final selling = panel(_TopChart.selling, 'Top Selling Products',
        const Color(0xFF0F766E), (l) {
      return [
        for (final x in l.selling)
          RankRow(x.name, x.qtySold, _q(x.qtySold),
              'Sale Rs ${_n(x.revenue)}'),
      ];
    }, subtitle: 'Quantity sold');

    final profit = panel(_TopChart.profit, 'Top Profit Products',
        const Color(0xFF15803D), (l) {
      return [
        for (final x in l.profit)
          RankRow(x.name, x.profit, 'Rs ${_n(x.profit)}',
              'Qty ${_q(x.qtySold)}'),
      ];
    }, subtitle: 'Profit earned');

    final low = panel(_TopChart.lowStock, 'High Sale, Low Stock',
        const Color(0xFFB91C1C), (l) {
      return [
        for (final x in l.lowStock)
          RankRow(x.name, x.qtySold, 'Sold ${_q(x.qtySold)}',
              x.stock <= 0 ? 'Out of stock' : 'Stock left ${_q(x.stock)}',
              warn: x.stock <= 0),
      ];
    }, subtitle: 'Sold zyada, stock bacha kam (restock karo)');

    if (!widget.desktop) {
      return Column(children: [
        selling, const SizedBox(height: 12),
        profit, const SizedBox(height: 12),
        low,
      ]);
    }
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: selling),
        const SizedBox(width: 12),
        Expanded(child: profit),
      ]),
      const SizedBox(height: 12),
      low,
    ]);
  }

  static final _nf = NumberFormat('#,##,###', 'en_IN');
  static String _n(double v) => _nf.format(v.round());
  static String _q(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class RankRow {
  final String label;
  final double value;
  final String valueText;
  final String note;
  final bool warn;
  const RankRow(this.label, this.value, this.valueText, this.note,
      {this.warn = false});
}

/// Horizontal ranked bars.
class RankedBarPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final bool isLoading, error;
  final VoidCallback onRetry;
  final List<RankRow> rows;
  final Widget trailing;

  const RankedBarPanel({
    super.key,
    required this.title,
    required this.color,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.rows,
    required this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = rows.fold<double>(0, (m, r) => r.value.abs() > m ? r.value.abs() : m);
    Widget body;
    if (isLoading) {
      body = const Center(
          child: SizedBox(
              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
    } else if (error) {
      body = Center(
          child: TextButton(onPressed: onRetry, child: const Text('Load nahi hua — dobara try karo')));
    } else if (rows.isEmpty) {
      body = Center(
          child: Text('Is period mein koi data nahi',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)));
    } else {
      body = Column(children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(
                width: 120,
                child: Text(r.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1A1D23))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(builder: (_, c) {
                  final w = maxV == 0 ? 0.0 : c.maxWidth * (r.value.abs() / maxV);
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 14,
                      width: w < 3 ? 3 : w,
                      decoration: BoxDecoration(
                        color: r.warn ? const Color(0xFF7F1D1D) : color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 112,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(r.valueText,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                      Text(r.note,
                          style: TextStyle(
                              fontSize: 10,
                              color: r.warn ? Colors.red : AppColor.textSecondary)),
                    ]),
              ),
            ]),
          ),
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1D23))),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColor.textSecondary)),
            ]),
          ),
          trailing,
        ]),
        const SizedBox(height: 12),
        ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 200), child: body),
      ]),
    );
  }
}
