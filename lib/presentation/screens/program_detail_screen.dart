import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/content_library_models.dart';
import '../providers/content_provider.dart';
import '../providers/theme_provider.dart';
import 'content_webview_screen.dart';

class ProgramDetailScreen extends ConsumerWidget {
  final ProgramModel program;

  const ProgramDetailScreen({
    super.key,
    required this.program,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final lessonsAsync = ref.watch(programLessonsProvider(program.id));
    final imageUrl = ApiConfig.resolveApiUrl(program.thumbnailPath);

    return Scaffold(
      appBar: AppBar(
        title: Text(program.title),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient(isDark)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceColor(isDark),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.borderColor(isDark)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl.isNotEmpty)
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.subtleFill(isDark)),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.subtleFill(isDark)),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                program.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary(isDark),
                                ),
                              ),
                            ),
                            if (program.isLocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
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
                        if (program.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 10),
                          Text(
                            program.description!,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.7,
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                        ],
                        if (program.isLocked) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlpha(18),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.warning.withAlpha(70),
                              ),
                            ),
                            child: Text(
                              'هذا البرنامج يتطلب صلاحية (اشتراك) للوصول إلى المحتوى الكامل.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: AppColors.textPrimary(isDark),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'الدروس',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 10),
            lessonsAsync.when(
              data: (lessons) {
                if (lessons.isEmpty) {
                  return _InlineEmptyState(isDark: isDark, text: 'لا توجد دروس حالياً');
                }

                return Column(
                  children: [
                    for (final lesson in lessons)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LessonCard(
                          lesson: lesson,
                          isDark: isDark,
                          onTap: () {
                            if (lesson.isLocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('هذا الدرس مقفل ويتطلب صلاحية مناسبة.'),
                                ),
                              );
                              return;
                            }

                            final url = (lesson.fileUrl?.isNotEmpty == true)
                                ? lesson.fileUrl!
                                : (lesson.mediaUrl?.isNotEmpty == true)
                                    ? lesson.mediaUrl!
                                    : '';

                            if (url.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('لا يوجد رابط متاح لهذا الدرس حالياً.'),
                                ),
                              );
                              return;
                            }

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ContentWebViewScreen(
                                  title: lesson.title,
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
              loading: () => _InlineLoading(isDark: isDark),
              error: (err, _) => _InlineError(isDark: isDark, text: err.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final ProgramLessonModel lesson;
  final bool isDark;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.subtleFill(isDark),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconForType(lesson.lessonType),
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    if (lesson.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        lesson.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (lesson.isLocked)
                const Icon(Icons.lock_rounded, color: AppColors.warning)
              else
                Icon(Icons.play_arrow_rounded, color: AppColors.textSecondary(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'audio':
        return Icons.headset_rounded;
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'file':
        return Icons.description_outlined;
      default:
        return Icons.article_outlined;
    }
  }
}

class _InlineLoading extends StatelessWidget {
  final bool isDark;

  const _InlineLoading({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
        ),
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
