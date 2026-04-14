import 'package:flutter/material.dart';

/// Premium PL logo with sport badges.
/// Uses TextPainter for crisp typography + 4 sport icons below.
class PLLogo extends StatelessWidget {
  final double size;

  const PLLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PLLogoPainter(),
      ),
    );
  }
}

class _PLLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final r = s * 0.22;

    // ─── Background ───
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(r),
    );
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6B35), Color(0xFFE8430A)],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawRRect(bgRect, bgPaint);

    // ─── Highlight gloss ───
    final glossPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.6),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawRRect(bgRect, glossPaint);

    // ─── "PL" text via TextPainter (uses system bold font) ───
    final fontSize = s * 0.44;
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'PL',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: s * 0.03,
          height: 1.0,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Center PL in the upper portion (leave room for sport badges)
    final textX = (s - textPainter.width) / 2;
    final textY = s * 0.10;
    textPainter.paint(canvas, Offset(textX, textY));

    // ─── Thin divider line ───
    final divY = textY + fontSize + s * 0.04;
    final divPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s * 0.20, divY),
      Offset(s * 0.80, divY),
      divPaint,
    );

    // ─── 4 Sport badges row ───
    final iconY = divY + s * 0.06;
    final iconSize = s * 0.16;
    final totalIconsWidth = iconSize * 4 + s * 0.04 * 3; // 4 icons + 3 gaps
    final startX = (s - totalIconsWidth) / 2;
    final iconSpacing = iconSize + s * 0.04;

    final icons = [
      Icons.sports_soccer,       // Футбол
      Icons.sports_hockey,       // Хоккей
      Icons.sports_tennis,       // Теннис
      Icons.sports_esports,      // Киберспорт
    ];

    for (int i = 0; i < icons.length; i++) {
      final cx = startX + i * iconSpacing + iconSize / 2;
      final cy = iconY + iconSize / 2;

      // Small circle background
      final circlePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2);
      canvas.drawCircle(Offset(cx, cy), iconSize / 2, circlePaint);

      // Icon via TextPainter (Material Icons)
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icons[i].codePoint),
          style: TextStyle(
            fontSize: iconSize * 0.55,
            fontFamily: icons[i].fontFamily,
            package: icons[i].fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(cx - iconPainter.width / 2, cy - iconPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
