import 'package:flutter/material.dart';

class AppShadows {
  static List<BoxShadow> card({required bool isDark}) {
    return [
      BoxShadow(
        color: Colors.black.withAlpha(isDark ? 64 : 16),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> lift({required bool isDark}) {
    return [
      BoxShadow(
        color: Colors.black.withAlpha(isDark ? 80 : 22),
        blurRadius: 30,
        offset: const Offset(0, 18),
      ),
    ];
  }
}

