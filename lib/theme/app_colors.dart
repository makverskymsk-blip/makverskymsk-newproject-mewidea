import 'package:flutter/material.dart';

/// Static accent / utility colors that stay the same in both themes.
class AppColors {
  // Accent — fixed
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFFB800);
  static const Color primaryDark = Color(0xFFE85D2C);
  static const Color accent = Color(0xFF00D4AA);

  // Utility — fixed
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA000);

  // Gradients — fixed
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFFB800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFF1612C), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Theme-dependent: accessed via AppColors.of(context) ───

  // Legacy statics (light) — kept for backward compatibility
  static const Color backgroundDark = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFF8F8FA);
  static const Color surface = Color(0xFFF0F0F5);
  static const Color glassWhite = Color(0x08000000);
  static const Color glassBorder = Color(0x1A000000);
  static const Color glassHighlight = Color(0x0A000000);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color border = Color(0xFF222222);
  static const Color borderLight = Color(0xFFDDDDDD);

  /// Get theme-aware colors from context
  static AppThemeColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? AppThemeColors.dark
        : AppThemeColors.light;
  }
}

/// Theme-dependent color set, used via [AppColors.of(context)]
class AppThemeColors {
  final Color scaffoldBg;
  final Color cardBg;
  final Color surfaceBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color borderColor;
  final Color borderLight;
  final Color glassBg;
  final Color glassBorder;
  final Color dialogBg;
  final Color navBarBg;
  final Color shadowColor;
  final Color chipBg;
  final Brightness brightness;

  const AppThemeColors({
    required this.scaffoldBg,
    required this.cardBg,
    required this.surfaceBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.borderColor,
    required this.borderLight,
    required this.glassBg,
    required this.glassBorder,
    required this.dialogBg,
    required this.navBarBg,
    required this.shadowColor,
    required this.chipBg,
    required this.brightness,
  });

  bool get isDark => brightness == Brightness.dark;

  static const AppThemeColors light = AppThemeColors(
    scaffoldBg: Color(0xFFF4F4F7),
    cardBg: Color(0xFFFFFFFF),
    surfaceBg: Color(0xFFF8F8FA),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF666666),
    textHint: Color(0xFF999999),
    borderColor: Color(0xFF222222),
    borderLight: Color(0xFFE0E0E5),
    glassBg: Color(0x08000000),
    glassBorder: Color(0x1A000000),
    dialogBg: Color(0xFFFFFFFF),
    navBarBg: Color(0xFFFFFFFF),
    shadowColor: Color(0x12000000),
    chipBg: Color(0xFFF0F0F5),
    brightness: Brightness.light,
  );

  static const AppThemeColors dark = AppThemeColors(
    scaffoldBg: Color(0xFF09090B),
    cardBg: Color(0xFF1C1C22),
    surfaceBg: Color(0xFF121216),
    textPrimary: Color(0xFFF0F0F0),
    textSecondary: Color(0xFFAAAAAA),
    textHint: Color(0xFF666666),
    borderColor: Color(0xFF38383F),
    borderLight: Color(0xFF2E2E36),
    glassBg: Color(0x15FFFFFF),
    glassBorder: Color(0x20FFFFFF),
    dialogBg: Color(0xFF1E1E24),
    navBarBg: Color(0xFF111114),
    shadowColor: Color(0x40000000),
    chipBg: Color(0xFF242430),
    brightness: Brightness.dark,
  );
}
