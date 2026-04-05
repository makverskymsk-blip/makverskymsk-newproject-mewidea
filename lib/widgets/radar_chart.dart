import 'dart:math';
import 'package:flutter/material.dart';

class RadarChart extends StatelessWidget {
  final List<RadarEntry> entries;
  final Color color;
  final double size;

  const RadarChart({
    super.key,
    required this.entries,
    this.color = const Color(0xFF4A90D9),
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarChartPainter(
          entries: entries,
          color: color,
        ),
      ),
    );
  }
}

class RadarEntry {
  final String label;
  final int value; // 0-99
  final int maxValue;

  const RadarEntry({
    required this.label,
    required this.value,
    this.maxValue = 99,
  });

  double get fraction => (value / maxValue).clamp(0.0, 1.0);
}

class _RadarChartPainter extends CustomPainter {
  final List<RadarEntry> entries;
  final Color color;

  _RadarChartPainter({
    required this.entries,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 24;
    final count = entries.length;
    final angleStep = (2 * pi) / count;
    // Start from top (-pi/2)
    const startAngle = -pi / 2;

    // Draw grid levels (33%, 66%, 100%)
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final level in [0.33, 0.66, 1.0]) {
      final r = radius * level;
      final path = Path();
      for (int i = 0; i < count; i++) {
        final angle = startAngle + angleStep * i;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axis lines
    final axisPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < count; i++) {
      final angle = startAngle + angleStep * i;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    // Draw data polygon (filled)
    final dataPath = Path();
    for (int i = 0; i < count; i++) {
      final angle = startAngle + angleStep * i;
      final r = radius * entries[i].fraction;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(dataPath, strokePaint);

    // Draw data points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final angle = startAngle + angleStep * i;
      final r = radius * entries[i].fraction;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      // White center dot
      canvas.drawCircle(
        Offset(x, y),
        1.5,
        Paint()..color = Colors.white,
      );
    }

    // Draw labels
    for (int i = 0; i < count; i++) {
      final angle = startAngle + angleStep * i;
      final labelRadius = radius + 16;
      final x = center.dx + labelRadius * cos(angle);
      final y = center.dy + labelRadius * sin(angle);

      final label = entries[i].label;
      final value = entries[i].value.toString();

      // Value text
      final valuePainter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Label text
      final labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Position: center the combined height
      final totalH = valuePainter.height + 1 + labelPainter.height;
      final offsetY = y - totalH / 2;
      final offsetXValue = x - valuePainter.width / 2;
      final offsetXLabel = x - labelPainter.width / 2;

      valuePainter.paint(canvas, Offset(offsetXValue, offsetY));
      labelPainter.paint(
          canvas, Offset(offsetXLabel, offsetY + valuePainter.height + 1));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter old) {
    return old.entries != entries || old.color != color;
  }
}
