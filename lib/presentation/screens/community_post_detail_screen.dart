import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/community_models.dart';
import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../providers/theme_provider.dart';

class CommunityPostDetailScreen extends ConsumerWidget {
  final String postId;

  const CommunityPostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final postAsync = ref.watch(communityPostDetailsProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنشور'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(isDark),
        ),
        child: RefreshIndicator(
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          onRefresh: () async {
            ref.invalidate(communityPostDetailsProvider(postId));
          },
          child: postAsync.when(
            data: (post) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                children: [
                  _PostHeaderCard(
                    post: post,
                    isDark: isDark,
                    onLike: () => _togglePostLike(context, ref, post),
                  ),
                  const SizedBox(height: 16),
                  if (post.scopes.isNotEmpty) ...[
                    Text(
                      'المساحات المرتبطة',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: post.scopes
                          .map(
                            (scope) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.panelColor(isDark),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: AppColors.borderColor(isDark)),
                              ),
                              child: Text(
                                scope.title,
                                style: TextStyle(
                                  color: AppColors.textPrimary(isDark),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Text(
                        'التعليقات',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDark),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${post.counts.comments})',
                        style: TextStyle(
                          color: AppColors.textSecondary(isDark),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (post.viewerState.canComment)
                        TextButton.icon(
                          onPressed: () => _showCommentSheet(
                            context: context,
                            ref: ref,
                            post: post,
                          ),
                          icon: const Icon(Icons.add_comment_outlined, size: 18),
                          label: const Text('تعليق جديد'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (post.comments.isEmpty)
                    _EmptyCommentsState(isDark: isDark)
                  else
                    ...post.comments.map(
                      (comment) => _CommentCard(
                        comment: comment,
                        isDark: isDark,
                        canReply: post.viewerState.canComment && comment.depth == 0,
                        onReply: () => _showCommentSheet(
                          context: context,
                          ref: ref,
                          post: post,
                          parentCommentId: comment.id,
                          parentAuthorName: comment.author.name,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 100),
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
                const SizedBox(height: 100),
                _EmptyCommentsState(
                  isDark: isDark,
                  title: 'تعذر تحميل المنشور',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _togglePostLike(
    BuildContext context,
    WidgetRef ref,
    CommunityPostModel post,
  ) async {
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
      ref.invalidate(communityPostDetailsProvider(post.id));
      ref.invalidate(communityFeedProvider(post.primaryContext.id));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showCommentSheet({
    required BuildContext context,
    required WidgetRef ref,
    required CommunityPostModel post,
    String? parentCommentId,
    String? parentAuthorName,
  }) async {
    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجل دخولك أولًا لإضافة تعليق.')),
      );
      context.go('/auth');
      return;
    }

    String body = '';
    bool isSubmitting = false;
    final messenger = ScaffoldMessenger.of(context);
    final isDark = ref.read(themeProvider) == ThemeMode.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> submit() async {
              if (body.trim().length < 2) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('اكتب تعليقًا قبل الإرسال.')),
                );
                return;
              }

              setSheetState(() => isSubmitting = true);

              try {
                await ref.read(communityRepositoryProvider).addComment(
                      postId: post.id,
                      body: body.trim(),
                      parentCommentId: parentCommentId,
                    );
                ref.invalidate(communityPostDetailsProvider(post.id));
                ref.invalidate(communityFeedProvider(post.primaryContext.id));

                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                messenger.showSnackBar(
                  const SnackBar(content: Text('تمت إضافة التعليق.')),
                );
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
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
                      parentCommentId == null ? 'تعليق جديد' : 'رد على ${parentAuthorName ?? 'التعليق'}',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      enabled: !isSubmitting,
                      minLines: 4,
                      maxLines: 7,
                      onChanged: (value) => body = value,
                      decoration: const InputDecoration(
                        labelText: 'اكتب تعليقك',
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
                            : const Text('إرسال التعليق'),
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

class _PostHeaderCard extends StatelessWidget {
  final CommunityPostModel post;
  final bool isDark;
  final VoidCallback onLike;

  const _PostHeaderCard({
    required this.post,
    required this.isDark,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy - HH:mm');

    return Container(
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
                radius: 20,
                backgroundColor: AppColors.subtleFill(isDark),
                backgroundImage: post.author.avatarUrl != null
                    ? NetworkImage(post.author.avatarUrl!)
                    : null,
                child: post.author.avatarUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        color: AppColors.appBarForeground(isDark),
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
                        color: AppColors.textPrimary(isDark),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatter.format(post.createdAt),
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 11,
                      ),
                    ),
                  ],
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
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if ((post.title ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              post.title!,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            post.body,
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: onLike,
                icon: Icon(
                  post.viewerState.liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                  color: post.viewerState.liked
                      ? (isDark ? AppColors.darkPrimary : AppColors.accent)
                      : AppColors.textSecondary(isDark),
                ),
                label: Text('${post.counts.reactions}'),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: AppColors.textSecondary(isDark),
              ),
              const SizedBox(width: 6),
              Text(
                '${post.counts.comments}',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
              if (post.isPinned) ...[
                const Spacer(),
                Icon(
                  Icons.push_pin_outlined,
                  size: 18,
                  color: isDark ? AppColors.darkPrimary : AppColors.accent,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final CommunityCommentModel comment;
  final bool isDark;
  final bool canReply;
  final VoidCallback onReply;

  const _CommentCard({
    required this.comment,
    required this.isDark,
    required this.canReply,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy - HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.subtleFill(isDark),
                backgroundImage: comment.author.avatarUrl != null
                    ? NetworkImage(comment.author.avatarUrl!)
                    : null,
                child: comment.author.avatarUrl == null
                    ? Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.appBarForeground(isDark),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author.name,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatter.format(comment.createdAt),
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (canReply)
                TextButton(
                  onPressed: onReply,
                  child: const Text('رد'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.body,
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              height: 1.6,
            ),
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...comment.replies.map(
              (reply) => Container(
                margin: const EdgeInsetsDirectional.only(start: 16, bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.subtleFill(isDark),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.author.name,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reply.body,
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        height: 1.5,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCommentsState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const _EmptyCommentsState({
    required this.isDark,
    this.title = 'لا توجد تعليقات بعد',
    this.subtitle = 'ابدأ النقاش بإضافة أول تعليق على هذا المنشور.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mark_chat_unread_outlined,
            size: 30,
            color: AppColors.appBarForeground(isDark),
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
