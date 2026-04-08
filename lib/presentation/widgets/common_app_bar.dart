import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';

class CommonAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool transparent;

  const CommonAppBar({
    super.key,
    this.title,
    this.actions,
    this.centerTitle = true,
    this.transparent = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final foreground = AppColors.appBarForeground(isDark);

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
      actions: actions,
      iconTheme: IconThemeData(
        color: foreground,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
