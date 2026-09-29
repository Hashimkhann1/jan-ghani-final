import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../../../core/color/app_color.dart';
import '../../data/model/sale_summary_model.dart';

/// AppBar ke graph icon se khulta hai — selected date range ka
/// Sale / Return / Customer Collection line graph.
Future<void> showSaleSummaryTrendDialog({
  required BuildContext                        context,
  required Future<List<SaleTrendPoint>> Function() load,
  required String                              subtitle,
}) {
  return showDialog(
    context: context,
    builder: (_) => _SaleTrendDialog(load: load, subtitle: subtitle),
  );
}

final _amtFmt = NumberFormat('#,##,###', 'en_IN');
String _rs(double v) => '${v < 0 ? '- ' : ''}Rs ${_amtFmt.format(v.abs().round())}';

class _Series {
  final String       name;
  final Color        color;
  final List<double> values;
  const _Series(this.name, this.color, this.values);

  double get total => values.fold(0, (a, b) => a + b);
}

class _SaleTrendDialog extends StatefulWidget {
  final Future<List<SaleTrendPoint>> Function() load;
  final String                                 subtitle;
  const _SaleTrendDialog({required this.load, required this.subtitle});

  @override
  State<_SaleTrendDialog> createState() => _SaleTrendDialogState();
}

class _SaleTrendDialogState extends State<_SaleTrendDialog> {
  late final Future<List<SaleTrendPoint>> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.all(w < 600 ? 12 : 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sale Trend',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D23))),
                        const SizedBox(height: 2),
                        Text(widget.subtitle,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<SaleTrendPoint>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 360,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColor.primary)),
                    );
                  }
                  if (snap.hasError) {
                    return SizedBox(
                      height: 360,
                      child: Center(
                        child: Text('Graph load error: ${snap.error}',
                            style: const TextStyle(color: AppColor.error)),
                      ),
                    );
                  }
                  final points = snap.data!;
                  final series = [
                    _Series('Sale', const Color(0xFF3B9A5E),
                        points.map((p) => p.sale).toList()),
                    _Series('Return Sale', const Color(0xFFEF4444),
                        points.map((p) => p.saleReturn).toList()),
                    _Series('Customer Collection', const Color(0xFFD97706),
                        points.map((p) => p.collection).toList()),
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [for (final s in series) _LegendChip(s)],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 340,
                        child: series.every((s) => s.values.every((v) => v == 0))
                            ? Center(
                                child: Text('Is range mein koi data nahi',
                                    style: TextStyle(
                                        color: Colors.grey.shade400)))
                            : _TrendChart(
                                labels: points.map((p) => p.label).toList(),
                                series: series,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final _Series s;
  const _LegendChip(this.s);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: s.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('${s.name}: ',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          Text(_rs(s.total),
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: s.color)),
        ]),
      );
}

// ─── Multi-line chart (hover / tap → tooltip) ─────────────────────────────
class _TrendChart extends StatefulWidget {
  final List<String>  labels;
  final List<_Series> series;
  const _TrendChart({required this.labels, required this.series});

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> {
  int? _selected;

  void _select(Offset local, double width) {
    final n = widget.labels.length;
    if (n == 0) return;
    final i = _TrendPainter.indexAt(local.dx, width, n);
    if (i != _selected) setState(() => _selected = i);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return MouseRegion(
        onHover: (e) => _select(e.localPosition, c.maxWidth),
        onExit: (_) => setState(() => _selected = null),
        child: GestureDetector(
          onTapDown: (d) => _select(d.localPosition, c.maxWidth),
          onHorizontalDragUpdate: (d) => _select(d.localPosition, c.maxWidth),
          child: CustomPaint(
            size: Size(c.maxWidth, c.maxHeight),
            painter: _TrendPainter(
              labels:   widget.labels,
              series:   widget.series,
              selected: _selected,
            ),
          ),
        ),
      );
    });
  }
}

class _TrendPainter extends CustomPainter {
  final List<String>  labels;
  final List<_Series> series;
  final int?          selected;
  _TrendPainter({
    required this.labels,
    required this.series,
    required this.selected,
  });

  static const _left   = 48.0;
  static const _right  = 12.0;
  static const _top    = 10.0;
  static const _bottom = 28.0;

  static double xAt(int i, double width, int n) => n == 1
      ? (_left + width - _right) / 2
      : _left + (width - _left - _right) * i / (n - 1);

  static int indexAt(double dx, double width, int n) {
    if (n == 1) return 0;
    final t = (dx - _left) / (width - _left - _right);
    return (t * (n - 1)).round().clamp(0, n - 1);
  }

