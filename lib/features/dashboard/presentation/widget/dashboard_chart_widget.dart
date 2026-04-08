import 'package:flutter/material.dart';

import '../../data/model/dashboard_model.dart';

class WeeklySalesChart extends StatelessWidget {
  final List<WeeklySale> data;
  const WeeklySalesChart({super.key, required this.data});

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
          const Text(
            'Last Week Sales',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D23),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _BarChartPainter(data),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<WeeklySale> data;
  _BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final barW = (size.width - 40) / data.length;
    const barPad = 8.0;
    const bottomPad = 28.0;
    const topPad = 10.0;
    final chartH = size.height - bottomPad - topPad;

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 0.8;
    const gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final y = topPad + chartH - (chartH * i / gridCount);
      canvas.drawLine(Offset(36, y), Offset(size.width, y), gridPaint);

      // Y labels
      final label = _kLabel((maxVal * i / gridCount));
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - 6));
    }

    // Bars
    for (int i = 0; i < data.length; i++) {
      final x = 36 + i * barW + barPad / 2;
      final barHeight = (data[i].amount / maxVal) * chartH;
      final y = topPad + chartH - barHeight;
      final w = barW - barPad;

      // Green gradient bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, barHeight),
        const Radius.circular(4),
      );

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3B9A5E),
          const Color(0xFF8ED4AA),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(x, y, w, barHeight),
        );

      canvas.drawRRect(rect, paint);

      // X labels
      final labelTp = TextPainter(
        text: TextSpan(
          text: data[i].day,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(
        canvas,
        Offset(x + w / 2 - labelTp.width / 2, size.height - bottomPad + 8),
      );
    }

    // Axes
    final axisPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1;
    // Y-axis
    canvas.drawLine(
      Offset(36, topPad),
      Offset(36, topPad + chartH),
      axisPaint,
    );
    // X-axis with arrow
    canvas.drawLine(
      Offset(36, topPad + chartH),
      Offset(size.width, topPad + chartH),
      axisPaint,
    );
    // Arrow head
    final arrPaint = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.fill;
    final arrPath = Path()
      ..moveTo(size.width, topPad + chartH)
      ..lineTo(size.width - 6, topPad + chartH - 3)
      ..lineTo(size.width - 6, topPad + chartH + 3)
      ..close();
    canvas.drawPath(arrPath, arrPaint);
  }

  String _kLabel(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Top Products Line Chart ───────────────────────────────────────────────
class TopProductsLineChart extends StatelessWidget {
  final List<TopProduct> products;
  const TopProductsLineChart({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final top5 = products.take(5).toList();
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
          const Text(
            'Top Products — Sales Trend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D23),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _LineChartPainter(top5),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<TopProduct> data;
  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxQty = data.map((e) => e.qty.toDouble()).reduce((a, b) => a > b ? a : b);
    const bottomPad = 40.0;
    const leftPad = 36.0;
    const topPad = 10.0;
    final chartH = size.height - bottomPad - topPad;
    final chartW = size.width - leftPad;
    final stepX = chartW / (data.length - 1);

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartH - (chartH * i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final label = (maxQty * i / 4).toInt().toString();
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - 6));
    }

    // Compute points
    final points = data.asMap().entries.map((e) {
      final x = leftPad + e.key * stepX;
      final y = topPad + chartH - (e.value.qty / maxQty) * chartH;
      return Offset(x, y);
    }).toList();

    // Fill area
    final fillPath = Path()..moveTo(points.first.dx, topPad + chartH);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }
    fillPath.lineTo(points.last.dx, topPad + chartH);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = const Color(0xFF38BDF8).withOpacity(0.12)
        ..style = PaintingStyle.fill,
    );

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dots + X labels
    for (int i = 0; i < points.length; i++) {
      // Outer circle
      canvas.drawCircle(
        points[i],
        5,
        Paint()..color = Colors.white,
      );
      // Inner dot
      canvas.drawCircle(
        points[i],
        3.5,
        Paint()..color = const Color(0xFF38BDF8),
      );

      // X label (product name truncated)
      final name = data[i].name.split(' ').first;
      final tp = TextPainter(
        text: TextSpan(
          text: name,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(points[i].dx - tp.width / 2, size.height - bottomPad + 8),
      );
    }

    // Axes
    final axisPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(leftPad, topPad), Offset(leftPad, topPad + chartH), axisPaint);
    canvas.drawLine(Offset(leftPad, topPad + chartH), Offset(size.width, topPad + chartH), axisPaint);

    // Arrow
    final arrPath = Path()
      ..moveTo(size.width, topPad + chartH)
      ..lineTo(size.width - 6, topPad + chartH - 3)
      ..lineTo(size.width - 6, topPad + chartH + 3)
      ..close();
    canvas.drawPath(arrPath, Paint()..color = const Color(0xFF6B7280));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}