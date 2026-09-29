import 'package:flutter/material.dart';

import '../../../../../../core/color/app_color.dart';
import '../../data/model/accountant_dashboard_model.dart';

// ─── Shared chart panel (branch dashboard chart card style) ───────────────
class _ChartPanel extends StatelessWidget {
  final String  title;
  final Widget? trailing;
  final bool    isLoading;
  final bool    isEmpty;
  final Widget  chart;

  const _ChartPanel({
    required this.title,
    required this.isLoading,
    required this.isEmpty,
    required this.chart,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D23),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: isLoading
                ? const Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : isEmpty
                    ? Center(
                        child: Text('Is period mein koi data nahi',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400)))
                    : chart,
          ),
        ],
      ),
    );
  }
}

// ─── Weekly / Monthly toggle ──────────────────────────────────────────────
class TrendPeriodToggle extends StatelessWidget {
  final DashboardTrendPeriod              value;
  final ValueChanged<DashboardTrendPeriod> onChanged;

  const TrendPeriodToggle(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(DashboardTrendPeriod p, String label) {
      final selected = p == value;
      return GestureDetector(
        onTap: () => onChanged(p),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColor.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF6B7280),
              )),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip(DashboardTrendPeriod.weekly, 'Weekly'),
          chip(DashboardTrendPeriod.monthly, 'Monthly'),
        ],
      ),
    );
  }
}

// ─── Bar chart (Sales / Credit Sale) ──────────────────────────────────────
class TrendBarChart extends StatelessWidget {
  final String                              title;
  final List<DashboardTrendPoint>           data;
  final double Function(DashboardTrendPoint) valueOf;
  final bool                                isLoading;
  final List<Color>                         gradient;
  final Widget?                             trailing;

  const TrendBarChart({
    super.key,
    required this.title,
    required this.data,
    required this.valueOf,
    required this.isLoading,
    this.gradient = const [Color(0xFF3B9A5E), Color(0xFF8ED4AA)],
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final values = data.map(valueOf).toList();
    return _ChartPanel(
      title:     title,
      trailing:  trailing,
      isLoading: isLoading,
      isEmpty:   values.every((v) => v == 0),
      chart: CustomPaint(
        painter: _BarChartPainter(
          labels:   data.map((p) => p.label).toList(),
          values:   values,
          gradient: gradient,
        ),
        size: Size.infinite,
      ),
    );
  }
}

// ─── Line chart (Profit / Installment) ────────────────────────────────────
class TrendLineChart extends StatelessWidget {
  final String                              title;
  final List<DashboardTrendPoint>           data;
  final double Function(DashboardTrendPoint) valueOf;
  final bool                                isLoading;
  final Color                               color;
  final Widget?                             trailing;

