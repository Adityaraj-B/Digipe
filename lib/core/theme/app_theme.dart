import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Centralized theme definitions for light and dark modes.
/// Both themes share the same brand color palette; only surfaces and
/// background values differ between them.
class AppTheme {
  AppTheme._();

  // ── Brand ─────────────────────────────────────────────────────────────
  static const _seed = AppColors.sunOrange;

  // ── Page-transition builder reused in both themes ─────────────────────
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  // ══════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: const Color(0xFFF9FAFB),
      onSurface: const Color(0xFF0D0D0D),
      surfaceContainerHighest: Colors.white,
      surfaceContainerLow: const Color(0xFFF3F4F6),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE5E7EB),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF131313),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _seed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        hintStyle: const TextStyle(color: Color(0xFFB0B7C3)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D0D0D),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1C1C1E),
        contentTextStyle: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFFB0B7C3);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF0D0D0D);
          return const Color(0xFFE5E7EB);
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    const bg = Color(0xFF0D0D0D);
    const card = Color(0xFF1C1C1E);
    const border = Color(0xFF2A2A2A);

    final cs = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      surface: bg,
      onSurface: Colors.white,
      surfaceContainerHighest: card,
      surfaceContainerLow: const Color(0xFF161618),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: border,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF131313),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _seed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
        hintStyle: const TextStyle(color: Color(0xFF636366)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2C2C2E),
        contentTextStyle: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.black;
          return const Color(0xFF636366);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.sunOrange;
          return const Color(0xFF3A3A3C);
        }),
      ),
    );
  }
}
