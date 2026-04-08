import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_provider.dart';

// Using StateProvider for simplicity and maximum compatibility
final themeProvider = StateProvider<ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final themeIndex = prefs.getInt('theme_mode');
  if (themeIndex != null) {
    return ThemeMode.values[themeIndex];
  }
  return ThemeMode.system;
});

extension ThemeToggle on WidgetRef {
  void toggleTheme() {
    final current = read(themeProvider);
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    read(themeProvider.notifier).state = next;
    read(sharedPreferencesProvider).setInt('theme_mode', next.index);
  }
}
