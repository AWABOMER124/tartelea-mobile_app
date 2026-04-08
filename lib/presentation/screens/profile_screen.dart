import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import 'auth_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    if (user == null) {
      return const AuthScreen();
    }

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppColors.appBarForeground(isDark),
            ),
            onPressed: ref.toggleTheme,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(isDark),
        ),
        child: profileAsync.when(
          data: (profile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: Column(
                children: [
                  _buildProfileHeader(profile, isDark),
                  const SizedBox(height: 18),
                  _buildProfileStats(isDark),
                  const SizedBox(height: 24),
                  _buildMenuSection(context, ref, isDark),
                ],
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              'خطأ: $err',
              style: TextStyle(color: AppColors.textPrimary(isDark)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic profile, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkPrimary : AppColors.accent,
                width: 2.2,
              ),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.subtleFill(isDark),
              backgroundImage:
                  (profile?.avatarUrl != null) ? NetworkImage(profile!.avatarUrl!) : null,
              child: (profile?.avatarUrl == null)
                  ? Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: AppColors.appBarForeground(isDark),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile?.fullName ?? 'مستخدم ترتيل',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.subtleFill(isDark),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'عضوية ترتيلية',
              style: TextStyle(
                color: AppColors.appBarForeground(isDark),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if ((profile?.email ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              profile.email,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileStats(bool isDark) {
    return Row(
      children: [
        Expanded(child: _StatsCard(label: 'المسارات', value: '3', isDark: isDark)),
        const SizedBox(width: 10),
        Expanded(child: _StatsCard(label: 'المنشورات', value: '12', isDark: isDark)),
        const SizedBox(width: 10),
        Expanded(child: _StatsCard(label: 'البراعة', value: '450', isDark: isDark)),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        children: [
          _MenuItem(icon: Icons.bookmark_outline, label: 'المفضلة', isDark: isDark, onTap: () {}),
          _MenuItem(icon: Icons.history_edu_outlined, label: 'سجل التعلم', isDark: isDark, onTap: () {}),
          _MenuItem(
            icon: Icons.stars_outlined,
            label: 'ترتيلة بريميوم',
            isDark: isDark,
            color: isDark ? AppColors.darkPrimary : AppColors.accent,
            onTap: () => context.push('/pricing'),
          ),
          _MenuItem(icon: Icons.payment_outlined, label: 'سجل الاشتراكات', isDark: isDark, onTap: () {}),
          _MenuItem(icon: Icons.help_outline, label: 'مركز المساعدة', isDark: isDark, onTap: () {}),
          const Divider(height: 24),
          _MenuItem(
            icon: Icons.logout_rounded,
            label: 'تسجيل الخروج',
            isDark: isDark,
            color: Colors.redAccent,
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              ref.invalidate(authTokenProvider);
              ref.invalidate(profileProvider);
              ref.invalidate(userProfileProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatsCard({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.appBarForeground(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary(isDark);

    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        label,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w700),
      ),
      trailing: Icon(
        Icons.chevron_left_rounded,
        size: 20,
        color: AppColors.textSecondary(isDark),
      ),
      onTap: onTap,
    );
  }
}
