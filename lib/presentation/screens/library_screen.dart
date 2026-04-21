import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/content_library_models.dart';
import '../providers/content_provider.dart';
import '../providers/theme_provider.dart';
import 'content_webview_screen.dart';
import 'library_category_screen.dart';

class LibraryScreen extends ConsumerWidget {
  final String? initialSidebarCategory;

  const LibraryScreen({super.key, this.initialSidebarCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final categoriesAsync = ref.watch(contentCategoriesProvider);
    final featuredAsync = ref.watch(contentFeaturedProvider);

    Future<void> onRefresh() async {
      ref.invalidate(contentCategoriesProvider);
      ref.invalidate(contentFeaturedProvider);
      await Future.wait([
        ref.read(contentCategoriesProvider.future),
        ref.read(contentFeaturedProvider.future),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة'),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              _HeroCard(isDark: isDark),
              const SizedBox(height: 14),
              featuredAsync.when(
                data: (featured) => featured == null
                    ? const SizedBox.shrink()
                    : _FeaturedSection(
                        featured: featured,
                        isDark: isDark,
                      ),
                loading: () => _LoadingPanel(isDark: isDark, height: 164),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              Text(
                'الأقسام',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 10),
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return _EmptyState(
                      isDark: isDark,
                      title: 'لا يوجد محتوى بعد',
                      subtitle: 'سيظهر هنا تقسيم المحتوى بمجرد إعداد Directus.',
                    );
                  }

                  return Column(
                    children: [
                      for (var i = 0; i < categories.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CategoryCard(
                            category: categories[i],
                            isDark: isDark,
                            index: i,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LibraryCategoryScreen(
                                    category: categories[i],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
                loading: () => Column(
                  children: [
                    _LoadingPanel(isDark: isDark, height: 112),
                    const SizedBox(height: 12),
                    _LoadingPanel(isDark: isDark, height: 112),
                  ],
                ),
                error: (err, _) => _EmptyState(
                  isDark: isDark,
                  title: 'تعذر تحميل الأقسام',
                  subtitle: err.toString(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isDark;

  const _HeroCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient(isDark),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 70 : 30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المكتبة الترتيلية',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white.withAlpha(240),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'رحلة محتوى منظمة: مسارات، برامج، ومصادر تساعدك تتقدم خطوة بخطوة.',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Colors.white.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  final ContentFeaturedResponse featured;
  final bool isDark;

  const _FeaturedSection({
    required this.featured,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanners = featured.banners.isNotEmpty;
    final hasPrograms = featured.featuredPrograms.isNotEmpty;
    final hasItems = featured.featuredLibraryItems.isNotEmpty;

    if (!hasBanners && !hasPrograms && !hasItems) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'محتوى مميز',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 10),
          if (hasBanners) _BannersCarousel(banners: featured.banners, isDark: isDark),
          if (hasPrograms) ...[
            const SizedBox(height: 12),
            _HorizontalProgramsRow(programs: featured.featuredPrograms, isDark: isDark),
          ],
          if (hasItems) ...[
            const SizedBox(height: 12),
            _HorizontalItemsRow(items: featured.featuredLibraryItems, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _BannersCarousel extends StatefulWidget {
  final List<FeaturedBannerModel> banners;
  final bool isDark;

  const _BannersCarousel({required this.banners, required this.isDark});

  @override
  State<_BannersCarousel> createState() => _BannersCarouselState();
}

class _BannersCarouselState extends State<_BannersCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final imageUrl = ApiConfig.resolveApiUrl(banner.imagePath);

              return GestureDetector(
                onTap: banner.link == null || banner.link!.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ContentWebViewScreen(
                              title: banner.title,
                              url: banner.link!,
                            ),
                          ),
                        );
                      },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderColor(widget.isDark)),
                    color: AppColors.surfaceColor(widget.isDark),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 180),
                          placeholder: (_, __) => Container(
                            color: AppColors.subtleFill(widget.isDark),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.subtleFill(widget.isDark),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.auto_awesome,
                              color: AppColors.textSecondary(widget.isDark),
                            ),
                          ),
                        )
                      else
                        Container(color: AppColors.subtleFill(widget.isDark)),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(150),
                              ],
                            ),
                          ),
                          child: Text(
                            banner.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.banners.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? (widget.isDark ? AppColors.darkPrimary : AppColors.accent)
                        : AppColors.borderColor(widget.isDark),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HorizontalProgramsRow extends StatelessWidget {
  final List<ProgramModel> programs;
  final bool isDark;

  const _HorizontalProgramsRow({required this.programs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'برامج مختارة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: programs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _ProgramMiniCard(program: programs[index], isDark: isDark);
            },
          ),
        ),
      ],
    );
  }
}

class _HorizontalItemsRow extends StatelessWidget {
  final List<LibraryItemModel> items;
  final bool isDark;

  const _HorizontalItemsRow({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مواد مختارة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _LibraryItemMiniCard(item: items[index], isDark: isDark);
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ContentCategoryModel category;
  final bool isDark;
  final int index;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = index.isEven
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF2A1F19), Color(0xFF211812)]
                : const [AppColors.primary, AppColors.spiritualGreen],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF1D2116), Color(0xFF211812)]
                : const [AppColors.spiritualGreen, AppColors.accent],
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withAlpha(isDark ? 26 : 30)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(isDark ? 18 : 22),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  index.isEven ? Icons.school_rounded : Icons.favorite_rounded,
                  color: Colors.white.withAlpha(240),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withAlpha(245),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.description?.trim().isNotEmpty == true
                          ? category.description!
                          : 'استكشف المسارات والمحتوى الخاص بهذا القسم.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_left_rounded,
                color: Colors.white.withAlpha(240),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramMiniCard extends StatelessWidget {
  final ProgramModel program;
  final bool isDark;

  const _ProgramMiniCard({required this.program, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.resolveApiUrl(program.thumbnailPath);

    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.subtleFill(isDark)),
              errorWidget: (_, __, ___) => Container(color: AppColors.subtleFill(isDark)),
            )
          else
            Container(color: AppColors.subtleFill(isDark)),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(160),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      program.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (program.isLocked)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withAlpha(60)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'مقفل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryItemMiniCard extends StatelessWidget {
  final LibraryItemModel item;
  final bool isDark;

  const _LibraryItemMiniCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.resolveApiUrl(item.thumbnailPath);

    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.subtleFill(isDark)),
              errorWidget: (_, __, ___) => Container(color: AppColors.subtleFill(isDark)),
            )
          else
            Container(color: AppColors.subtleFill(isDark)),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(160),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (item.isLocked)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withAlpha(60)),
                      ),
                      child: const Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  final bool isDark;
  final double height;

  const _LoadingPanel({required this.isDark, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: isDark ? AppColors.darkPrimary : AppColors.primary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

