import 'package:flutter/material.dart';

class AppColors {
  // Earth & Crown palette
  static const Color primary = Color(0xFF513224);
  static const Color primarySoft = Color(0xFF765341);
  static const Color secondary = Color(0xFFE8DBC5);
  static const Color accent = Color(0xFFD4A63B);
  static const Color accentSoft = Color(0xFFE8C573);
  static const Color spiritualGreen = Color(0xFF446B51);
  static const Color spiritualGreenLight = Color(0xFF6D8F77);

  // Light mode
  static const Color background = Color(0xFFF6EFE4);
  static const Color surface = Color(0xFFFBF7F0);
  static const Color card = Color(0xFFFFFBF5);
  static const Color foreground = Color(0xFF352217);
  static const Color muted = Color(0xFFF0E6D8);
  static const Color mutedForeground = Color(0xFF7D6658);
  static const Color border = Color(0xFFD8C7B1);

  // Dark mode
  static const Color darkBackground = Color(0xFF16100D);
  static const Color darkSurface = Color(0xFF211812);
  static const Color darkCard = Color(0xFF2A1F19);
  static const Color darkForeground = Color(0xFFF0E2CC);
  static const Color darkMuted = Color(0xFF2E241D);
  static const Color darkMutedForeground = Color(0xFFC8B49A);
  static const Color darkBorder = Color(0xFF433329);
  static const Color darkPrimary = Color(0xFFD1A64A);
  static const Color darkAccent = Color(0xFFB98C31);

  static const Color deepForest = Color(0xFF1D2116);
  static const Color success = Color(0xFF4E8A62);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFD39C35);
  static const Color info = Color(0xFF7E6A3E);

  static Color textPrimary(bool isDark) => isDark ? darkForeground : foreground;
  static Color textSecondary(bool isDark) =>
      isDark ? darkMutedForeground : mutedForeground;
  static Color borderColor(bool isDark) => isDark ? darkBorder : border;
  static Color surfaceColor(bool isDark) => isDark ? darkCard : card;
  static Color surfaceVariant(bool isDark) => isDark ? darkSurface : surface;
  static Color accentForeground(bool isDark) => isDark ? darkBackground : foreground;
  static Color appBarForeground(bool isDark) => isDark ? darkForeground : primary;
  static Color panelColor(bool isDark) =>
      isDark ? const Color(0xE62A1F19) : const Color(0xE6FFF9F0);
  static Color subtleFill(bool isDark) =>
      isDark ? Colors.white.withAlpha(18) : primary.withAlpha(12);

  static LinearGradient screenGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [darkBackground, deepForest, darkSurface]
          : const [background, secondary, surface],
    );
  }

  static LinearGradient heroGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [darkSurface, primary, deepForest]
          : const [primary, spiritualGreen, accent],
    );
  }
}
