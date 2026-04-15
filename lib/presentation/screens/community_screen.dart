import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/theme_provider.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final postsAsync = ref.watch(postsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المجتمع التفاعلي'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_comment_outlined,
              color: AppColors.appBarForeground(isDark),
            ),
            onPressed: () => _showCreatePostSheet(context, ref, isDark),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(isDark),
        ),
        child: postsAsync.when(
          data: (posts) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              _buildCreatePostBox(context, ref, isDark),
              const SizedBox(height: 18),
              if (posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'لا يوجد منشورات حالياً',
                      style: TextStyle(color: AppColors.textSecondary(isDark)),
                    ),
                  ),
                )
              else
                ...posts.map((post) => _PostCard(post: post, isDark: isDark)),
            ],
          ),
          loading: () => Center(
            child: CircularProgressIndicator(
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              'خطأ: $err',
              style: TextStyle(color: AppColors.textPrimary(isDark)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostBox(BuildContext context, WidgetRef ref, bool isDark) {
    return InkWell(
      onTap: () => _showCreatePostSheet(context, ref, isDark),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.panelColor(isDark),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderColor(isDark)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.subtleFill(isDark),
              child: Icon(
                Icons.person_rounded,
                color: AppColors.appBarForeground(isDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.subtleFill(isDark),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ماذا يدور في ذهنك؟',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreatePostSheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) async {
    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجل الدخول أولاً لإنشاء منشور.')),
      );
      context.go('/auth');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    String title = '';
    String body = '';
    String category = 'general';
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (title.trim().length < 5) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('عنوان المنشور يجب أن يكون 5 أحرف على الأقل.')),
                );
                return;
              }

              if (body.trim().length < 10) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('محتوى المنشور يجب أن يكون 10 أحرف على الأقل.')),
                );
                return;
              }

              setSheetState(() => isSubmitting = true);

              try {
                final post = await ref.read(postRepositoryProvider).createPost(
                      title: title.trim(),
                      body: body.trim(),
                      category: category,
                    );

                if (post == null) {
                  throw Exception('تعذر إنشاء المنشور.');
                }

                ref.invalidate(postsProvider(null));
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                messenger.showSnackBar(
                  const SnackBar(content: Text('تم إنشاء المنشور بنجاح.')),
                );
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text(_errorMessage(error))),
                );
              } finally {
                if (sheetContext.mounted) {
                  setSheetState(() => isSubmitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.panelColor(isDark),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.borderColor(isDark)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إنشاء منشور جديد',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      enabled: !isSubmitting,
                      onChanged: (value) => title = value,
                      decoration: const InputDecoration(
                        labelText: 'عنوان المنشور',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('عام')),
                        DropdownMenuItem(value: 'quran', child: Text('قرآن')),
                        DropdownMenuItem(value: 'awareness', child: Text('توعية')),
                        DropdownMenuItem(value: 'sudan_awareness', child: Text('السودان')),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setSheetState(() => category = value);
                              }
                            },
                      decoration: const InputDecoration(
                        labelText: 'التصنيف',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !isSubmitting,
                      minLines: 4,
                      maxLines: 6,
                      onChanged: (value) => body = value,
                      decoration: const InputDecoration(
                        labelText: 'محتوى المنشور',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : submit,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('نشر المنشور'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] ?? data['error']?['message'] ?? 'تعذر إنشاء المنشور.')
            .toString();
      }
      return error.message ?? 'تعذر إنشاء المنشور.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _PostCard extends StatelessWidget {
  final dynamic post;
  final bool isDark;

  const _PostCard({
    required this.post,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.subtleFill(isDark),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.appBarForeground(isDark),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (post.authorName ?? '').toString().trim().isEmpty
                        ? 'مستخدم ترتيل'
                        : post.authorName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(post.createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary(isDark),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.subtleFill(isDark),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.category,
                  style: TextStyle(
                    color: AppColors.appBarForeground(isDark),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          if (post.body != null) ...[
            const SizedBox(height: 8),
            Text(
              post.body!,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _ActionButton(
                icon: Icons.thumb_up_alt_outlined,
                label: 'أعجبني',
                color: AppColors.textSecondary(isDark),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ميزة التفاعل ستتفعّل في التحديث القادم.'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'تعليق',
                color: AppColors.textSecondary(isDark),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ميزة التعليقات من التطبيق ستتفعّل قريبًا.'),
                    ),
                  );
                },
              ),
              const Spacer(),
              Icon(
                Icons.share_outlined,
                size: 18,
                color: AppColors.textSecondary(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
