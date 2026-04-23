import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Shimmer/holographic overlay that reacts to device tilt via gyroscope.
/// On web or devices without gyroscope, falls back to auto-animation.
class GyroShimmerOverlay extends StatefulWidget {
  /// Base color for the shimmer highlight (e.g. gold, purple).
  final Color shimmerColor;

  /// Secondary highlight (creates rainbow holo effect).
  final Color? secondaryColor;

  /// Border radius of the parent card.
  final BorderRadius borderRadius;

  /// Intensity of the effect (0.0 - 1.0).
  final double intensity;

  const GyroShimmerOverlay({
    super.key,
    required this.shimmerColor,
    this.secondaryColor,
    required this.borderRadius,
    this.intensity = 0.5,
  });

  @override
  State<GyroShimmerOverlay> createState() => _GyroShimmerOverlayState();
}

class _GyroShimmerOverlayState extends State<GyroShimmerOverlay>
    with SingleTickerProviderStateMixin {
  // Normalized position of the shimmer spotlight (-1..1)
  double _dx = 0.0;
  double _dy = 0.0;

  // For auto-animation fallback
  late AnimationController _autoController;
  StreamSubscription? _gyroSub;
  bool _hasGyro = false;

  @override
  void initState() {
    super.initState();

    // Auto-animation fallback (smooth loop)
    _autoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _autoController.addListener(() {
      if (!_hasGyro && mounted) {
        final t = _autoController.value * 2 * pi;
        setState(() {
          _dx = sin(t) * 0.6;
          _dy = cos(t * 0.7) * 0.4;
        });
      }
    });

    // Try real gyroscope (skip on web)
    if (!kIsWeb) {
      _initGyro();
    }
  }

  void _initGyro() {
    try {
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: const Duration(milliseconds: 50),
      ).listen(
        (event) {
          if (!_hasGyro) {
            _hasGyro = true;
            _autoController.stop();
          }
          if (mounted) {
            setState(() {
              // Accumulate rotation, clamp to [-1, 1]
              // event.y = rotation around Y axis (left-right tilt)
              // event.x = rotation around X axis (forward-back tilt)
              _dx = (_dx + event.y * 0.04).clamp(-1.0, 1.0);
              _dy = (_dy + event.x * 0.04).clamp(-1.0, 1.0);

              // Gentle decay towards center
              _dx *= 0.95;
              _dy *= 0.95;
            });
          }
        },
        onError: (_) {
          // Gyro not available, keep auto-animation
        },
      );
    } catch (_) {
      // sensors not available
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _autoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = widget.intensity;
    final baseColor = widget.shimmerColor;
    final secondary = widget.secondaryColor ?? baseColor.withValues(alpha: 0.3);

    // Position the gradient spotlight based on dx/dy
    final spotX = 0.5 + _dx * 0.5; // 0..1
    final spotY = 0.5 + _dy * 0.5; // 0..1

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main shimmer spotlight
            AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    (spotX * 2 - 1),
                    (spotY * 2 - 1),
                  ),
                  radius: 0.8,
                  colors: [
                    baseColor.withValues(alpha: 0.25 * intensity),
                    baseColor.withValues(alpha: 0.08 * intensity),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Secondary holo streak
            AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.0 + _dx * 2, -1.0 + _dy),
                  end: Alignment(1.0 + _dx * 2, 1.0 + _dy),
                  colors: [
                    Colors.transparent,
                    secondary.withValues(alpha: 0.12 * intensity),
                    baseColor.withValues(alpha: 0.18 * intensity),
                    secondary.withValues(alpha: 0.12 * intensity),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                ),
              ),
            ),

            // Specular highlight dot (small bright point)
            Positioned(
              left: spotX * 200 - 30,
              top: spotY * 80 - 15,
              child: Container(
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(30),
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15 * intensity),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
