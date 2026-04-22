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
import 'program_detail_screen.dart';

class LibraryTrackScreen extends ConsumerStatefulWidget {
  final ContentCategoryModel category;
  final ContentTrackModel track;

  const LibraryTrackScreen({
    super.key,
    required this.category,
    required this.track,
  });

  @override
  ConsumerState<LibraryTrackScreen> createState() => _LibraryTrackScreenState();
}

class _LibraryTrackScreenState extends ConsumerState<LibraryTrackScreen> {
  String? _selectedContentType;
  int _tabIndex = 0;

  final List<Map<String, String?>> _contentTypeFilters = const [
    {'label': 'الكل', 'value': null},
    {'label': 'مقالات', 'value': 'article'},
    {'label': 'صوتي', 'value': 'audio'},
    {'label': 'مرئي', 'value': 'video'},
    {'label': 'تمارين', 'value': 'exercise'},
    {'label': 'تأمل', 'value': 'meditation'},
    {'label': 'ملفات', 'value': 'file'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    final programsAsync = ref.watch(
      programsProvider(
        ProgramsQuery(
          categorySlug: widget.category.slug,
          trackSlug: widget.track.slug,
        ),
      ),
    );
    final itemsAsync = ref.watch(
      libraryItemsProvider(
        LibraryItemsQuery(
          categorySlug: widget.category.slug,
          trackSlug: widget.track.slug,
          contentType: _selectedContentType,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.track.title),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: ListView(
          padding: AppSpacing.page,
          children: [
            _TrackHero(
              isDark: isDark,
              categoryTitle: widget.category.title,
              trackTitle: widget.track.title,
              description: widget.track.description,
            ),
            const SizedBox(height: AppSpacing.s16),
            _TypeFilterRow(
              isDark: isDark,
              options: _contentTypeFilters,
              selectedValue: _selectedContentType,
              onChanged: (value) => setState(() => _selectedContentType = value),
            ),
            const SizedBox(height: AppSpacing.s16),
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
                      text: 'لا توجد برامج في هذا المسار',
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
                      text: _selectedContentType == null
                          ? 'لا توجد مواد في هذا المسار'
                          : 'لا توجد مواد من هذا النوع حالياً',
                    );
                  }

                  return Column(
                    children: [
                      for (final item in items)
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

class _TrackHero extends StatelessWidget {
  final bool isDark;
  final String categoryTitle;
  final String trackTitle;
  final String? description;

  const _TrackHero({
    required this.isDark,
    required this.categoryTitle,
    required this.trackTitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryTitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trackTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          if (description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              description!,
              style: TextStyle(
                fontSize: 13,
                height: 1.65,
                color: AppColors.textSecondary(isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeFilterRow extends StatelessWidget {
  final bool isDark;
  final List<Map<String, String?>> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const _TypeFilterRow({
    required this.isDark,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final label = options[index]['label'] ?? '';
          final value = options[index]['value'];
          final selected = value == selectedValue;

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onChanged(value),
            selectedColor: isDark ? AppColors.darkPrimary : AppColors.accent,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected
                  ? AppColors.accentForeground(isDark)
                  : AppColors.textPrimary(isDark),
            ),
            backgroundColor: AppColors.surfaceColor(isDark),
            shape: StadiumBorder(
              side: BorderSide(color: AppColors.borderColor(isDark)),
            ),
          );
        },
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
