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

    return AppBar(
      title: title != null 
          ? Text(
              title!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            )
          : Image.asset(
              'assets/images/logo.png', // Fallback to logo if no title
              height: 40,
              errorBuilder: (context, _, __) => const Text(
                'Tartelea',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
      centerTitle: centerTitle,
      backgroundColor: transparent ? Colors.transparent : null,
      elevation: 0,
      actions: actions,
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : AppColors.primary,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
