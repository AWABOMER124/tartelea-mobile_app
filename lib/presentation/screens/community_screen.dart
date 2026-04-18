import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/community_models.dart';
import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../providers/theme_provider.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String? _selectedContextId;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = ref.watch(userProvider);
    final contextsAsync = ref.watch(communityContextsProvider);
    final contexts = contextsAsync.asData?.value ?? const <CommunityContextModel>[];
    final activeContextId = _resolveActiveContextId(contexts);
    final feedAsync = ref.watch(communityFeedProvider(activeContextId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المجتمع'),
        actions: [
          IconButton(
            onPressed: () => _showCreatePostSheet(
              context: context,
              isDark: isDark,
              contexts: contexts,
              activeContextId: activeContextId,
            ),
            icon: Icon(
              Icons.add_comment_outlined,
              color: AppColors.appBarForeground(isDark),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(isDark),
        ),
        child: Column(
          children: [
            _ContextStrip(
              isDark: isDark,
              contextsAsync: contextsAsync,
              selectedContextId: activeContextId,
              onSelected: (contextId) {
                setState(() {
                  _selectedContextId = contextId;
                });
              },
            ),
            Expanded(
              child: RefreshIndicator(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(communityContextsProvider);
                  ref.invalidate(communityFeedProvider(activeContextId));
                },
                child: feedAsync.when(
                  data: (feed) {
                    final allItems = <Widget>[
                      const SizedBox(height: 12),
                      _CreatePostBox(
                        isDark: isDark,
                        enabled: user != null && contexts.isNotEmpty,
                        onTap: () => _showCreatePostSheet(
                          context: context,
                          isDark: isDark,
                          contexts: contexts,
                          activeContextId: activeContextId,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ];

                    if (feed.pinnedItems.isNotEmpty) {
                      allItems.add(
                        _SectionLabel(
                          isDark: isDark,
                          title: 'منشورات مثبتة',
                          icon: Icons.push_pin_outlined,
                        ),
                      );
                      allItems.add(const SizedBox(height: 10));
                      allItems.addAll(
                        feed.pinnedItems.map(
                          (post) => _CommunityPostCard(
                            post: post,
                            isDark: isDark,
                            isPinned: true,
                            onTap: () => context.push('/community/post/${post.id}'),
                            onLike: () => _togglePostLike(
                              context: context,
                              post: post,
                              activeContextId: activeContextId,
                            ),
                          ),
                        ),
                      );
                    }

                    if (feed.items.isNotEmpty) {
                      allItems.add(
                        _SectionLabel(
                          isDark: isDark,
                          title: 'أحدث النقاشات',
                          icon: Icons.forum_outlined,
                        ),
                      );
                      allItems.add(const SizedBox(height: 10));
                      allItems.addAll(
                        feed.items.map(
                          (post) => _CommunityPostCard(
                            post: post,
                            isDark: isDark,
                            onTap: () => context.push('/community/post/${post.id}'),
                            onLike: () => _togglePostLike(
                              context: context,
                              post: post,
                              activeContextId: activeContextId,
                            ),
                          ),
                        ),
                      );
                    }

                    if (feed.pinnedItems.isEmpty && feed.items.isEmpty) {
                      allItems.add(
                        _EmptyState(
                          isDark: isDark,
                          title: user == null ? 'سجّل دخولك للانضمام إلى المجتمع' : 'لا توجد منشورات بعد',
                          subtitle: user == null
                              ? 'المجتمع يبدأ بعد تسجيل الدخول، وستظهر لك المساحات المتاحة لك مباشرة.'
                              : 'ابدأ أول منشور في هذه المساحة وشارك سؤالًا أو فائدة أو تدبرًا.',
                        ),
                      );
                    }

                    allItems.add(const SizedBox(height: 24));

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      children: allItems,
                    );
                  },
                  loading: () => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: CircularProgressIndicator(
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  error: (error, _) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      _EmptyState(
                        isDark: isDark,
                        title: 'تعذر تحميل المجتمع',
                        subtitle: error.toString().replaceFirst('Exception: ', ''),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveActiveContextId(List<CommunityContextModel> contexts) {
    if (_selectedContextId != null && contexts.any((item) => item.id == _selectedContextId)) {
      return _selectedContextId;
    }
    if (contexts.isNotEmpty) {
      return contexts.first.id;
    }
    return null;
  }

  Future<void> _togglePostLike({
    required BuildContext context,
    required CommunityPostModel post,
    required String? activeContextId,
  }) async {
    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجل دخولك أولًا للتفاعل داخل المجتمع.')),
      );
      context.go('/auth');
      return;
    }

    try {
      await ref.read(communityRepositoryProvider).setPostLike(
            postId: post.id,
            active: !post.viewerState.liked,
          );
      ref.invalidate(communityFeedProvider(activeContextId));
      ref.invalidate(communityPostDetailsProvider(post.id));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showCreatePostSheet({
    required BuildContext context,
    required bool isDark,
    required List<CommunityContextModel> contexts,
    required String? activeContextId,
  }) async {
    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجل دخولك أولًا لإنشاء منشور جديد.')),
      );
      context.go('/auth');
      return;
    }

    if (contexts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مساحة مجتمع متاحة لهذا الحساب الآن.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final initialContextId = activeContextId ?? contexts.first.id;
    String selectedContextId = initialContextId;
    String title = '';
    String body = '';
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> submit() async {
              if (body.trim().length < 3) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('اكتب نص المنشور أولًا.')),
                );
                return;
              }

              setSheetState(() => isSubmitting = true);

              try {
                await ref.read(communityRepositoryProvider).createPost(
                      primaryContextId: selectedContextId,
                      title: title.trim().isEmpty ? null : title.trim(),
                      body: body.trim(),
                    );

                ref.invalidate(communityFeedProvider(selectedContextId));
                ref.invalidate(communityContextsProvider);

                if (mounted) {
                  setState(() {
                    _selectedContextId = selectedContextId;
                  });
                }

                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }

                messenger.showSnackBar(
                  const SnackBar(content: Text('تم نشر المنشور بنجاح.')),
                );
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(error.toString().replaceFirst('Exception: ', '')),
                  ),
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
                      'منشور جديد',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedContextId,
                      decoration: const InputDecoration(
                        labelText: 'المساحة',
                      ),
                      items: contexts
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.title),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }
                              setSheetState(() {
                                selectedContextId = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !isSubmitting,
                      onChanged: (value) => title = value,
                      decoration: const InputDecoration(
                        labelText: 'عنوان مختصر اختياري',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !isSubmitting,
                      minLines: 4,
                      maxLines: 7,
                      onChanged: (value) => body = value,
                      decoration: const InputDecoration(
                        labelText: 'اكتب منشورك',
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
}

class _ContextStrip extends StatelessWidget {
  final bool isDark;
  final AsyncValue<List<CommunityContextModel>> contextsAsync;
  final String? selectedContextId;
  final ValueChanged<String> onSelected;

  const _ContextStrip({
    required this.isDark,
    required this.contextsAsync,
    required this.selectedContextId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: contextsAsync.when(
        data: (contexts) {
          if (contexts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'ستظهر مساحات المجتمع هنا عندما تتوفر لحسابك.',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            itemBuilder: (context, index) {
              final item = contexts[index];
              final isSelected = item.id == selectedContextId;
              return ChoiceChip(
                label: Text(item.title),
                selected: isSelected,
                onSelected: (_) => onSelected(item.id),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.accentForeground(isDark)
                      : AppColors.textPrimary(isDark),
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: AppColors.panelColor(isDark),
                selectedColor: isDark ? AppColors.darkPrimary : AppColors.accent,
                side: BorderSide(color: AppColors.borderColor(isDark)),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: contexts.length,
          );
        },
        loading: () => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _CreatePostBox extends StatelessWidget {
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  const _CreatePostBox({
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                Icons.edit_note_outlined,
                color: AppColors.appBarForeground(isDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                enabled ? 'اكتب منشورًا جديدًا أو سؤالًا للمجتمع' : 'سجل الدخول أولًا لبدء المشاركة',
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;

  const _SectionLabel({
    required this.isDark,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.appBarForeground(isDark),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  final CommunityPostModel post;
  final bool isDark;
  final bool isPinned;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _CommunityPostCard({
    required this.post,
    required this.isDark,
    required this.onTap,
    required this.onLike,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy - HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.subtleFill(isDark),
                    backgroundImage: post.author.avatarUrl != null
                        ? NetworkImage(post.author.avatarUrl!)
                        : null,
                    child: post.author.avatarUrl == null
                        ? Icon(
                            Icons.person_rounded,
                            color: AppColors.appBarForeground(isDark),
                            size: 18,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatter.format(post.createdAt),
                          style: TextStyle(
                            color: AppColors.textSecondary(isDark),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPinned)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Icon(
                        Icons.push_pin_outlined,
                        size: 18,
                        color: isDark ? AppColors.darkPrimary : AppColors.accent,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.subtleFill(isDark),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.primaryContext.title,
                      style: TextStyle(
                        color: AppColors.appBarForeground(isDark),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if ((post.title ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  post.title!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                post.body,
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ActionButton(
                    icon: post.viewerState.liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                    label: '${post.counts.reactions}',
                    color: post.viewerState.liked
                        ? (isDark ? AppColors.darkPrimary : AppColors.accent)
                        : AppColors.textSecondary(isDark),
                    onTap: onLike,
                  ),
                  const SizedBox(width: 20),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '${post.counts.comments}',
                    color: AppColors.textSecondary(isDark),
                    onTap: onTap,
                  ),
                  if (post.isLocked) ...[
                    const Spacer(),
                    const Text(
                      'التعليقات مغلقة',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
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
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            color: AppColors.appBarForeground(isDark),
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
