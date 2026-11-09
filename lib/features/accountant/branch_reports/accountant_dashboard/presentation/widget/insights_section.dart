import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../../../core/color/app_color.dart';
import '../../data/datasource/insights_datasource.dart';
import '../../data/model/accountant_dashboard_model.dart';
import '../../data/model/insights_model.dart';
import 'dashboard_trend_charts.dart';
import 'top_products_section.dart' show RankRow, RankedBarPanel;

/// Dashboard ke extra graphs. Ek shared Weekly/Monthly toggle; do RPC calls
/// (rankings + trend) period ke hisab se, cache ke saath.
class InsightsSection extends StatefulWidget {
  final String branchId;
  final DateTime endDate;
  final bool desktop;
  const InsightsSection({
    super.key,
    required this.branchId,
    required this.endDate,
    required this.desktop,
  });

  @override
  State<InsightsSection> createState() => _InsightsSectionState();
}

class _InsightsSectionState extends State<InsightsSection> {
  late final _ds = InsightsDatasource(branchId: widget.branchId);
  var _period = DashboardTrendPeriod.weekly;
  final _cache = <DashboardTrendPeriod, InsightsResult>{};
  final _loading = <DashboardTrendPeriod>{};
  final _failed = <DashboardTrendPeriod>{};
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _ensure(_period);
  }

  @override
  void didUpdateWidget(InsightsSection old) {
    super.didUpdateWidget(old);
    if (old.endDate != widget.endDate || old.branchId != widget.branchId) {
      _gen++;
      _cache.clear();
      _loading.clear();
      _failed.clear();
      _ensure(_period);
    }
  }

  Future<void> _ensure(DashboardTrendPeriod p) async {
    if (_cache.containsKey(p) || _loading.contains(p)) return;
    final gen = _gen;
    setState(() {
      _loading.add(p);
      _failed.remove(p);
    });
    try {
      final r = await _ds.load(widget.endDate, p);
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

  static final _nf = NumberFormat('#,##,###', 'en_IN');
  static String _n(double v) => _nf.format(v.round());
  static String _q(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  static String _hour(String h) {
    final x = int.tryParse(h) ?? 0;
    final h12 = x % 12 == 0 ? 12 : x % 12;
    return '$h12${x < 12 ? 'a' : 'p'}';
  }

  @override
  Widget build(BuildContext context) {
    final res = _cache[_period];
    final loading = res == null && !_failed.contains(_period);
    final error = _failed.contains(_period);
    final r = res?.range;
    final tr = res?.trend ?? const <InsightsBucket>[];

    Widget rank(String title, String sub, Color c, List<RankRow> rows) =>
        RankedBarPanel(
          title: title, subtitle: sub, color: c,
          isLoading: loading, error: error,
          onRetry: () => _ensure(_period), rows: rows,
          trailing: const SizedBox.shrink(),
        );

    // DashboardTrendPoint sirf painter reuse karne ke liye.
    List<DashboardTrendPoint> pts(double Function(InsightsBucket) f) => [
          for (final b in tr)
            DashboardTrendPoint(
                label: b.label, sale: f(b), saleReturn: 0, profit: 0,
                creditSale: 0, installment: 0),
        ];
    Widget bar(String t, double Function(InsightsBucket) f, List<Color> g) =>
        TrendBarChart(
            title: t, data: pts(f), valueOf: (p) => p.sale,
            isLoading: loading, gradient: g);
    Widget line(String t, double Function(InsightsBucket) f, Color c) =>
        TrendLineChart(
            title: t, data: pts(f), valueOf: (p) => p.sale,
            isLoading: loading, color: c);

    // Hourly: sirf sale wale ghante (min..max), 24 labels nahi.
    final hours = r?.hourly ?? const <InsightItem>[];
    final hourly = TrendBarChart(
      title: 'Hourly Sale',
      data: [
        for (final h in hours)
          DashboardTrendPoint(
              label: _hour(h.name), sale: h.value, saleReturn: 0, profit: 0,
              creditSale: 0, installment: 0),
      ],
      valueOf: (p) => p.sale,
      isLoading: loading,
      gradient: const [Color(0xFF0E7490), Color(0xFF67E8F9)],
    );

    final charts = <Widget>[
      hourly,
      rank('Category Wise Sale', 'Sale (profit saath mein)', const Color(0xFF7C3AED), [
        for (final x in r?.category ?? const <InsightItem>[])
          RankRow(x.name, x.value, 'Rs ${_n(x.value)}', 'Profit Rs ${_n(x.extra)}'),
      ]),
      rank('Staff Wise Sale', 'Kis ne kitni sale ki', const Color(0xFF0369A1), [
        for (final x in r?.staff ?? const <InsightItem>[])
          RankRow(x.name, x.value, 'Rs ${_n(x.value)}', '${_q(x.extra)} invoices'),
      ]),
      line('Profit Margin %', (b) => b.marginPct, const Color(0xFF15803D)),
      rank('Loss Making Products', 'Cost se kam par bike', const Color(0xFFB91C1C), [
        for (final x in r?.lossProducts ?? const <InsightItem>[])
          RankRow(x.name, x.value, 'Loss Rs ${_n(x.value)}', 'Qty ${_q(x.extra)}',
              warn: true),
      ]),
      bar('Discount Trend', (b) => b.discount,
          const [Color(0xFFB45309), Color(0xFFFCD34D)]),
      rank('Top Customers', 'Sab se zyada khareed', const Color(0xFF0F766E), [
        for (final x in r?.topCustomers ?? const <InsightItem>[])
          RankRow(x.name, x.value, 'Rs ${_n(x.value)}', '${_q(x.extra)} invoices'),
      ]),
      rank('Top Udhaar Customers', 'Abhi baqi balance', const Color(0xFFC2410C), [
        for (final x in r?.topUdhaar ?? const <InsightItem>[])
          RankRow(x.name, x.value, 'Rs ${_n(x.value)}', 'Baqi'),
      ]),
      _GroupedBars(
        title: 'Credit Given vs Recovered',
        labels: [for (final b in tr) b.label],
        a: [for (final b in tr) b.credit],
        b: [for (final b in tr) b.recovered],
        aName: 'Credit diya', bName: 'Wapas aaya',
        aColor: const Color(0xFFD97706), bColor: const Color(0xFF16A34A),
        isLoading: loading,
      ),
      rank('Dead Stock', 'Is period mein bilkul nahi bika (paisa phansa)',
          const Color(0xFF64748B), [
        for (final x in r?.deadStock ?? const <InsightItem>[])
          RankRow(x.name, x.value, 'Rs ${_n(x.value)}', 'Stock ${_q(x.extra)}'),
      ]),
      bar('Stock Damage Trend', (b) => b.damage,
          const [Color(0xFFBE123C), Color(0xFFFDA4AF)]),
      _GroupedBars(
        title: 'Cash In vs Cash Out',
        labels: [for (final b in tr) b.label],
        a: [for (final b in tr) b.cashIn],
        b: [for (final b in tr) b.cashOut],
        aName: 'Cash In', bName: 'Cash Out',
        aColor: const Color(0xFF16A34A), bColor: const Color(0xFFDC2626),
        isLoading: loading,
      ),
    ];

    Widget grid() {
      if (!widget.desktop) {
        return Column(children: [
          for (final c in charts) ...[c, const SizedBox(height: 12)],
        ]);
      }
      return Column(children: [
        for (var i = 0; i < charts.length; i += 2) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: charts[i]),
            const SizedBox(width: 12),
            Expanded(
                child: i + 1 < charts.length ? charts[i + 1] : const SizedBox()),
          ]),
          const SizedBox(height: 12),
        ],
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(
          child: Text('Business Insights',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23))),
        ),
        TrendPeriodToggle(
          value: _period,
          onChanged: (p) {
            setState(() => _period = p);
            _ensure(p);
          },
        ),
      ]),
      const SizedBox(height: 4),
      Text(
        _period == DashboardTrendPeriod.weekly
            ? 'Pichle 7 din'
            : 'Rankings: pichle 30 din · Trends: pichle 6 mahine',
        style: const TextStyle(fontSize: 11, color: AppColor.textSecondary),
      ),
      const SizedBox(height: 10),
      grid(),
    ]);
  }
}

