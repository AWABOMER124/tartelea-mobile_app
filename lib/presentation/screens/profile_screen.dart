import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import 'auth_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    
    if (user == null) {
      return const AuthScreen();
    }

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الملف الشخصي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.deepForest],
          ),
        ),
        child: profileAsync.when(
          data: (profile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 100, 0, 0),
              child: Column(
                children: [
                  _buildProfileHeader(profile),
                  const SizedBox(height: 24),
                  _buildProfileStats(),
                  const SizedBox(height: 32),
                  _buildMenuSection(context, ref),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (err, stack) => Center(child: Text('خطأ: $err', style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(51))),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withAlpha(51),
                  backgroundImage: (profile?.avatarUrl != null) ? NetworkImage(profile!.avatarUrl!) : null,
                  child: (profile?.avatarUrl == null) ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile?.fullName ?? 'مستخدم ترتيل',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withAlpha(127)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: AppColors.accent, size: 14),
                SizedBox(width: 4),
                Text('عضوية ترتيلية', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatsItem(label: 'المسارات', value: '3'),
          _StatsItem(label: 'المنشورات', value: '12'),
          _StatsItem(label: 'البراعة', value: '450'),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _MenuItem(icon: Icons.bookmark_outline, label: 'المفضلة', onTap: () {}),
          _MenuItem(icon: Icons.history_edu_outlined, label: 'سجل التعلم', onTap: () {}),
          _MenuItem(
            icon: Icons.stars_outlined, 
            label: 'ترتيلة بريميوم', 
            onTap: () => context.push('/pricing'),
            color: AppColors.accent,
          ),
          _MenuItem(icon: Icons.payment_outlined, label: 'سجل الاشتراكات', onTap: () {}),
          _MenuItem(icon: Icons.help_outline, label: 'مركز المساعدة', onTap: () {}),
          const SizedBox(height: 16),
          _MenuItem(
            icon: Icons.logout,
            label: 'تسجيل الخروج',
            color: Colors.redAccent,
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}

class _StatsItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatsItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(label, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_left, size: 20, color: Colors.white54),
      onTap: onTap,
    );
  }
}