  const TrendLineChart({
    super.key,
    required this.title,
    required this.data,
    required this.valueOf,
    required this.isLoading,
    this.color = const Color(0xFF38BDF8),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final values = data.map(valueOf).toList();
    return _ChartPanel(
      title:     title,
      trailing:  trailing,
      isLoading: isLoading,
      isEmpty:   values.length < 2 || values.every((v) => v == 0),
      chart: CustomPaint(
        painter: _LineChartPainter(
          labels: data.map((p) => p.label).toList(),
          values: values,
          color:  color,
        ),
        size: Size.infinite,
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────
const _leftPad   = 40.0;
const _topPad    = 18.0;
const _bottomPad = 26.0;

String _kLabel(double v) {
  final a = v.abs();
  final s = v < 0 ? '-' : '';
  if (a >= 100000) return '$s${(a / 100000).toStringAsFixed(1)}L';
  if (a >= 1000)   return '$s${(a / 1000).toStringAsFixed(a >= 10000 ? 0 : 1)}k';
  return '$s${a.toStringAsFixed(0)}';
}

void _text(Canvas c, String s, Offset at,
    {Color color = const Color(0xFF9CA3AF),
    double size = 9,
    FontWeight weight = FontWeight.w400,
    bool center = false}) {
  final tp = TextPainter(
    text: TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center ? at - Offset(tp.width / 2, 0) : at);
}

/// Y-axis range (0 hamesha shamil — negative values bhi sahi dikhen).
(double, double) _range(List<double> values) {
  var lo = values.fold<double>(0, (a, b) => a < b ? a : b);
  var hi = values.fold<double>(0, (a, b) => a > b ? a : b);
  if (hi == lo) hi = lo + 1;
  return (lo, hi);
}

/// Grid lines + Y labels; value → y mapper return karta hai.
double Function(double) _drawGrid(
    Canvas canvas, Size size, double lo, double hi) {
  final chartH = size.height - _topPad - _bottomPad;
  double yOf(double v) => _topPad + chartH * (1 - (v - lo) / (hi - lo));

  final grid = Paint()
    ..color = const Color(0xFFEEEEEE)
    ..strokeWidth = 0.8;
  for (var i = 0; i <= 4; i++) {
    final v = lo + (hi - lo) * i / 4;
    final y = yOf(v);
    canvas.drawLine(Offset(_leftPad, y), Offset(size.width, y), grid);
    _text(canvas, _kLabel(v), Offset(0, y - 6));
  }
  // Zero / X-axis
  canvas.drawLine(
    Offset(_leftPad, yOf(0)),
    Offset(size.width, yOf(0)),
    Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1,
  );
  return yOf;
}

class _BarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final List<Color>  gradient;
  _BarChartPainter(
      {required this.labels, required this.values, required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final (lo, hi) = _range(values);
    final yOf  = _drawGrid(canvas, size, lo, hi);
    final slot = (size.width - _leftPad) / values.length;
    final w    = (slot * 0.55).clamp(8.0, 42.0);

    for (var i = 0; i < values.length; i++) {
      final cx  = _leftPad + slot * i + slot / 2;
      final v   = values[i];
      final top = yOf(v > 0 ? v : 0);
      final bot = yOf(v > 0 ? 0 : v);
      final rect = Rect.fromLTRB(cx - w / 2, top, cx + w / 2, bot);

      if (rect.height > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: v >= 0
                  ? gradient
                  : const [Color(0xFFFCA5A5), Color(0xFFEF4444)],
            ).createShader(rect),
        );
      }
      if (v != 0) {
        _text(canvas, _kLabel(v), Offset(cx, top - 13),
            color: const Color(0xFF374151),
            weight: FontWeight.w600,
            center: true);
      }
      _text(canvas, labels[i], Offset(cx, size.height - _bottomPad + 8),
          color: const Color(0xFF6B7280), size: 10, center: true);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      !_listEq(old.values, values) ||
      !_listEq(old.labels, labels) ||
      !_listEq(old.gradient, gradient);
}

class _LineChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final Color        color;
  _LineChartPainter(
      {required this.labels, required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final (lo, hi) = _range(values);
    final yOf  = _drawGrid(canvas, size, lo, hi);
    final slot = (size.width - _leftPad) / values.length;

    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(_leftPad + slot * i + slot / 2, yOf(values[i])),
    ];

    Path smooth() {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 0; i < pts.length - 1; i++) {
        final mx = (pts[i].dx + pts[i + 1].dx) / 2;
        p.cubicTo(mx, pts[i].dy, mx, pts[i + 1].dy, pts[i + 1].dx,
            pts[i + 1].dy);
      }
      return p;
    }

    // Fill (zero line tak)
    final fill = smooth()
      ..lineTo(pts.last.dx, yOf(0))
      ..lineTo(pts.first.dx, yOf(0))
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withOpacity(0.12));

    canvas.drawPath(
      smooth(),
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < pts.length; i++) {
      final neg = values[i] < 0;
      canvas.drawCircle(pts[i], 5, Paint()..color = Colors.white);
      canvas.drawCircle(pts[i], 3.5,
          Paint()..color = neg ? const Color(0xFFEF4444) : color);
      if (values[i] != 0) {
        _text(canvas, _kLabel(values[i]), pts[i] + const Offset(0, -16),
            color: neg ? const Color(0xFFEF4444) : const Color(0xFF374151),
            weight: FontWeight.w600,
            center: true);
      }
      _text(canvas, labels[i], Offset(pts[i].dx, size.height - _bottomPad + 8),
          color: const Color(0xFF6B7280), size: 10, center: true);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      !_listEq(old.values, values) ||
      !_listEq(old.labels, labels) ||
      old.color != color;
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
