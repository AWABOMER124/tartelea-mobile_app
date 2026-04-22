import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_config.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/content_library_models.dart';
import '../../data/models/profile_model.dart';
import '../../data/models/subscription_contract.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_stats_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/app_states.dart';
import '../widgets/common_app_bar.dart';
import 'auth_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const AuthScreen();
    }

    final profileAsync = ref.watch(userProfileProvider);
    final subscriptionAsync = ref.watch(subscriptionContractProvider);
    final sessionsCountAsync = ref.watch(sessionsAttendedCountProvider);
    final tracksAsync = ref.watch(contentTracksProvider(null));

    Future<void> onRefresh() async {
      ref.invalidate(profileProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(subscriptionContractProvider);
      ref.invalidate(sessionsAttendedCountProvider);
      ref.invalidate(contentTracksProvider(null));
      await Future.wait([
        ref.read(userProfileProvider.future),
        ref.read(sessionsAttendedCountProvider.future),
        ref.read(contentTracksProvider(null).future),
      ]);
    }

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'الملف الشخصي',
        showThemeToggle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          child: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return ListView(
                  padding: AppSpacing.page,
                  children: [
                    AppErrorState(
                      title: 'تعذر تحميل الملف',
                      message: 'لم نتمكن من تحميل بيانات الحساب حالياً.',
                      onRetry: () => ref.invalidate(userProfileProvider),
                    ),
                  ],
                );
              }

              return ListView(
                padding: AppSpacing.page,
                children: [
                  _ProfileHeader(
                    profile: profile,
                    subscriptionAsync: subscriptionAsync,
                    onEdit: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _ProfileStatsRow(
                    sessionsCountAsync: sessionsCountAsync,
                    tracksAsync: tracksAsync,
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  _ProfileActionsPanel(
                    onEditProfile: () => context.push('/profile/edit'),
                    onOpenNotifications: () => context.push('/notifications'),
                    onOpenSettings: () => context.push('/settings'),
                    onOpenSubscription: ApiConfig.subscriptionsPaused
                        ? null
                        : () => context.push('/pricing'),
                    onLogout: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      ref.invalidate(authTokenProvider);
                      ref.invalidate(profileProvider);
                      ref.invalidate(userProfileProvider);
                      ref.invalidate(subscriptionContractProvider);
                    },
                  ),
                ],
              );
            },
            loading: () => ListView(
              padding: AppSpacing.page,
              children: const [
                AppSkeletonCard(height: 160),
                SizedBox(height: AppSpacing.s16),
                Row(
                  children: [
                    Expanded(child: AppSkeletonCard(height: 78)),
                    SizedBox(width: AppSpacing.s12),
                    Expanded(child: AppSkeletonCard(height: 78)),
                    SizedBox(width: AppSpacing.s12),
                    Expanded(child: AppSkeletonCard(height: 78)),
                  ],
                ),
                SizedBox(height: AppSpacing.s24),
                AppSkeletonCard(height: 280),
              ],
            ),
            error: (err, _) => ListView(
              padding: AppSpacing.page,
              children: [
                AppErrorState(
                  title: 'تعذر تحميل الملف',
                  message: err.toString().replaceFirst('Exception: ', ''),
                  onRetry: () => ref.invalidate(userProfileProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final AsyncValue<SubscriptionContract?> subscriptionAsync;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.profile,
    required this.subscriptionAsync,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = (profile.fullName ?? '').trim().isEmpty
        ? 'مستخدم ترتيلة'
        : profile.fullName!.trim();

    return AppCard(
      usePanelColor: true,
      borderRadius: AppRadius.panel,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkPrimary : AppColors.accent,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.subtleFill(isDark),
                backgroundImage:
                    (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                    ? Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: AppColors.appBarForeground(isDark),
                      )
                    : null,
              ),
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
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary(isDark),
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    _PlanBadge(async: subscriptionAsync),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(isDark),
                      ),
                ),
                if ((profile.bio ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    profile.bio!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(isDark),
                        ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s12),
                SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل الملف'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final AsyncValue<SubscriptionContract?> async;

  const _PlanBadge({required this.async});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.accent;

    return async.when(
      data: (contract) {
        final effective = contract;
        final isPremium =
            effective != null && effective.isActive && !effective.isFreePlan;
        final label = isPremium ? 'بريميوم' : 'مجاني';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isPremium
                ? accent.withAlpha(30)
                : AppColors.subtleFill(isDark),
            borderRadius: AppRadius.chip,
            border: Border.all(
              color: isPremium
                  ? accent.withAlpha(120)
                  : AppColors.borderColor(isDark),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isPremium ? accent : AppColors.appBarForeground(isDark),
                  fontWeight: FontWeight.w900,
                ),
          ),
        );
      },
      loading: () => const AppSkeletonBox(
        height: 26,
        width: 72,
        borderRadius: AppRadius.chip,
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.subtleFill(isDark),
          borderRadius: AppRadius.chip,
          border: Border.all(color: AppColors.borderColor(isDark)),
        ),
        child: Text(
          '—',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary(isDark),
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  final AsyncValue<int> sessionsCountAsync;
  final AsyncValue<List<ContentTrackModel>> tracksAsync;

  const _ProfileStatsRow({
    required this.sessionsCountAsync,
    required this.tracksAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'الجلسات',
            value: sessionsCountAsync.when(
              data: (value) => value.toString(),
              loading: () => null,
              error: (_, __) => '—',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: _StatCard(
            label: 'المسارات',
            value: tracksAsync.when(
              data: (items) => items.length.toString(),
              loading: () => null,
              error: (_, __) => '—',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        const Expanded(
          child: _StatCard(
            label: 'المحفوظات',
            value: '0',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String? value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      usePanelColor: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
      borderRadius: AppRadius.card,
      child: Column(
        children: [
          if (value == null)
            const AppSkeletonBox(height: 22, width: 44)
          else
            Text(
              value!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary(isDark),
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionsPanel extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback? onOpenSubscription;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onLogout;

  const _ProfileActionsPanel({
    required this.onEditProfile,
    required this.onOpenSubscription,
    required this.onOpenNotifications,
    required this.onOpenSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.accent;

    return AppCard(
      usePanelColor: true,
      borderRadius: AppRadius.panel,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.edit_outlined,
            title: 'تعديل الملف الشخصي',
            subtitle: 'الاسم، الصورة، كلمة المرور',
            onTap: onEditProfile,
          ),
          if (onOpenSubscription != null) ...[
            const Divider(height: 1),
            _ActionTile(
              icon: Icons.workspace_premium_outlined,
              title: 'الاشتراك',
              subtitle: 'إدارة الخطة والفواتير',
              accent: accent,
              onTap: onOpenSubscription!,
            ),
          ],
          const Divider(height: 1),
          _ActionTile(
            icon: Icons.notifications_none_rounded,
            title: 'الإشعارات',
            subtitle: 'آخر التحديثات والتنبيهات',
            onTap: onOpenNotifications,
          ),
          const Divider(height: 1),
          _ActionTile(
            icon: Icons.settings_outlined,
            title: 'الإعدادات',
            subtitle: 'التفضيلات والخصوصية',
            onTap: onOpenSettings,
          ),
          const Divider(height: 1),
          _ActionTile(
            icon: Icons.logout_rounded,
            title: 'تسجيل الخروج',
            subtitle: 'إنهاء الجلسة الحالية',
            destructive: true,
            onTap: () {
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final Color? accent;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = destructive
        ? Colors.redAccent
        : (accent ?? AppColors.appBarForeground(isDark));

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.subtleFill(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor(isDark)),
        ),
        child: Icon(icon, color: baseColor),
      ),
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

