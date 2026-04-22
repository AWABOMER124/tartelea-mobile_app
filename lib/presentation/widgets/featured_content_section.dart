import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_config.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/content_library_models.dart';
import '../screens/content_webview_screen.dart';
import '../screens/program_detail_screen.dart';
import 'app_card.dart';

class FeaturedContentSection extends StatelessWidget {
  final ContentFeaturedResponse featured;
  final String title;

  const FeaturedContentSection({
    super.key,
    required this.featured,
    this.title = 'محتوى مميز',
  });

  @override
  Widget build(BuildContext context) {
    final hasBanners = featured.banners.isNotEmpty;
    final hasPrograms = featured.featuredPrograms.isNotEmpty;
    final hasItems = featured.featuredLibraryItems.isNotEmpty;

    if (!hasBanners && !hasPrograms && !hasItems) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      usePanelColor: true,
      borderRadius: AppRadius.panel,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary(isDark),
                ),
          ),
          if (hasBanners) ...[
            const SizedBox(height: AppSpacing.s12),
            _BannersCarousel(banners: featured.banners),
          ],
          if (hasPrograms) ...[
            const SizedBox(height: AppSpacing.s16),
            _HorizontalProgramsRow(programs: featured.featuredPrograms),
          ],
          if (hasItems) ...[
            const SizedBox(height: AppSpacing.s16),
            _HorizontalItemsRow(items: featured.featuredLibraryItems),
          ],
        ],
      ),
    );
  }
}

class _BannersCarousel extends StatefulWidget {
  final List<FeaturedBannerModel> banners;

  const _BannersCarousel({required this.banners});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final imageUrl = ApiConfig.resolveApiUrl(banner.imagePath);
              final hasLink = banner.link != null && banner.link!.trim().isNotEmpty;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: hasLink
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ContentWebViewScreen(
                                  title: banner.title,
                                  url: banner.link!,
                                ),
                              ),
                            );
                          }
                        : null,
                    borderRadius: AppRadius.card,
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.card,
                        border: Border.all(color: AppColors.borderColor(isDark)),
                        color: AppColors.surfaceColor(isDark),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.card,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (imageUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                fadeInDuration:
                                    const Duration(milliseconds: 180),
                                placeholder: (_, __) => Container(
                                  color: AppColors.subtleFill(isDark),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.subtleFill(isDark),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                ),
                              )
                            else
                              Container(color: AppColors.subtleFill(isDark)),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                                        banner.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (hasLink) ...[
                                      const SizedBox(width: 10),
                                      Icon(
                                        Icons.open_in_new_rounded,
                                        size: 18,
                                        color: Colors.white.withAlpha(220),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: AppSpacing.s8),
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
                        ? (isDark ? AppColors.darkPrimary : AppColors.accent)
                        : AppColors.borderColor(isDark),
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

  const _HorizontalProgramsRow({required this.programs});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'برامج مختارة',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: programs.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s12),
            itemBuilder: (context, index) {
              final program = programs[index];
              return _ProgramMiniCard(program: program);
            },
          ),
        ),
      ],
    );
  }
}

class _HorizontalItemsRow extends StatelessWidget {
  final List<LibraryItemModel> items;

  const _HorizontalItemsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مواد مختارة',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _LibraryItemMiniCard(item: item);
            },
          ),
        ),
      ],
    );
  }
}

class _ProgramMiniCard extends StatelessWidget {
  final ProgramModel program;

  const _ProgramMiniCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = ApiConfig.resolveApiUrl(program.thumbnailPath);

    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProgramDetailScreen(program: program),
              ),
            );
          },
          borderRadius: AppRadius.card,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderColor(isDark)),
              color: AppColors.surfaceColor(isDark),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.card,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.subtleFill(isDark)),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.subtleFill(isDark)),
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
                            Colors.black.withAlpha(165),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(170),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withAlpha(60),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryItemMiniCard extends StatelessWidget {
  final LibraryItemModel item;

  const _LibraryItemMiniCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = ApiConfig.resolveApiUrl(item.thumbnailPath);

    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (item.isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('هذا المحتوى مقفل ويتطلب صلاحية مناسبة.'),
                ),
              );
              return;
            }

            final url = (item.fileUrl?.isNotEmpty == true)
                ? item.fileUrl!
                : (item.mediaUrl?.isNotEmpty == true)
                    ? item.mediaUrl!
                    : '';

            if (url.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لا يوجد رابط متاح لهذا المحتوى حالياً.')),
              );
              return;
            }

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContentWebViewScreen(
                  title: item.title,
                  url: url,
                ),
              ),
            );
          },
          borderRadius: AppRadius.card,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderColor(isDark)),
              color: AppColors.surfaceColor(isDark),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.card,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.subtleFill(isDark)),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.subtleFill(isDark)),
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
                            Colors.black.withAlpha(165),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(170),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withAlpha(60),
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

