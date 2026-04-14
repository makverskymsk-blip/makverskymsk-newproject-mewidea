import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Compact animated icon button for switching ThemeMode.
/// Shows sun ☀️ in light mode, moon 🌙 in dark mode.
/// Outline (contour) style with smooth icon transition.
class ThemeSwitch extends StatefulWidget {
  const ThemeSwitch({super.key});

  @override
  State<ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<ThemeSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final isDark = context.read<ThemeProvider>().isDark;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: isDark ? 1.0 : 0.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    final themeProv = context.read<ThemeProvider>();
    themeProv.toggle();
    if (themeProv.isDark) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    // Sync if changed externally
    if (isDark && _ctrl.value == 0) _ctrl.forward();
    if (!isDark && _ctrl.value == 1) _ctrl.reverse();

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;

          final iconColor = Color.lerp(
            const Color(0xFFFF8C00),
            const Color(0xFF818CF8),
            t,
          )!;

          return SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) {
                  return RotationTransition(
                    turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                    child: ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  key: ValueKey(isDark),
                  size: 18,
                  color: iconColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
