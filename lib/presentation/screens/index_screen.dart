import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/promo_banner.dart';

class IndexScreen extends ConsumerWidget {
  const IndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(isDark),
        ),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(isDark, ref),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                child: Column(
                  children: [
                    _buildHeroSection(isDark),
                    const SizedBox(height: 22),
                    _buildSanctuaryCards(context, isDark),
                    const SizedBox(height: 22),
                    const PromoBanner(),
                    const SizedBox(height: 28),
                    _buildExplorePlatform(context, isDark),
                    const SizedBox(height: 28),
                    if (user == null) _buildJoinPrompt(context, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, WidgetRef ref) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      title: Text(
        'المدرسة الترتيلية',
        style: GoogleFonts.amiri(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary(isDark),
          fontSize: 28,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsetsDirectional.only(end: 12),
          decoration: BoxDecoration(
            color: AppColors.panelColor(isDark),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderColor(isDark)),
          ),
          child: IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppColors.appBarForeground(isDark),
            ),
            onPressed: ref.toggleTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient(isDark),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: (isDark ? AppColors.darkPrimary : AppColors.accentSoft).withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 34 : 18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 128,
            height: 128,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(20),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withAlpha(110)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/images/logo.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'لا تستوحش طريق الوعي لقلة السالكين',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 42, height: 1.2, color: Colors.white.withAlpha(170)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              ),
              Container(width: 42, height: 1.2, color: Colors.white.withAlpha(170)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withAlpha(70)),
            ),
            child: Text(
              '﴿ وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا ﴾',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                color: Colors.white,
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSanctuaryCards(BuildContext context, bool isDark) {
    final items = [
      {'emoji': '🌱', 'title': 'اخلع', 'desc': 'تنقية المفاهيم'},
      {'emoji': '📖', 'title': 'تدبر', 'desc': 'تعلّم اللسان'},
      {'emoji': '🌟', 'title': 'رتل', 'desc': 'تطبيق الفهم'},
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.panelColor(isDark),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderColor(isDark)),
            ),
            child: InkWell(
              onTap: () {
                final category = item['title'] == 'اخلع'
                    ? 'takhliya'
                    : (item['title'] == 'تدبر' ? 'tahliya' : 'tajalli');
                context.go('/library', extra: category);
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                child: Column(
                  children: [
                    Text(item['emoji']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 8),
                    Text(
                      item['title']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['desc']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExplorePlatform(BuildContext context, bool isDark) {
    final List<Map<String, dynamic>> navItems = [
      {'label': 'المكتبة', 'icon': Icons.book_outlined, 'path': '/library'},
      {'label': 'الورش', 'icon': Icons.video_camera_front_outlined, 'path': '/workshops'},
      {'label': 'الغرف الصوتية', 'icon': Icons.mic_external_on_outlined, 'path': '/audio-rooms'},
      {'label': 'الاشتراك المميز', 'icon': Icons.stars_outlined, 'path': '/pricing'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'استكشف المنصة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: navItems.map((item) {
              final path = item['path'] as String;
              final label = item['label'] as String;
              final icon = item['icon'] as IconData;

              return InkWell(
                onTap: () => context.go(path),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.subtleFill(isDark),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.borderColor(isDark)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: AppColors.appBarForeground(isDark),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinPrompt(BuildContext context, bool isDark) {
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
          Text(
            'انضم إلى المدرسة الترتيلية',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'سجّل الآن وابدأ رحلتك في تعلّم اللسان العربي المبين',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/auth'),
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}
