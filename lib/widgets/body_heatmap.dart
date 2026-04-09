import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Data for one muscle group used by the heatmap.
class MuscleHeatData {
  final String name;
  final double intensity; // 0.0 – 1.0 normalized
  final double rawValue;  // original tonnage

  const MuscleHeatData({
    required this.name,
    required this.intensity,
    required this.rawValue,
  });
}

/// Body Heatmap — image-based silhouette with glowing muscle zone overlays.
class BodyHeatmap extends StatefulWidget {
  final Map<String, double> muscleData;
  final bool showFront;

  const BodyHeatmap({
    super.key,
    required this.muscleData,
    this.showFront = true,
  });

  @override
  State<BodyHeatmap> createState() => _BodyHeatmapState();
}

class _BodyHeatmapState extends State<BodyHeatmap>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  String? _selectedMuscle;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  List<MuscleHeatData> _normalizeData() {
    if (widget.muscleData.isEmpty) return [];
    final maxVal = widget.muscleData.values.fold(0.0, math.max);
    if (maxVal <= 0) return [];
    return widget.muscleData.entries.map((e) {
      return MuscleHeatData(
        name: e.key,
        intensity: (e.value / maxVal).clamp(0.0, 1.0),
        rawValue: e.value,
      );
    }).toList()
      ..sort((a, b) => b.intensity.compareTo(a.intensity));
  }

  /// Heat color gradient: blue → green → yellow → orange → red
  static Color intensityColor(double intensity) {
    if (intensity <= 0) return const Color(0xFF1A1A2E);
    if (intensity < 0.15) return const Color(0xFF004D40);
    if (intensity < 0.3) return const Color(0xFF00796B);
    if (intensity < 0.45) return const Color(0xFF388E3C);
    if (intensity < 0.6) return const Color(0xFFF9A825);
    if (intensity < 0.75) return const Color(0xFFFF8F00);
    if (intensity < 0.9) return const Color(0xFFE65100);
    return const Color(0xFFD50000);
  }

  static String intensityLabel(double intensity) {
    if (intensity <= 0) return 'Нет данных';
    if (intensity < 0.2) return 'Лёгкая';
    if (intensity < 0.4) return 'Умеренная';
    if (intensity < 0.6) return 'Средняя';
    if (intensity < 0.8) return 'Высокая';
    return 'Максимальная';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);
    final heatData = _normalizeData();

    final intensityMap = <String, double>{};
    for (final d in heatData) {
      intensityMap[d.name] = d.intensity;
    }

    return Column(
      children: [
        // ─── Body with image + overlay ───
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, child) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GestureDetector(
                  onTapDown: (details) => _handleTap(details, context),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1A1A2E),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background grid pattern
                                CustomPaint(
                                  size: Size(constraints.maxWidth, constraints.maxHeight),
                                  painter: _GridPatternPainter(),
                                ),
                                // Body image
                                Positioned.fill(
                                  child: Image.asset(
                                    widget.showFront
                                        ? 'assets/images/body_front.png'
                                        : 'assets/images/body_back.png',
                                    fit: BoxFit.contain,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    colorBlendMode: BlendMode.modulate,
                                  ),
                                ),
                                // Muscle zone overlays
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _MuscleOverlayPainter(
                                      intensityMap: intensityMap,
                                      glowValue: _glowAnim.value,
                                      showFront: widget.showFront,
                                      selectedMuscle: _selectedMuscle,
                                    ),
                                  ),
                                ),
                                // Glow aura effect for high-intensity muscles
                                if (heatData.any((d) => d.intensity > 0.5))
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: _GlowAuraPainter(
                                          intensityMap: intensityMap,
                                          glowValue: _glowAnim.value,
                                          showFront: widget.showFront,
                                        ),
                                      ),
                                    ),
                                  ),
                                // View label
                                Positioned(
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF2A2A3E),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      widget.showFront ? 'FRONT' : 'BACK',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // ─── Legend gradient bar ───
        _buildGradientLegend(t),

        const SizedBox(height: 14),

        // ─── Muscle list ───
        if (heatData.isNotEmpty) _buildMuscleList(t, heatData),
      ],
    );
  }

  void _handleTap(TapDownDetails details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPos = details.localPosition;
    final relX = localPos.dx / box.size.width;
    final relY = localPos.dy / box.size.height;

    String? tapped;

    if (widget.showFront) {
      if (relY < 0.1) {
        tapped = null;
      } else if (relY < 0.28) {
        if (relX > 0.32 && relX < 0.68) {
          tapped = 'Грудь';
        } else {
          tapped = 'Плечи';
        }
      } else if (relY < 0.38) {
        if (relX < 0.25 || relX > 0.75) {
          tapped = 'Бицепс';
        } else {
          tapped = 'Пресс';
        }
      } else if (relY < 0.52) {
        if (relX > 0.3 && relX < 0.7) {
          tapped = 'Пресс';
        } else {
          tapped = 'Трицепс';
        }
      } else {
        tapped = 'Ноги';
      }
    } else {
      if (relY < 0.1) {
        tapped = null;
      } else if (relY < 0.5) {
        if (relX > 0.3 && relX < 0.7) {
          tapped = 'Спина';
        } else {
          tapped = 'Плечи';
        }
      } else {
        tapped = 'Ноги';
      }
    }

    setState(() {
      _selectedMuscle = (_selectedMuscle == tapped) ? null : tapped;
    });
  }

  Widget _buildGradientLegend(AppThemeColors t) {
    return Column(
      children: [
        Container(
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF004D40),
                Color(0xFF388E3C),
                Color(0xFFF9A825),
                Color(0xFFFF8F00),
                Color(0xFFE65100),
                Color(0xFFD50000),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Нет', style: TextStyle(color: t.textHint, fontSize: 9)),
              Text('Макс',
                  style: TextStyle(color: t.textHint, fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleList(AppThemeColors t, List<MuscleHeatData> data) {
    return Column(
      children: data.map((d) {
        final isSelected = _selectedMuscle == d.name;
        final color = intensityColor(d.intensity);
        final glowColor = color.withValues(alpha: 0.3);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMuscle = isSelected ? null : d.name;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.12) : t.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isSelected ? color.withValues(alpha: 0.6) : t.borderLight,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Flame icon for hot muscles
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      d.intensity >= 0.8
                          ? '🔥'
                          : d.intensity >= 0.5
                              ? '💪'
                              : '•',
                      style: TextStyle(
                        fontSize: d.intensity >= 0.5 ? 16 : 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              intensityLabel(d.intensity),
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(d.intensity * 100).round()}%',
                            style: TextStyle(
                              color: t.textHint,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatNumber(d.rawValue)} кг',
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      height: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Stack(
                          children: [
                            Container(color: t.borderLight),
                            FractionallySizedBox(
                              widthFactor: d.intensity,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withValues(alpha: 0.6),
                                      color,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatNumber(double n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toStringAsFixed(0);
  }
}

// ═══════════════════════════════════════════════════════════
//  Background grid pattern
// ═══════════════════════════════════════════════════════════

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A2E).withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Subtle dot grid
    final dotPaint = Paint()
      ..color = const Color(0xFF2A2A3E).withValues(alpha: 0.3)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════
//  Muscle zone overlay painter — colored regions on body image
// ═══════════════════════════════════════════════════════════

class _MuscleOverlayPainter extends CustomPainter {
  final Map<String, double> intensityMap;
  final double glowValue;
  final bool showFront;
  final String? selectedMuscle;

  _MuscleOverlayPainter({
    required this.intensityMap,
    required this.glowValue,
    required this.showFront,
    this.selectedMuscle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Image is square (1024x1024), fitted with BoxFit.contain
    // Container is taller than wide (AspectRatio 0.6)
    // So image fills width, centered vertically
    final imgW = size.width;
    final imgH = size.width; // square image
    final offsetY = (size.height - imgH) / 2;

    // All coordinates relative to image bounds
    final imgRect = Rect.fromLTWH(0, offsetY, imgW, imgH);

    if (showFront) {
      _paintFront(canvas, cx, imgRect);
    } else {
      _paintBack(canvas, cx, imgRect);
    }
  }

  void _paintFront(Canvas canvas, double cx, Rect img) {
    final w = img.width;
    final t = img.top;
    final ih = img.height;

    // Chest — двойная грудная мышца
    _paintMuscleZone(canvas, 'Грудь', [
      // Left pec
      _createMuscleRegion(cx, ih,
          cx - 0.11 * w, t + 0.27 * ih,
          cx - 0.01 * w, t + 0.26 * ih,
          cx - 0.01 * w, t + 0.36 * ih,
          cx - 0.09 * w, t + 0.35 * ih,
          bulge: 0.012 * w),
      // Right pec
      _createMuscleRegion(cx, ih,
          cx + 0.01 * w, t + 0.26 * ih,
          cx + 0.11 * w, t + 0.27 * ih,
          cx + 0.09 * w, t + 0.35 * ih,
          cx + 0.01 * w, t + 0.36 * ih,
          bulge: 0.012 * w),
    ]);

    // Abs — 6-pack blocks
    _paintMuscleZone(canvas, 'Пресс', [
      _createRect(cx - 0.045 * w, t + 0.37 * ih,
          0.09 * w, 0.15 * ih, 6),
    ]);

    // Shoulders — deltoids
    for (final sign in [-1.0, 1.0]) {
      _paintMuscleZone(canvas, 'Плечи', [
        _createOval(
          cx + sign * 0.16 * w,
          t + 0.28 * ih,
          0.04 * w,
          0.04 * ih,
        ),
      ]);
    }

    // Biceps — inner upper arm
    for (final sign in [-1.0, 1.0]) {
      _paintMuscleZone(canvas, 'Бицепс', [
        _createAngledOval(
          cx + sign * 0.15 * w,
          t + 0.36 * ih,
          0.015 * w,
          0.055 * ih,
          sign * 0.25,
        ),
      ]);
    }

    // Quads / Legs
    for (final sign in [-1.0, 1.0]) {
      _paintMuscleZone(canvas, 'Ноги', [
        _createOval(
          cx + sign * 0.06 * w,
          t + 0.70 * ih,
          0.04 * w,
          0.12 * ih,
        ),
      ]);
    }
  }

  void _paintBack(Canvas canvas, double cx, Rect img) {
    final w = img.width;
    final t = img.top;
    final ih = img.height;

    // Upper back / lats
    _paintMuscleZone(canvas, 'Спина', [
      // Left lat
      _createMuscleRegion(cx, ih,
          cx - 0.13 * w, t + 0.30 * ih,
          cx - 0.02 * w, t + 0.29 * ih,
          cx - 0.03 * w, t + 0.50 * ih,
          cx - 0.10 * w, t + 0.48 * ih,
          bulge: 0.02 * w),
      // Right lat
      _createMuscleRegion(cx, ih,
          cx + 0.02 * w, t + 0.29 * ih,
          cx + 0.13 * w, t + 0.30 * ih,
          cx + 0.10 * w, t + 0.48 * ih,
          cx + 0.03 * w, t + 0.50 * ih,
          bulge: 0.02 * w),
    ]);

    // Rear delts
    for (final sign in [-1.0, 1.0]) {
      _paintMuscleZone(canvas, 'Плечи', [
        _createOval(
          cx + sign * 0.16 * w,
          t + 0.28 * ih,
          0.04 * w,
          0.04 * ih,
        ),
      ]);
    }

    // Triceps — inner upper arm
    for (final sign in [-1.0, 1.0]) {
      _paintMuscleZone(canvas, 'Трицепс', [
        _createAngledOval(
          cx + sign * 0.15 * w,
          t + 0.36 * ih,
          0.015 * w,
          0.055 * ih,
          sign * 0.25,
        ),
      ]);
    }

    // Hamstrings / Legs
    for (final sign in [-1.0, 1.0]) {
      _paintMuscleZone(canvas, 'Ноги', [
        _createOval(
          cx + sign * 0.06 * w,
          t + 0.70 * ih,
          0.04 * w,
          0.12 * ih,
        ),
      ]);
    }
  }

  Path _createMuscleRegion(
    double cx, double h,
    double x1, double y1,
    double x2, double y2,
    double x3, double y3,
    double x4, double y4, {
    double bulge = 0,
  }) {
    final path = Path();
    path.moveTo(x1, y1);
    if (bulge > 0) {
      final midX12 = (x1 + x2) / 2;
      final midY12 = (y1 + y2) / 2 - bulge;
      path.quadraticBezierTo(midX12, midY12, x2, y2);
    } else {
      path.lineTo(x2, y2);
    }
    path.quadraticBezierTo((x2 + x3) / 2 + bulge * 0.3, (y2 + y3) / 2, x3, y3);
    final midX34 = (x3 + x4) / 2;
    final midY34 = (y3 + y4) / 2 + bulge * 0.5;
    path.quadraticBezierTo(midX34, midY34, x4, y4);
    path.quadraticBezierTo((x4 + x1) / 2 - bulge * 0.3, (y4 + y1) / 2, x1, y1);
    path.close();
    return path;
  }

  Path _createOval(double cx, double cy, double rx, double ry) {
    return Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));
  }

  /// Rotated oval for muscles that follow angled limbs (biceps, triceps)
  Path _createAngledOval(double cx, double cy, double rx, double ry, double angle) {
    final path = Path();
    path.addOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2));
    final matrix = Matrix4.identity()
      ..translate(cx, cy)
      ..rotateZ(angle);
    return path.transform(matrix.storage);
  }

  Path _createRect(double x, double y, double w, double h, double r) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(r),
      ));
  }

  void _paintMuscleZone(Canvas canvas, String muscle, List<Path> paths) {
    final intensity = intensityMap[muscle] ?? 0;
    if (intensity <= 0) return;

    final color = _BodyHeatmapState.intensityColor(intensity);
    final isSelected = selectedMuscle == muscle;

    for (final path in paths) {
      // Layer 1: Wide outer glow (very diffuse, soft edge)
      final outerGlow = Paint()
        ..color = color.withValues(alpha: (0.08 + intensity * 0.12) * glowValue)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 + intensity * 12);
      canvas.drawPath(path, outerGlow);

      // Layer 2: Medium glow
      final midGlow = Paint()
        ..color = color.withValues(alpha: (0.12 + intensity * 0.18) * glowValue)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + intensity * 6);
      canvas.drawPath(path, midGlow);

      // Layer 3: Inner core (slightly sharper but still soft)
      final innerFill = Paint()
        ..color = color.withValues(alpha: (0.15 + intensity * 0.25) * glowValue)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + intensity * 3);
      canvas.drawPath(path, innerFill);

      // Layer 4: Stroke glow halo (soft edge outline)
      final haloStroke = Paint()
        ..color = color.withValues(alpha: (0.10 + intensity * 0.15) * glowValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 + intensity * 8
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + intensity * 10);
      canvas.drawPath(path, haloStroke);

      // Bright edge for selected muscle
      if (isSelected) {
        final selectPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5 * glowValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawPath(path, selectPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MuscleOverlayPainter old) =>
      old.glowValue != glowValue ||
      old.selectedMuscle != selectedMuscle ||
      old.showFront != showFront;
}

// ═══════════════════════════════════════════════════════════
//  Glow aura painter — ambient glow around hot muscles
// ═══════════════════════════════════════════════════════════

class _GlowAuraPainter extends CustomPainter {
  final Map<String, double> intensityMap;
  final double glowValue;
  final bool showFront;

  _GlowAuraPainter({
    required this.intensityMap,
    required this.glowValue,
    required this.showFront,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Same image rect calculation as _MuscleOverlayPainter
    final imgH = size.width; // square image
    final offsetY = (size.height - imgH) / 2;

    // Draw large, soft glow for the hottest muscle
    String? hottest;
    double maxIntensity = 0;
    for (final e in intensityMap.entries) {
      if (e.value > maxIntensity) {
        maxIntensity = e.value;
        hottest = e.key;
      }
    }

    if (hottest == null || maxIntensity < 0.4) return;

    final color = _BodyHeatmapState.intensityColor(maxIntensity);

    // Determine center of the hottest muscle (image-relative)
    Offset center;
    if (showFront) {
      center = switch (hottest) {
        'Грудь' => Offset(cx, offsetY + 0.35 * imgH),
        'Пресс' => Offset(cx, offsetY + 0.49 * imgH),
        'Плечи' => Offset(cx, offsetY + 0.28 * imgH),
        'Бицепс' => Offset(cx, offsetY + 0.38 * imgH),
        'Ноги' => Offset(cx, offsetY + 0.70 * imgH),
        _ => Offset(cx, offsetY + 0.45 * imgH),
      };
    } else {
      center = switch (hottest) {
        'Спина' => Offset(cx, offsetY + 0.40 * imgH),
        'Плечи' => Offset(cx, offsetY + 0.28 * imgH),
        'Трицепс' => Offset(cx, offsetY + 0.38 * imgH),
        'Ноги' => Offset(cx, offsetY + 0.70 * imgH),
        _ => Offset(cx, offsetY + 0.45 * imgH),
      };
    }

    // Large soft glow
    final glowRadius = 60 + maxIntensity * 40;
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        glowRadius,
        [
          color.withValues(alpha: 0.15 * glowValue),
          color.withValues(alpha: 0.05 * glowValue),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(center, glowRadius, glowPaint);

    // Ambient body glow (edge light)
    final edgePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx - size.width * 0.3, 0),
        Offset(cx + size.width * 0.3, 0),
        [
          Colors.transparent,
          color.withValues(alpha: 0.05 * glowValue),
          color.withValues(alpha: 0.08 * glowValue),
          color.withValues(alpha: 0.05 * glowValue),
          Colors.transparent,
        ],
        [0.0, 0.2, 0.5, 0.8, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0.1 * size.height, size.width, 0.8 * size.height),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowAuraPainter old) =>
      old.glowValue != glowValue || old.showFront != showFront;
}
