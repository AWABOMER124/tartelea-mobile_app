import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/content_library_models.dart';
import '../providers/content_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/app_states.dart';
import '../widgets/app_section_header.dart';
import '../widgets/featured_content_section.dart';
import '../widgets/common_app_bar.dart';
import 'library_category_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final String? initialSidebarCategory;

  const LibraryScreen({
    super.key,
    this.initialSidebarCategory,
  });

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _handledInitialCategory = false;

  @override
  Widget build(BuildContext context) {
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
      appBar: const CommonAppBar(title: 'المكتبة'),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          child: ListView(
            padding: AppSpacing.page,
            children: [
              const _LibraryHero(),
              const SizedBox(height: AppSpacing.s16),
              featuredAsync.when(
                data: (featured) => featured == null
                    ? const SizedBox.shrink()
                    : FeaturedContentSection(featured: featured),
                loading: () => const AppSkeletonCard(height: 190),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.s20),
              const AppSectionHeader(title: 'الأقسام'),
              const SizedBox(height: AppSpacing.s12),
              categoriesAsync.when(
                data: (categories) {
                  final validCategories = categories
                      .where(
                        (c) =>
                            c.title.trim().isNotEmpty &&
                            c.slug.trim().isNotEmpty,
                      )
                      .toList();

                  _maybeOpenInitialCategory(context, validCategories);

                  if (validCategories.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'لا يوجد محتوى بعد',
                      message: 'سيظهر هنا تقسيم المحتوى بمجرد إعداد Directus.',
                      actionLabel: 'تحديث',
                      onAction: onRefresh,
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: validCategories.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.s12,
                      crossAxisSpacing: AppSpacing.s12,
                      childAspectRatio: 0.92,
                    ),
                    itemBuilder: (context, index) {
                      final category = validCategories[index];
                      return _CategoryTile(
                        category: category,
                        index: index,
                        onTap: () => _openCategory(context, category),
                      );
                    },
                  );
                },
                loading: () => const _CategoriesSkeleton(),
                error: (err, _) => AppErrorState(
                  title: 'تعذر تحميل الأقسام',
                  message: err.toString(),
                  onRetry: onRefresh,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }

  void _maybeOpenInitialCategory(
    BuildContext context,
    List<ContentCategoryModel> categories,
  ) {
    if (_handledInitialCategory) return;
    final targetSlug = widget.initialSidebarCategory?.trim();
    if (targetSlug == null || targetSlug.isEmpty) return;

    final category = categories
        .cast<ContentCategoryModel?>()
        .firstWhere((c) => c?.slug == targetSlug, orElse: () => null);
    if (category == null) {
      _handledInitialCategory = true;
      return;
    }

    _handledInitialCategory = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openCategory(context, category);
    });
  }

  void _openCategory(BuildContext context, ContentCategoryModel category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LibraryCategoryScreen(category: category),
      ),
    );
  }
}

class _LibraryHero extends ConsumerWidget {
  const _LibraryHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient(isDark),
        borderRadius: AppRadius.panel,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 70 : 26),
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white.withAlpha(245),
                ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'محتوى منظم: مسارات، برامج، ومواد تساعدك تتقدم بهدوء ووضوح.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha(230),
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.s12,
      crossAxisSpacing: AppSpacing.s12,
      childAspectRatio: 0.92,
      children: const [
        AppSkeletonCard(height: 170),
        AppSkeletonCard(height: 170),
        AppSkeletonCard(height: 170),
        AppSkeletonCard(height: 170),
      ],
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final ContentCategoryModel category;
  final int index;
  final VoidCallback onTap;

  const _CategoryTile({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.panel,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: AppRadius.panel,
            border: Border.all(
              color: Colors.white.withAlpha(isDark ? 26 : 30),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(isDark ? 18 : 22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  index.isEven ? Icons.school_rounded : Icons.favorite_rounded,
                  color: Colors.white.withAlpha(240),
                ),
              ),
              const Spacer(),
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
    );
  }
}
