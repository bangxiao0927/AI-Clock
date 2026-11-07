import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Colour tokens shared by every screen.
abstract final class AppColors {
  // Surfaces and text.
  static const background = Color(0xFF0E1116);
  static const surface = Color(0xFF161A21);
  static const surfaceHigh = Color(0xFF1F242D);
  static const outline = Color(0xFF2A303B);
  static const textPrimary = Color(0xFFECEFF4);
  static const textMuted = Color(0xFF9AA3B2);

  // Brand (logo gradient and spark).
  static const brandStart = Color(0xFF4F7CFF);
  static const brandEnd = Color(0xFF8B5CF6);
  static const spark = Color(0xFFFFC857);

  // One restrained accent per feature area.
  static const clockAccent = Color(0xFF5B8DEF);
  static const dayAccent = Color(0xFFF5B14C);
  static const notesAccent = Color(0xFF4FD1A5);
}

/// The single app theme (dark).
abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.brandStart,
      secondary: AppColors.brandEnd,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.outline,
    );

    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final textTheme = base.textTheme
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      // Android: fade-forward. iOS: native slide with swipe-back.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
            backgroundColor: AppColors.background,
          ),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
