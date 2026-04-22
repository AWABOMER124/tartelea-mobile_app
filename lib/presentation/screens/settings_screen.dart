import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/common_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);

    void setThemeMode(ThemeMode mode) {
      ref.read(themeProvider.notifier).state = mode;
      ref.read(sharedPreferencesProvider).setInt('theme_mode', mode.index);
    }

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'الإعدادات',
        showNotifications: false,
        showThemeToggle: false,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: ListView(
          padding: AppSpacing.page,
          children: [
            AppCard(
              usePanelColor: true,
              borderRadius: AppRadius.panel,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) =>
                        setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
                    secondary: _LeadingIcon(
                      icon: Icons.dark_mode_outlined,
                      color: AppColors.appBarForeground(isDark),
                    ),
                    title: Text(
                      'الوضع الداكن',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary(isDark),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    subtitle: Text(
                      'تغيير مظهر التطبيق',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary(isDark),
                          ),
                    ),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'إعدادات الإشعارات',
                    subtitle: 'التحكم بالتنبيهات داخل التطبيق',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('قريباً')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppCard(
              usePanelColor: true,
              borderRadius: AppRadius.panel,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    title: 'تسجيل الخروج',
                    subtitle: 'إنهاء الجلسة الحالية',
                    destructive: true,
                    onTap: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      ref.invalidate(authTokenProvider);
                      ref.invalidate(profileProvider);
                      ref.invalidate(userProfileProvider);
                      if (context.mounted) {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leadingColor =
        destructive ? Colors.redAccent : AppColors.appBarForeground(isDark);

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: 2),
      leading: _LeadingIcon(icon: icon, color: leadingColor),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color:
                  destructive ? Colors.redAccent : AppColors.textPrimary(isDark),
              fontWeight: FontWeight.w800,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary(isDark),
            ),
      ),
      trailing: Icon(
        Icons.chevron_left_rounded,
        size: 18,
        color: AppColors.textSecondary(isDark),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LeadingIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.subtleFill(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Icon(icon, color: color),
    );
  }
}

