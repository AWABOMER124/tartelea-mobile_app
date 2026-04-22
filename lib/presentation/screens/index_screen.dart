import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/content_library_models.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/app_states.dart';
import '../widgets/app_section_header.dart';
import '../widgets/featured_content_section.dart';
import '../widgets/promo_banner.dart';
import 'library_category_screen.dart';
import 'library_track_screen.dart';

class IndexScreen extends ConsumerStatefulWidget {
  final void Function(int index)? onTabSelected;

  const IndexScreen({
    super.key,
    this.onTabSelected,
  });

  @override
  ConsumerState<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends ConsumerState<IndexScreen> {
  final _scrollController = ScrollController();
  final _categoriesAnchorKey = GlobalKey();
  String? _tracksCategorySlug;

  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<List<ContentCategoryModel>>>(
      contentCategoriesProvider,
      (previous, next) {
        if (_tracksCategorySlug != null) return;
        next.whenData((categories) {
          if (!mounted) return;
          if (_tracksCategorySlug != null) return;
          if (categories.isEmpty) return;
          setState(() => _tracksCategorySlug = _preferredTracksCategorySlug(categories));
        });
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = ref.watch(userProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    final featuredAsync = ref.watch(contentFeaturedProvider);
    final categoriesAsync = ref.watch(contentCategoriesProvider);

    Future<void> onRefresh() async {
      ref.invalidate(contentFeaturedProvider);
      ref.invalidate(contentCategoriesProvider);
      if (_tracksCategorySlug != null) {
        ref.invalidate(contentTracksProvider(_tracksCategorySlug));
      }
      await Future.wait([
        ref.read(contentFeaturedProvider.future),
        ref.read(contentCategoriesProvider.future),
      ]);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _HomeAppBar(
                title: 'المدرسة الترتيلية',
                onToggleTheme: ref.toggleTheme,
                showNotificationsDot: unreadNotifications > 0,
                onOpenNotifications: () {
                  if (user == null) {
                    context.push('/auth');
                    return;
                  }
                  context.push('/notifications');
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.page,
                  child: Column(
                    children: [
                      _HeroCard(
                        onPrimaryCta: () => _openTab(1),
                        onSecondaryCta: _scrollToCategories,
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      featuredAsync.when(
                        data: (featured) => featured == null
                            ? const SizedBox.shrink()
                            : FeaturedContentSection(featured: featured),
                        loading: () => const AppSkeletonCard(height: 190),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      const PromoBanner(),
                      const SizedBox(height: AppSpacing.s24),
                      AppCard(
                        key: _categoriesAnchorKey,
                        usePanelColor: true,
                        borderRadius: AppRadius.panel,
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSectionHeader(
                              title: 'استكشف الأقسام',
                              actionLabel: 'الكل',
                              onAction: () => _openTab(1),
                            ),
                            const SizedBox(height: AppSpacing.s12),
                            categoriesAsync.when(
                              data: (categories) {
                                if (categories.isEmpty) {
                                  return const AppInlineBanner(
                                    icon: Icons.menu_book_outlined,
                                    title: 'لا يوجد محتوى بعد',
                                    message:
                                        'سيظهر تقسيم المكتبة هنا بمجرد إعداد المحتوى.',
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 124,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: categories.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: AppSpacing.s12),
                                        itemBuilder: (context, index) {
                                          final category = categories[index];
                                          return _CategoryMiniCard(
                                            category: category,
                                            index: index,
                                            onTap: () => _openCategory(context, category),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.s20),
                                    _TracksSection(
                                      categories: categories,
                                      selectedCategorySlug: _tracksCategorySlug ??
                                          _preferredTracksCategorySlug(categories),
                                      onCategorySelected: (slug) => setState(() {
                                        _tracksCategorySlug = slug;
                                      }),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const _CategoriesRowSkeleton(),
                              error: (err, _) => AppErrorState(
                                title: 'تعذر تحميل الأقسام',
                                message: err.toString(),
                                onRetry: onRefresh,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      _ExploreActions(
                        onOpenLibrary: () => _openTab(1),
                        onOpenWorkshops: () => context.push('/workshops'),
                        onOpenRooms: () => _openTab(3),
                        onOpenPricing: () => context.push('/pricing'),
                      ),
                      if (user == null) ...[
                        const SizedBox(height: AppSpacing.s24),
                        _JoinPrompt(
                          onTap: () => context.push('/auth'),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTab(int index) {
    final handler = widget.onTabSelected;
    if (handler != null) {
      handler(index);
      return;
    }
  }

  void _scrollToCategories() {
    final context = _categoriesAnchorKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  static String _preferredTracksCategorySlug(
    List<ContentCategoryModel> categories,
  ) {
    final preferred = categories
        .cast<ContentCategoryModel?>()
        .firstWhere((c) => c?.slug == 'tartelea_school', orElse: () => null);
    return preferred?.slug ?? categories.first.slug;
  }

  void _openCategory(BuildContext context, ContentCategoryModel category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LibraryCategoryScreen(category: category),
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenNotifications;
  final bool showNotificationsDot;

  const _HomeAppBar({
    required this.title,
    required this.onToggleTheme,
    required this.onOpenNotifications,
    this.showNotificationsDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary(isDark),
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.appBarForeground(isDark),
                ),
                onPressed: onOpenNotifications,
              ),
              if (showNotificationsDot)
                PositionedDirectional(
                  top: 10,
                  end: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimary : AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.accent)
                              .withAlpha(120),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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
            onPressed: onToggleTheme,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onPrimaryCta;
  final VoidCallback onSecondaryCta;

  const _HeroCard({
    required this.onPrimaryCta,
    required this.onSecondaryCta,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient(isDark),
        borderRadius: AppRadius.panel,
        border: Border.all(
          color: (isDark ? AppColors.darkPrimary : AppColors.accentSoft)
              .withAlpha(110),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 34 : 16),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(18),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withAlpha(110)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'رحلة هادئة نحو فهم اللسان العربي المبين',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'برامج ومسارات ومواد مختارة تساعدك تتقدم خطوة بخطوة—بوضوح وطمأنينة.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha(230),
                ),
          ),
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimaryCta,
              child: const Text('ابدأ الآن'),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSecondaryCta,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withAlpha(120)),
              ),
              child: const Text('استكشف'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesRowSkeleton extends StatelessWidget {
  const _CategoriesRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s12),
        itemBuilder: (_, __) => const SizedBox(
          width: 220,
          child: AppSkeletonCard(height: 124),
        ),
      ),
    );
  }
}

class _CategoryMiniCard extends ConsumerWidget {
  final ContentCategoryModel category;
  final int index;
  final VoidCallback onTap;

  const _CategoryMiniCard({
    required this.category,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

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

    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: AppRadius.card,
              border: Border.all(color: Colors.white.withAlpha(isDark ? 26 : 30)),
            ),
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(isDark ? 18 : 22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        index.isEven
                            ? Icons.school_rounded
                            : Icons.favorite_rounded,
                        color: Colors.white.withAlpha(240),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white.withAlpha(240),
                      size: 26,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  category.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withAlpha(245),
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  category.description?.trim().isNotEmpty == true
                      ? category.description!
                      : 'استكشف المسارات والمحتوى الخاص بهذا القسم.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(225),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TracksSection extends ConsumerWidget {
  final List<ContentCategoryModel> categories;
  final String? selectedCategorySlug;
  final ValueChanged<String> onCategorySelected;

  const _TracksSection({
    required this.categories,
    required this.selectedCategorySlug,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final selectedSlug = selectedCategorySlug;

    if (selectedSlug == null) {
      return const SizedBox.shrink();
    }

    final selectedCategory = categories
        .cast<ContentCategoryModel?>()
        .firstWhere((c) => c?.slug == selectedSlug, orElse: () => null);
    if (selectedCategory == null) return const SizedBox.shrink();

    final tracksAsync = ref.watch(contentTracksProvider(selectedSlug));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المسارات',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary(isDark),
              ),
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.slug == selectedSlug;
              return ChoiceChip(
                label: Text(category.title),
                selected: isSelected,
                onSelected: (_) => onCategorySelected(category.slug),
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary(isDark)
                          : AppColors.textSecondary(isDark),
                      fontWeight: FontWeight.w800,
                    ),
                backgroundColor: AppColors.subtleFill(isDark),
                selectedColor: AppColors.subtleFill(isDark),
                side: BorderSide(
                  color: isSelected
                      ? (isDark ? AppColors.darkPrimary : AppColors.accent)
                          .withAlpha(150)
                      : AppColors.borderColor(isDark),
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.chip,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        tracksAsync.when(
          data: (tracks) {
            if (tracks.isEmpty) {
              return const AppInlineBanner(
                icon: Icons.route_outlined,
                title: 'لا توجد مسارات حالياً',
                message: 'سيظهر هنا تنظيم المسارات بمجرد إضافتها.',
              );
            }

            return SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tracks.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s12),
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return _TrackMiniCard(
                    category: selectedCategory,
                    track: track,
                  );
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s12),
              itemBuilder: (_, __) => const SizedBox(
                width: 220,
                child: AppSkeletonCard(height: 116),
              ),
            ),
          ),
          error: (err, _) => AppErrorState(
            title: 'تعذر تحميل المسارات',
            message: err.toString(),
            onRetry: () => ref.invalidate(contentTracksProvider(selectedSlug)),
          ),
        ),
      ],
    );
  }
}

class _TrackMiniCard extends ConsumerWidget {
  final ContentCategoryModel category;
  final ContentTrackModel track;

  const _TrackMiniCard({
    required this.category,
    required this.track,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return SizedBox(
      width: 220,
      child: AppCard(
        showShadow: true,
        borderRadius: AppRadius.card,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LibraryTrackScreen(
                category: category,
                track: track,
              ),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [AppColors.darkPrimary, AppColors.darkAccent]
                      : const [AppColors.accent, AppColors.spiritualGreenLight],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.route_rounded, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary(isDark),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    track.description?.trim().isNotEmpty == true
                        ? track.description!
                        : 'مسار يساعدك على التقدم خطوة بخطوة.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(isDark),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreActions extends ConsumerWidget {
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenWorkshops;
  final VoidCallback onOpenRooms;
  final VoidCallback onOpenPricing;

  const _ExploreActions({
    required this.onOpenLibrary,
    required this.onOpenWorkshops,
    required this.onOpenRooms,
    required this.onOpenPricing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return AppCard(
      usePanelColor: true,
      borderRadius: AppRadius.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'استكشف المنصة',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary(isDark),
                ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s12,
            children: [
              _QuickActionChip(
                label: 'المكتبة',
                icon: Icons.book_outlined,
                onTap: onOpenLibrary,
              ),
              _QuickActionChip(
                label: 'الورش',
                icon: Icons.video_camera_front_outlined,
                onTap: onOpenWorkshops,
              ),
              _QuickActionChip(
                label: 'الغرف الصوتية',
                icon: Icons.mic_external_on_outlined,
                onTap: onOpenRooms,
              ),
              _QuickActionChip(
                label: 'الاشتراك المميز',
                icon: Icons.stars_outlined,
                onTap: onOpenPricing,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends ConsumerWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return InkWell(
      onTap: onTap,
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
            const SizedBox(width: AppSpacing.s8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinPrompt extends ConsumerWidget {
  final VoidCallback onTap;

  const _JoinPrompt({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return AppCard(
      usePanelColor: true,
      borderRadius: AppRadius.panel,
      child: Column(
        children: [
          Text(
            'انضم إلى المدرسة الترتيلية',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary(isDark),
                ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'سجّل الآن وابدأ رحلتك في تعلّم اللسان العربي المبين.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary(isDark),
                ),
          ),
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              child: const Text('تسجيل الدخول'),
            ),
          ),
        ],
      ),
    );
  }
}
