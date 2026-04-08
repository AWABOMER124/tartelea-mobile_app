import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        secondary: AppColors.accent,
        onSecondary: AppColors.foreground,
        surface: AppColors.surface,
        onSurface: AppColors.foreground,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
    );

    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
      headlineMedium: GoogleFonts.amiri(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
      titleLarge: GoogleFonts.amiri(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.foreground,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        color: AppColors.foreground,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        color: AppColors.mutedForeground,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.mutedForeground),
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: GoogleFonts.cairo(
          color: AppColors.surface,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkBackground,
        secondary: AppColors.accentSoft,
        onSecondary: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkForeground,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      dividerColor: AppColors.darkBorder,
    );

    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
      headlineMedium: GoogleFonts.amiri(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.darkForeground,
      ),
      titleLarge: GoogleFonts.amiri(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.darkForeground,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.darkForeground,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        color: AppColors.darkForeground,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        color: AppColors.darkMutedForeground,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkForeground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        labelStyle: const TextStyle(color: AppColors.darkMutedForeground),
        hintStyle: const TextStyle(color: AppColors.darkMutedForeground),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkForeground,
          side: const BorderSide(color: AppColors.darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkCard,
        contentTextStyle: GoogleFonts.cairo(
          color: AppColors.darkForeground,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkMutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
