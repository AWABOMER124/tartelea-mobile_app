import 'package:flutter/material.dart';

import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool usePanelColor;
  final bool showBorder;
  final bool showShadow;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
    this.borderRadius = AppRadius.card,
    this.usePanelColor = false,
    this.showBorder = true,
    this.showShadow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = usePanelColor
        ? AppColors.panelColor(isDark)
        : AppColors.surfaceColor(isDark);

    final decoration = BoxDecoration(
      color: background,
      borderRadius: borderRadius,
      border: showBorder ? Border.all(color: AppColors.borderColor(isDark)) : null,
      boxShadow: showShadow ? AppShadows.card(isDark: isDark) : null,
    );

    if (onTap == null) {
      return Container(
        decoration: decoration,
        padding: padding,
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: decoration,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
