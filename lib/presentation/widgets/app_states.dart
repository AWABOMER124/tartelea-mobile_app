import 'package:flutter/material.dart';

import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import 'app_card.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = AppColors.textPrimary(isDark);
    final secondary = AppColors.textSecondary(isDark);

    return AppCard(
      usePanelColor: true,
      borderRadius: AppRadius.panel,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.subtleFill(isDark),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: AppColors.appBarForeground(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: foreground,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              color: secondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.s16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.title = 'حدث خطأ',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline_rounded,
      title: title,
      message: message,
      actionLabel: onRetry == null ? null : 'إعادة المحاولة',
      onAction: onRetry,
    );
  }
}

class AppInlineBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const AppInlineBanner({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.subtleFill(isDark),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.appBarForeground(isDark)),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
                if (message != null && message!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    message!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

