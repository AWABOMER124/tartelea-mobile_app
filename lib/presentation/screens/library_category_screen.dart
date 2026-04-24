import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_config.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/content_library_models.dart';
import '../providers/content_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_segmented_tabs.dart';
import '../widgets/app_skeleton.dart';
import 'content_webview_screen.dart';
import 'library_track_screen.dart';
import 'program_detail_screen.dart';

class LibraryCategoryScreen extends ConsumerStatefulWidget {
  final ContentCategoryModel category;

  const LibraryCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<LibraryCategoryScreen> createState() =>
      _LibraryCategoryScreenState();
}

class _LibraryCategoryScreenState extends ConsumerState<LibraryCategoryScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final category = widget.category;
    final tracksAsync = ref.watch(contentTracksProvider(category.slug));
    final programsAsync = ref.watch(
      programsProvider(ProgramsQuery(categorySlug: category.slug)),
    );
    final itemsAsync = ref.watch(
      libraryItemsProvider(LibraryItemsQuery(categorySlug: category.slug)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: ListView(
          padding: AppSpacing.page,
          children: [
            if (category.description?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                child: Text(
                  category.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary(isDark),
                      ),
                ),
              ),
            tracksAsync.when(
              data: (tracks) {
                final validTracks = tracks
                    .where((t) => t.title.trim().isNotEmpty && t.slug.trim().isNotEmpty)
                    .toList();

                if (validTracks.isEmpty) return const SizedBox.shrink();

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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: validTracks.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.s12,
                        crossAxisSpacing: AppSpacing.s12,
                        childAspectRatio: 1.18,
                      ),
                      itemBuilder: (context, index) {
                        final track = validTracks[index];
                        return _TrackCard(
                          track: track,
                          isDark: isDark,
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
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.s20),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            AppSegmentedTabs(
              labels: const ['البرامج', 'المواد'],
              index: _tabIndex,
              onChanged: (value) => setState(() => _tabIndex = value),
            ),
            const SizedBox(height: AppSpacing.s16),
            if (_tabIndex == 0) ...[
              _SectionHeader(title: 'البرامج', isDark: isDark),
              programsAsync.when(
                data: (programs) {
                  if (programs.isEmpty) {
                    return _InlineEmptyState(
                      isDark: isDark,
                      text: 'لا توجد برامج حالياً',
                    );
                  }

                  return Column(
                    children: [
                      for (final program in programs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                          child: _ProgramCard(
                            program: program,
                            isDark: isDark,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProgramDetailScreen(program: program),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const _InlineLoading(),
                error: (err, _) =>
                    _InlineError(isDark: isDark, text: err.toString()),
              ),
            ] else ...[
              _SectionHeader(title: 'المواد', isDark: isDark),
              itemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return _InlineEmptyState(
                      isDark: isDark,
                      text: 'لا توجد مواد حالياً',
                    );
                  }

                  return Column(
                    children: [
                      for (final item in items.take(20))
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                          child: _LibraryItemCard(
                            item: item,
                            isDark: isDark,
                            onTap: () {
                              if (item.isLocked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'هذا المحتوى مقفل ويتطلب صلاحية مناسبة.',
                                    ),
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
                                  const SnackBar(
                                    content: Text(
                                      'لا يوجد رابط متاح لهذا المحتوى حالياً.',
                                    ),
                                  ),
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
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const _InlineLoading(),
                error: (err, _) =>
                    _InlineError(isDark: isDark, text: err.toString()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final ContentTrackModel track;
  final bool isDark;
  final VoidCallback onTap;

  const _TrackCard({
    required this.track,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor(isDark),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderColor(isDark)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 55 : 18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [AppColors.darkPrimary, AppColors.darkAccent]
                        : const [AppColors.accent, AppColors.spiritualGreenLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.route_rounded, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                track.description?.trim().isNotEmpty == true
                    ? track.description!
                    : 'برامج ومصادر داخل هذا المسار',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final ProgramModel program;
  final bool isDark;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.program,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.resolveApiUrl(program.thumbnailPath);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceColor(isDark),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.borderColor(isDark)),
          ),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 92,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.subtleFill(isDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.subtleFill(isDark)),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.subtleFill(isDark)),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              program.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary(isDark),
                              ),
                            ),
                          ),
                          if (program.isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withAlpha(35),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.warning.withAlpha(80),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 14,
                                    color: AppColors.warning,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'مقفل',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        program.description?.trim().isNotEmpty == true
                            ? program.description!
                            : 'دروس ومواد داخل هذا البرنامج',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textSecondary(isDark),
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryItemCard extends StatelessWidget {
  final LibraryItemModel item;
  final bool isDark;
  final VoidCallback onTap;

  const _LibraryItemCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.resolveApiUrl(item.thumbnailPath);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceColor(isDark),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.borderColor(isDark)),
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.subtleFill(isDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.subtleFill(isDark)),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.subtleFill(isDark)),
                      )
                    : Icon(
                        _iconForType(item.contentType),
                        color: AppColors.textSecondary(isDark),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary(isDark),
                              ),
                            ),
                          ),
                          if (item.isLocked)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withAlpha(35),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.warning.withAlpha(80),
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description?.trim().isNotEmpty == true
                            ? item.description!
                            : 'محتوى ${_labelForType(item.contentType)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textSecondary(isDark),
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'audio':
        return Icons.headset_rounded;
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'meditation':
        return Icons.self_improvement_rounded;
      case 'file':
        return Icons.description_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'video':
        return 'مرئي';
      case 'audio':
        return 'صوتي';
      case 'exercise':
        return 'تمارين';
      case 'meditation':
        return 'تأمل';
      case 'file':
        return 'ملفات';
      default:
        return 'مقالات';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary(isDark),
        ),
      ),
    );
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: Column(
        children: [
          AppSkeletonCard(height: 106),
          SizedBox(height: AppSpacing.s12),
          AppSkeletonCard(height: 106),
          SizedBox(height: AppSpacing.s12),
          AppSkeletonCard(height: 106),
        ],
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final bool isDark;
  final String text;

  const _InlineEmptyState({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textSecondary(isDark)),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final bool isDark;
  final String text;

  const _InlineError({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textPrimary(isDark)),
      ),
    );
  }
}
