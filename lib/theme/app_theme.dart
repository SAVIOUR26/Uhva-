import 'package:flutter/material.dart';

class UhvaColors {
  static const primary = Color(0xFF6C63FF);
  static const primaryDark = Color(0xFF4B44CC);
  static const primaryLight = Color(0xFF9D97FF);

  static const background = Color(0xFF07071A);
  static const surface = Color(0xFF0E0E24);
  static const surfaceAlt = Color(0xFF13132E);
  static const card = Color(0xFF181832);

  static const onBackground = Color(0xFFE8E8F0);
  static const onSurface = Color(0xFFCCCCDD);
  static const onSurfaceMuted = Color(0xFF888899);
  static const onSurfaceHint = Color(0xFF555566);

  static const liveRed = Color(0xFFE53935);
  static const epgNow = Color(0xFF2A2550);
  static const focusBorder = primary;

  static const divider = Color(0xFF1E1E3A);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: UhvaColors.background,
        colorScheme: const ColorScheme.dark(
          primary: UhvaColors.primary,
          secondary: UhvaColors.primaryLight,
          surface: UhvaColors.surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: UhvaColors.onSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: UhvaColors.surface,
          foregroundColor: UhvaColors.onBackground,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: UhvaColors.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        cardTheme: CardTheme(
          color: UhvaColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.zero,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: UhvaColors.onBackground, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: UhvaColors.onBackground, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: UhvaColors.onBackground, fontWeight: FontWeight.w600, fontSize: 16),
          titleMedium: TextStyle(color: UhvaColors.onBackground, fontWeight: FontWeight.w500, fontSize: 14),
          titleSmall: TextStyle(color: UhvaColors.onSurface, fontWeight: FontWeight.w500, fontSize: 12),
          bodyLarge: TextStyle(color: UhvaColors.onSurface, fontSize: 14),
          bodyMedium: TextStyle(color: UhvaColors.onSurfaceMuted, fontSize: 13),
          bodySmall: TextStyle(color: UhvaColors.onSurfaceHint, fontSize: 11),
          labelSmall: TextStyle(color: UhvaColors.onSurfaceHint, fontSize: 10, letterSpacing: 0.5),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: UhvaColors.surfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: UhvaColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: UhvaColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: UhvaColors.primary, width: 1.5),
          ),
          hintStyle: const TextStyle(color: UhvaColors.onSurfaceHint),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: UhvaColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: UhvaColors.divider,
          thickness: 0.5,
          space: 0,
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Colors.transparent,
          selectedTileColor: Color(0x2A6C63FF),
          iconColor: UhvaColors.onSurfaceMuted,
          textColor: UhvaColors.onSurface,
        ),
      );
}
