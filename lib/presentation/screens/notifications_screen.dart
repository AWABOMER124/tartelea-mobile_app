import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/app_states.dart';
import '../widgets/common_app_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(notificationsListProvider);

    Future<void> onRefresh() async {
      ref.invalidate(notificationsListProvider);
      await ref.read(notificationsListProvider.future);
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: 'الإشعارات',
        showNotifications: false,
        actions: [
          async.maybeWhen(
            data: (items) => items.any((item) => !item.isRead)
                ? IconButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(notificationsRepositoryProvider)
                            .markAllRead();
                        ref.invalidate(notificationsListProvider);
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
                    icon: const Icon(Icons.done_all_rounded),
                    tooltip: 'تحديد الكل كمقروء',
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          child: async.when(
            data: (items) {
              if (items.isEmpty) {
                return ListView(
                  padding: AppSpacing.page,
                  children: const [
                    AppEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'لا توجد إشعارات بعد',
                      message:
                          'عندما تبدأ جلسة جديدة أو يتم تحديث اشتراكك ستظهر هنا إشعاراتك.',
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: AppSpacing.page,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _NotificationTile(
                    notification: item,
                    onTap: () async {
                      if (!item.isRead) {
                        try {
                          await ref
                              .read(notificationsRepositoryProvider)
                              .markRead(item.id);
                          ref.invalidate(notificationsListProvider);
                        } catch (_) {
                          // Ignore mark-read failures for UX; still allow open.
                        }
                      }
                    },
                  );
                },
              );
            },
            loading: () => ListView.builder(
              padding: AppSpacing.page,
              itemCount: 6,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.s12),
                child: AppSkeletonCard(height: 92),
              ),
            ),
            error: (error, _) => ListView(
              padding: AppSpacing.page,
              children: [
                AppErrorState(
                  title: 'تعذر تحميل الإشعارات',
                  message: error.toString().replaceFirst('Exception: ', ''),
                  onRetry: () => ref.invalidate(notificationsListProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.accent;
    final createdAt = notification.createdAt.toLocal();
    final timeLabel = DateFormat('dd MMM • HH:mm').format(createdAt);

    return AppCard(
      usePanelColor: true,
      borderRadius: AppRadius.panel,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.subtleFill(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor(isDark)),
            ),
            child: Icon(
              _iconFor(notification.type),
              color: AppColors.appBarForeground(isDark),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary(isDark),
                              fontWeight: notification.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                            ),
                      ),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(width: AppSpacing.s8),
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(top: 4),
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
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  notification.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(isDark),
                      ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  timeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary(isDark),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    return switch (type) {
      NotificationType.room => Icons.mic_external_on_rounded,
      NotificationType.like => Icons.favorite_rounded,
      NotificationType.comment => Icons.chat_bubble_outline_rounded,
      NotificationType.system => Icons.notifications_rounded,
    };
  }
}

