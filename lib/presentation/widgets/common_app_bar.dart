import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';

class CommonAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool transparent;
  final bool showNotifications;
  final bool showThemeToggle;

  const CommonAppBar({
    super.key,
    this.title,
    this.actions,
    this.centerTitle = true,
    this.transparent = true,
    this.showNotifications = true,
    this.showThemeToggle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final foreground = AppColors.appBarForeground(isDark);
    final user = ref.watch(userProvider);
    final unreadCount = showNotifications
        ? ref.watch(unreadNotificationsCountProvider)
        : 0;

    final resolvedActions = <Widget>[
      ...(actions ?? const []),
      if (showNotifications)
        _AppBarAction(
          icon: Icons.notifications_none_rounded,
          showDot: unreadCount > 0,
          foreground: foreground,
          isDark: isDark,
          onTap: () {
            if (user == null) {
              context.push('/auth');
              return;
            }
            context.push('/notifications');
          },
        ),
      if (showThemeToggle)
        _AppBarAction(
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          foreground: foreground,
          isDark: isDark,
          onTap: ref.toggleTheme,
        ),
    ];

    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: foreground,
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.panelColor(isDark),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderColor(isDark)),
              ),
              child: Image.asset(
                'assets/images/logo.jpeg',
                height: 34,
                fit: BoxFit.contain,
                errorBuilder: (context, _, __) => Text(
                  'Tartelea',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
              ),
            ),
      centerTitle: centerTitle,
      backgroundColor: transparent ? Colors.transparent : null,
      elevation: 0,
      actions: resolvedActions.isEmpty ? null : resolvedActions,
      iconTheme: IconThemeData(
        color: foreground,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final Color foreground;
  final bool isDark;
  final VoidCallback onTap;

  const _AppBarAction({
    required this.icon,
    required this.foreground,
    required this.isDark,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.darkPrimary : AppColors.accent;

    return Container(
      margin: const EdgeInsetsDirectional.only(end: 12),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(icon, color: foreground),
            onPressed: onTap,
          ),
          if (showDot)
            PositionedDirectional(
              top: 10,
              end: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withAlpha(120),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
