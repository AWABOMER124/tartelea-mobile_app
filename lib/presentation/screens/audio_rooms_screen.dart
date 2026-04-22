import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/session_models.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/app_states.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pulsing_dot.dart';

class AudioRoomsScreen extends ConsumerStatefulWidget {
  const AudioRoomsScreen({super.key});

  @override
  ConsumerState<AudioRoomsScreen> createState() => _AudioRoomsScreenState();
}

class _AudioRoomsScreenState extends ConsumerState<AudioRoomsScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final isAuthorized = ref.watch(isAuthorizedProvider);
    final selectedStatus = _selectedStatus;
    final sessionsAsync = ref.watch(sessionListProvider(selectedStatus));

    return Scaffold(
      appBar: CommonAppBar(
        title: 'الغرف الصوتية',
        transparent: true,
        actions: [
          if (isAuthorized)
            IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.appBarForeground(isDark),
              ),
              onPressed: () => _showCreateRoomSheet(context, isDark),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(isDark),
        ),
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.page.copyWith(bottom: AppSpacing.s12),
              child: Column(
                children: [
                  _buildHeroPanel(isDark),
                  const SizedBox(height: 14),
                  _StatusStrip(
                    isDark: isDark,
                    selectedStatus: selectedStatus ?? 'all',
                    onSelected: (status) {
                      setState(() {
                        _selectedStatus = status == 'all' ? null : status;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Padding(
                      padding: AppSpacing.page,
                      child: AppEmptyState(
                        icon: Icons.mic_external_on_outlined,
                        title: 'لا توجد جلسات حالياً',
                        message:
                            'عندما تبدأ جلسة أو يتم جدولة جلسات جديدة ستظهر هنا.',
                        actionLabel: 'تحديث',
                        onAction: () =>
                            ref.invalidate(sessionListProvider(selectedStatus)),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(sessionListProvider(selectedStatus));
                    },
                    child: ListView.builder(
                      padding: AppSpacing.page.copyWith(top: AppSpacing.s8),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) => _SessionCard(
                        item: sessions[index],
                        isDark: isDark,
                        onTap: () => context
                            .push('/audio-room/${sessions[index].session.id}'),
                      ),
                    ),
                  );
                },
                loading: () => ListView.builder(
                  padding: AppSpacing.page.copyWith(top: AppSpacing.s8),
                  itemCount: 3,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.s16),
                    child: AppSkeletonCard(height: 220),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: AppSpacing.page,
                  child: AppErrorState(
                    title: 'تعذر تحميل الجلسات',
                    message: error.toString().replaceFirst('Exception: ', ''),
                    onRetry: () =>
                        ref.invalidate(sessionListProvider(selectedStatus)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateRoomSheet(BuildContext context, bool isDark) async {
    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجل الدخول أولًا لإنشاء جلسة صوتية.')),
      );
      context.go('/auth');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    String title = '';
    String description = '';
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (title.trim().length < 3) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('عنوان الجلسة يجب أن يكون 3 أحرف على الأقل.'),
                  ),
                );
                return;
              }

              setSheetState(() => isSubmitting = true);

              try {
                final created =
                    await ref.read(sessionRepositoryProvider).createSession(
                          title: title.trim(),
                          description: description.trim().isEmpty
                              ? null
                              : description.trim(),
                        );

                ref.invalidate(sessionListProvider(null));
                ref.invalidate(sessionListProvider('scheduled'));
                ref.invalidate(sessionListProvider('live'));

                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }

                messenger.showSnackBar(
                  const SnackBar(content: Text('تم إنشاء الجلسة بنجاح.')),
                );

                if (!context.mounted) {
                  return;
                }

                context.push('/audio-room/${created.session.id}');
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(
                    content:
                        Text(error.toString().replaceFirst('Exception: ', '')),
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
                      'إنشاء جلسة صوتية',
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
                        labelText: 'عنوان الجلسة',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: !isSubmitting,
                      minLines: 3,
                      maxLines: 5,
                      onChanged: (value) => description = value,
                      decoration: const InputDecoration(
                        labelText: 'وصف مختصر',
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('إنشاء الجلسة'),
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

  Widget _buildHeroPanel(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient(isDark),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جلسات مباشرة ومساحات قادمة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الموبايل أصبح يقرأ الغرف من عقد sessions الرسمي. افتح الجلسة لمتابعة البث أو الانضمام والتحكم حسب صلاحياتك.',
            style: TextStyle(
              color: Colors.white.withAlpha(222),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final bool isDark;
  final String selectedStatus;
  final ValueChanged<String> onSelected;

  const _StatusStrip({
    required this.isDark,
    required this.selectedStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'الكل'),
      ('live', 'مباشر الآن'),
      ('scheduled', 'القادمة'),
      ('ended', 'المنتهية'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter.$1 == selectedStatus;

          return ChoiceChip(
            label: Text(filter.$2),
            selected: isSelected,
            onSelected: (_) => onSelected(filter.$1),
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
        itemCount: filters.length,
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionListItemModel item;
  final bool isDark;
  final VoidCallback onTap;

  const _SessionCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheduledAt = item.session.scheduledAt.toLocal();
    final dateLabel = DateFormat('dd MMM - HH:mm').format(scheduledAt);
    final statusLabel = switch (item.session.status) {
      'live' => 'مباشر',
      'ended' => 'منتهية',
      _ => 'قادمة',
    };
    final statusColor = _statusColor(item.session.status, isDark);
    final gradient = _cardGradient(item.session.status, isDark);
    final denialText = _denialReasonText(item.access.denialReason);
    final host = item.room.host;
    final participantTotal = item.room.participantCount;
    final visiblePeople = _participantsPreview();

    final primaryLabel = item.session.isLive
        ? (item.access.canJoin ? 'انضم للبث' : 'غير متاح')
        : 'عرض التفاصيل';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: AppColors.borderColor(isDark).withAlpha(120)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 70 : 30),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _avatar(host.avatarUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            host.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withAlpha(238),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.session.visibility == 'restricted'
                                ? 'وصول مقيّد'
                                : 'وصول عام',
                            style: TextStyle(
                              color: Colors.white.withAlpha(190),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusPill(statusLabel, statusColor),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.session.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (item.session.description ?? '').trim().isNotEmpty
                      ? item.session.description!
                      : _categoryLabel(item.session.category),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _meta(
                      Icons.people_outline,
                      '$participantTotal/${item.room.maxParticipants}',
                    ),
                    const SizedBox(width: 10),
                    _meta(Icons.schedule_outlined, dateLabel),
                    const Spacer(),
                    _avatarStack(visiblePeople, statusColor),
                  ],
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: denialText != null
                      ? Text(
                          denialText,
                          key: const ValueKey('denied'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('ok')),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (item.session.isLive && !item.access.canJoin)
                        ? null
                        : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.accentForeground(isDark),
                      disabledBackgroundColor: Colors.white.withAlpha(130),
                      disabledForegroundColor:
                          AppColors.accentForeground(isDark).withAlpha(160),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    icon: Icon(item.session.isLive
                        ? Icons.headphones_outlined
                        : Icons.chevron_left_rounded),
                    label: Text(primaryLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status, bool isDark) {
    return switch (status) {
      'live' => const Color(0xFFFF3B30),
      'ended' => Colors.white.withAlpha(180),
      _ => isDark ? AppColors.darkPrimary : AppColors.accent,
    };
  }

  LinearGradient _cardGradient(String status, bool isDark) {
    final base = _statusColor(status, isDark);
    if (status == 'ended') {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (isDark ? AppColors.darkSurface : AppColors.surface).withAlpha(220),
          (isDark ? AppColors.darkCard : AppColors.card).withAlpha(220),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base.withAlpha(isDark ? 210 : 230),
        AppColors.primary.withAlpha(isDark ? 210 : 230),
        (isDark ? AppColors.deepForest : AppColors.spiritualGreen)
            .withAlpha(isDark ? 210 : 230),
      ],
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == 'مباشر') ...[
            PulsingDot(color: color, size: 7),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withAlpha(240),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withAlpha(220)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(220),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _avatar(String? avatarUrl) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white.withAlpha(32),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? const Icon(Icons.person_outline, color: Colors.white)
          : null,
    );
  }

  List<SessionUserSummaryModel> _participantsPreview() {
    final users = <SessionUserSummaryModel>[
      item.room.host,
      ...item.room.speakers,
      ...item.room.moderators
    ];
    final seen = <String>{};
    final unique = <SessionUserSummaryModel>[];
    for (final user in users) {
      if (user.id.isEmpty) continue;
      if (!seen.add(user.id)) continue;
      unique.add(user);
      if (unique.length >= 5) break;
    }
    return unique;
  }

  Widget _avatarStack(List<SessionUserSummaryModel> users, Color accent) {
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    const overlap = 14.0;
    final max = users.length > 5 ? 5 : users.length;
    final width = 36 + (max - 1) * overlap;

    return SizedBox(
      width: width,
      height: 36,
      child: Stack(
        children: [
          for (var i = 0; i < max; i++)
            Positioned(
              right: i * overlap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withAlpha(210), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withAlpha(26),
                  backgroundImage: users[i].avatarUrl != null
                      ? NetworkImage(users[i].avatarUrl!)
                      : null,
                  child: users[i].avatarUrl == null
                      ? const Icon(Icons.person_outline,
                          color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ),
          if (users.length > max)
            Positioned(
              right: max * overlap,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withAlpha(26),
                child: Text(
                  '+${users.length - max}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(240),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'quran' => 'مجلس قرآني',
      'values' => 'مجلس القيم',
      'community' => 'مجلس عام',
      'tahliya' => 'مجلس التحلية',
      'takhliya' => 'مجلس التخلية',
      'tajalli' => 'مجلس التجلي',
      _ => 'جلسة صوتية',
    };
  }

  String? _denialReasonText(String? denialReason) {
    return switch (denialReason) {
      'AUTH_REQUIRED' => 'سجل الدخول أولًا للانضمام.',
      'SESSION_NOT_APPROVED' => 'هذه الجلسة ما زالت بانتظار المراجعة.',
      'SESSION_ENDED' => 'هذه الجلسة انتهت بالفعل.',
      'SESSION_FULL' => 'وصلت الجلسة إلى الحد الأقصى من الحضور.',
      'SUBSCRIPTION_REQUIRED' => 'هذه الجلسة تتطلب اشتراكًا فعالًا.',
      _ => null,
    };
  }
}
