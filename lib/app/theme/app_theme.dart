import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTheme {
  static const Color _seedColor = AppPalette.gold;

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppPalette.gold,
          onPrimary: AppPalette.black,
          secondary: AppPalette.navy,
          onSecondary: AppPalette.white,
          surface: AppPalette.white,
          onSurface: AppPalette.black,
          outline: AppPalette.border,
        );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppPalette.canvas,
      fontFamily: 'Segoe UI',
    );

    return baseTheme.copyWith(
      cardTheme: CardThemeData(
        color: AppPalette.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: AppPalette.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      dividerColor: AppPalette.border,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.gold,
          foregroundColor: AppPalette.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.navy,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: AppPalette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppPalette.gold, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.navy,
        contentTextStyle: baseTheme.textTheme.bodyMedium?.copyWith(
          color: AppPalette.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textTheme: baseTheme.textTheme.copyWith(
        headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppPalette.black,
        ),
        titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppPalette.black,
        ),
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          color: AppPalette.navy,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          color: AppPalette.textMuted,
        ),
        bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
          color: AppPalette.textMuted,
        ),
      ),
    );
  }
}
