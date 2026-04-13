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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemeColors.light.surfaceBg,
        labelStyle: TextStyle(color: AppThemeColors.light.textHint),
        hintStyle: TextStyle(color: AppThemeColors.light.textHint),
        prefixIconColor: AppColors.primary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppThemeColors.light.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800,
          letterSpacing: -0.5, color: AppThemeColors.light.textPrimary,
          decoration: TextDecoration.none,
        ),
        headlineMedium: TextStyle(
          fontSize: 26, fontWeight: FontWeight.bold,
          color: AppThemeColors.light.textPrimary,
          decoration: TextDecoration.none,
        ),
        titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700,
          letterSpacing: 0.5, color: AppThemeColors.light.textPrimary,
          decoration: TextDecoration.none,
        ),
        titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppThemeColors.light.textPrimary,
          decoration: TextDecoration.none,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppThemeColors.light.textPrimary, decoration: TextDecoration.none),
        bodyMedium: TextStyle(fontSize: 14, color: AppThemeColors.light.textSecondary, decoration: TextDecoration.none),
        labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 1.0, color: AppThemeColors.light.textHint,
          decoration: TextDecoration.none,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemeColors.dark.surfaceBg.withValues(alpha: 0.7),
        labelStyle: TextStyle(color: AppThemeColors.dark.textHint),
        hintStyle: TextStyle(color: AppThemeColors.dark.textHint),
        prefixIconColor: AppColors.primary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppThemeColors.dark.borderLight.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800,
          letterSpacing: -0.5, color: AppThemeColors.dark.textPrimary,
          decoration: TextDecoration.none,
        ),
        headlineMedium: TextStyle(
          fontSize: 26, fontWeight: FontWeight.bold,
          color: AppThemeColors.dark.textPrimary,
          decoration: TextDecoration.none,
        ),
        titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700,
          letterSpacing: 0.5, color: AppThemeColors.dark.textPrimary,
          decoration: TextDecoration.none,
        ),
        titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppThemeColors.dark.textPrimary,
          decoration: TextDecoration.none,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppThemeColors.dark.textPrimary, decoration: TextDecoration.none),
        bodyMedium: TextStyle(fontSize: 14, color: AppThemeColors.dark.textSecondary, decoration: TextDecoration.none),
        labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 1.0, color: AppThemeColors.dark.textHint,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
