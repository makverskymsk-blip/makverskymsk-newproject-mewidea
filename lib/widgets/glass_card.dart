import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppColors.of(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.cardBg,
            t.isDark
                ? t.cardBg.withValues(alpha: 0.93)
                : t.surfaceBg.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: t.borderLight.withValues(alpha: 0.5)),
        boxShadow: [
          // Primary soft shadow
          BoxShadow(
            color: t.isDark
                ? Colors.black.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
          // Tight ambient shadow
          BoxShadow(
            color: t.isDark
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