  static String _k(double v) {
    final a = v.abs(), s = v < 0 ? '-' : '';
    if (a >= 100000) return '$s${(a / 100000).toStringAsFixed(1)}L';
    if (a >= 1000)   return '$s${(a / 1000).toStringAsFixed(a >= 10000 ? 0 : 1)}k';
    return '$s${a.toStringAsFixed(0)}';
  }

  TextPainter _tp(String s, {Color color = const Color(0xFF9CA3AF),
      double size = 10, FontWeight weight = FontWeight.w400}) =>
      TextPainter(
        text: TextSpan(
            text: s,
            style: TextStyle(color: color, fontSize: size, fontWeight: weight)),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    if (n == 0) return;
    final all = series.expand((s) => s.values);
    var lo = all.fold<double>(0, (a, b) => a < b ? a : b);
    var hi = all.fold<double>(0, (a, b) => a > b ? a : b);
    if (hi == lo) hi = lo + 1;

    final chartH = size.height - _top - _bottom;
    double yOf(double v) => _top + chartH * (1 - (v - lo) / (hi - lo));

    // Grid + Y labels
    final grid = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 0.8;
    for (var i = 0; i <= 5; i++) {
      final v = lo + (hi - lo) * i / 5;
      final y = yOf(v);
      canvas.drawLine(Offset(_left, y), Offset(size.width - _right, y), grid);
      final tp = _tp(_k(v));
      tp.paint(canvas, Offset(_left - tp.width - 8, y - tp.height / 2));
    }
    canvas.drawLine(
      Offset(_left, yOf(0)),
      Offset(size.width - _right, yOf(0)),
      Paint()
        ..color = const Color(0xFFD1D5DB)
        ..strokeWidth = 1,
    );

    // X labels — overlap se bachne ke liye har k-th
    final maxLabels = ((size.width - _left - _right) / 56).floor().clamp(1, n);
    final step = (n / maxLabels).ceil();
    for (var i = 0; i < n; i += step) {
      final tp = _tp(labels[i], color: const Color(0xFF6B7280));
      tp.paint(canvas,
          Offset(xAt(i, size.width, n) - tp.width / 2, size.height - _bottom + 8));
    }

    // Selected guide line
    if (selected != null) {
      final x = xAt(selected!, size.width, n);
      canvas.drawLine(
        Offset(x, _top),
        Offset(x, _top + chartH),
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = 1,
      );
    }

    // Lines + dots
    for (final s in series) {
      final pts = [
        for (var i = 0; i < n; i++) Offset(xAt(i, size.width, n), yOf(s.values[i])),
      ];
      if (n > 1) {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final p in pts.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = s.color
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round,
        );
      }
      final showDots = n <= 40;
      for (var i = 0; i < n; i++) {
        if (!showDots && i != selected) continue;
        final r = i == selected ? 5.0 : 3.5;
        canvas.drawCircle(pts[i], r + 1.5, Paint()..color = Colors.white);
        canvas.drawCircle(pts[i], r, Paint()..color = s.color);
      }
    }

    if (selected != null) _drawTooltip(canvas, size, n);
  }

  void _drawTooltip(Canvas canvas, Size size, int n) {
    final i = selected!;
    final title = _tp(labels[i],
        color: const Color(0xFF1A1D23), size: 11, weight: FontWeight.w700);
    final lines = [
      for (final s in series)
        (s.color, _tp('${s.name}: ${_rs(s.values[i])}',
            color: const Color(0xFF374151), size: 11)),
    ];
    const pad = 10.0, gap = 5.0, dot = 12.0;
    final w = [title.width, ...lines.map((l) => l.$2.width + dot)]
            .reduce((a, b) => a > b ? a : b) + pad * 2;
    final h = pad * 2 + title.height +
        lines.fold<double>(0, (a, l) => a + l.$2.height + gap);

    final x0 = xAt(i, size.width, n);
    var left = x0 + 12;
    if (left + w > size.width) left = x0 - 12 - w;
    if (left < 0) left = 0;
    final rect = Rect.fromLTWH(left, _top, w, h);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 2)), const Radius.circular(8)),
      Paint()..color = Colors.black.withOpacity(0.06),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke,
    );

    var y = rect.top + pad;
    title.paint(canvas, Offset(rect.left + pad, y));
    y += title.height + gap;
    for (final (color, tp) in lines) {
      canvas.drawCircle(
          Offset(rect.left + pad + 4, y + tp.height / 2), 4, Paint()..color = color);
      tp.paint(canvas, Offset(rect.left + pad + dot, y));
      y += tp.height + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.selected != selected ||
      !identical(old.series, series) ||
      !identical(old.labels, labels);
}
