import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/theme_provider.dart';

class CustomBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderColor(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 36 : 18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: isDark ? AppColors.darkPrimary : AppColors.primary,
        unselectedItemColor: AppColors.textSecondary(isDark),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books_rounded),
            label: 'المكتبة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: 'المجتمع',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_external_on_outlined),
            activeIcon: Icon(Icons.mic_external_on_rounded),
            label: 'الغرف الصوتية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