// ─── Do series ke grouped bars ──────────────────────────────────────────────
class _GroupedBars extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<double> a, b;
  final String aName, bName;
  final Color aColor, bColor;
  final bool isLoading;
  const _GroupedBars({
    required this.title,
    required this.labels,
    required this.a,
    required this.b,
    required this.aName,
    required this.bName,
    required this.aColor,
    required this.bColor,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final empty = [...a, ...b].every((v) => v == 0);
    Widget legend(String t, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ]);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1D23))),
          ),
          legend(aName, aColor),
          const SizedBox(width: 10),
          legend(bName, bColor),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: isLoading
              ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
              : empty
                  ? Center(child: Text('Is period mein koi data nahi', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)))
                  : CustomPaint(
                      size: Size.infinite,
                      painter: _GroupedPainter(labels, a, b, aColor, bColor)),
        ),
      ]),
    );
  }
}

class _GroupedPainter extends CustomPainter {
  final List<String> labels;
  final List<double> a, b;
  final Color ca, cb;
  _GroupedPainter(this.labels, this.a, this.b, this.ca, this.cb);

  static String _k(double v) {
    if (v >= 100000) return '${(v / 1000).toStringAsFixed(0)}k';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  void _text(Canvas c, String s, Offset o, {double size = 9, Color? color, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: color ?? const Color(0xFF6B7280), fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(o.dx - tp.width / 2, o.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    if (n == 0) return;
    const bottom = 24.0, top = 16.0;
    final h = size.height - bottom - top;
    final maxV = [...a, ...b].fold<double>(0, (m, v) => v > m ? v : m);
    if (maxV <= 0) return;
    final grid = Paint()..color = const Color(0xFFE5E7EB)..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + h * (1 - i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final slot = size.width / n;
    final w = (slot * 0.30).clamp(6.0, 22.0);
    for (var i = 0; i < n; i++) {
      final cx = slot * i + slot / 2;
      for (final (k, v, col) in [(-1, a[i], ca), (1, b[i], cb)]) {
        final bh = h * (v / maxV);
        final x = cx + k * (w / 2 + 1);
        if (bh > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x - w / 2, top + h - bh, w, bh), const Radius.circular(3)),
            Paint()..color = col,
          );
          _text(canvas, _k(v), Offset(x, top + h - bh - 11), size: 8, bold: true, color: const Color(0xFF374151));
        }
      }
      _text(canvas, labels[i], Offset(cx, size.height - bottom + 8), size: 10);
    }
  }

  @override
  bool shouldRepaint(covariant _GroupedPainter o) =>
      o.a != a || o.b != b || o.labels != labels;
}
