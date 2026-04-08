import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/promo_banner.dart';

class IndexScreen extends ConsumerWidget {
  const IndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.deepForest],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                     const SizedBox(height: 80), // For the extended appBar
                     _buildHeroSection(),
                     const SizedBox(height: 24),
                     _buildSanctuaryCards(context),
                     const SizedBox(height: 24),
                     const PromoBanner(),
                     const SizedBox(height: 32),
                     _buildExplorePlatform(context),
                     const SizedBox(height: 32),
                     if (user == null) _buildJoinPrompt(context),
                     const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      title: Text(
        'المدرسة الترتيلية',
        style: GoogleFonts.amiri(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(51),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
              // Note: Make sure logo.jpg exists in assets/images/
              image: const DecorationImage(
                image: AssetImage('assets/images/logo.jpg'),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: AppColors.secondary.withAlpha(127), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'لا تستوحش طريق الوعي لقلة السالكين',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white, 
            fontSize: 18, 
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 40, height: 1, color: AppColors.secondary),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.auto_awesome, size: 16, color: AppColors.secondary),
            ),
            Container(width: 40, height: 1, color: AppColors.secondary),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '﴿ وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا ﴾',
            style: GoogleFonts.amiri(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSanctuaryCards(BuildContext context) {
    final items = [
      {'emoji': '🌱', 'title': 'اخلع', 'desc': 'تنقية المفاهيم', 'color': AppColors.spiritualGreen},
      {'emoji': '📖', 'title': 'تدبر', 'desc': 'تعلّم اللسان', 'color': AppColors.secondary},
      {'emoji': '🌟', 'title': 'رتل', 'desc': 'تطبيق الفهم', 'color': AppColors.primary},
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Card(
            elevation: 0,
            color: Colors.white.withAlpha(25),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withAlpha(51)),
            ),
            child: InkWell(
              onTap: () {
                final category = item['title'] == 'اخلع' ? 'takhliya' : (item['title'] == 'تدبر' ? 'tahliya' : 'tajalli');
                context.go('/library', extra: category);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(item['emoji'] as String, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 8),
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      item['desc'] as String,
                      style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
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

  Widget _buildExplorePlatform(BuildContext context) {
    final navItems = [
      {'label': 'المكتبة', 'icon': Icons.book_outlined, 'color': AppColors.primary, 'path': '/library'},
      {'label': 'الورش', 'icon': Icons.video_camera_front_outlined, 'color': AppColors.secondary, 'path': '/workshops'},
      {'label': 'الغرف الصوتية', 'icon': Icons.mic_external_on_outlined, 'color': AppColors.accent, 'path': '/audio-rooms'},
      {'label': 'الاشتراك المميز', 'icon': Icons.stars, 'color': AppColors.accent, 'path': '/pricing'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'استكشف المنصة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: navItems.map((item) {
            return InkWell(
              onTap: () => context.go(item['path'] as String),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withAlpha(13),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: (item['color'] as Color).withAlpha(51)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item['icon'] as IconData, size: 18, color: item['color'] as Color),
                    const SizedBox(width: 8),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildJoinPrompt(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        children: [
          const Text(
            'انضم إلى المدرسة الترتيلية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'سجّل الآن وابدأ رحلتك في تعلّم اللسان العربي المبين',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/auth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
