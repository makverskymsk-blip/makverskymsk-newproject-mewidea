import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  // ─── Light ───
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppThemeColors.light.scaffoldBg,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Color(0xFFF0F0F5),
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppThemeColors.light.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppThemeColors.light.textPrimary),
        titleTextStyle: TextStyle(
          color: AppThemeColors.light.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppThemeColors.light.dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppThemeColors.light.borderLight),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800,
          letterSpacing: -0.5, color: AppThemeColors.light.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 26, fontWeight: FontWeight.bold,
          color: AppThemeColors.light.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700,
          letterSpacing: 0.5, color: AppThemeColors.light.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppThemeColors.light.textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppThemeColors.light.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: AppThemeColors.light.textSecondary),
        labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 1.0, color: AppThemeColors.light.textHint,
        ),
      ),
    );
  }

  // ─── Dark ───
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppThemeColors.dark.scaffoldBg,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppThemeColors.dark.surfaceBg,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppThemeColors.dark.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppThemeColors.dark.textPrimary),
        titleTextStyle: TextStyle(
          color: AppThemeColors.dark.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppThemeColors.dark.dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppThemeColors.dark.borderLight),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800,
          letterSpacing: -0.5, color: AppThemeColors.dark.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 26, fontWeight: FontWeight.bold,
          color: AppThemeColors.dark.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700,
          letterSpacing: 0.5, color: AppThemeColors.dark.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppThemeColors.dark.textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppThemeColors.dark.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: AppThemeColors.dark.textSecondary),
        labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 1.0, color: AppThemeColors.dark.textHint,
        ),
      ),
    );
  }
}
