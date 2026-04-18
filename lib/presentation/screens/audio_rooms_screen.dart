import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/session_models.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common_app_bar.dart';

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
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
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
                    return _EmptyState(isDark: isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(sessionListProvider(selectedStatus));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) => _SessionCard(
                        item: sessions[index],
                        isDark: isDark,
                        onTap: () =>
                            context.push('/audio-room/${sessions[index].session.id}'),
                      ),
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
                error: (error, _) => _ErrorState(
                  isDark: isDark,
                  message: error.toString().replaceFirst('Exception: ', ''),
                  onRetry: () => ref.invalidate(sessionListProvider(selectedStatus)),
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
                final created = await ref.read(sessionRepositoryProvider).createSession(
                      title: title.trim(),
                      description:
                          description.trim().isEmpty ? null : description.trim(),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
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
    final statusColor = switch (item.session.status) {
      'live' => Colors.redAccent,
      'ended' => AppColors.textSecondary(isDark),
      _ => isDark ? AppColors.darkPrimary : AppColors.accent,
    };
    final denialText = _denialReasonText(item.access.denialReason);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.session.visibility == 'restricted'
                        ? 'وصول مقيّد'
                        : 'وصول عام',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    item.session.isLive ? Icons.radio : Icons.schedule_outlined,
                    color: statusColor,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.session.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              if ((item.session.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.session.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaChip(
                    isDark: isDark,
                    icon: Icons.person_outline,
                    label: item.room.host.name,
                  ),
                  _MetaChip(
                    isDark: isDark,
                    icon: Icons.people_outline,
                    label:
                        '${item.room.participantCount}/${item.room.maxParticipants}',
                  ),
                  _MetaChip(
                    isDark: isDark,
                    icon: Icons.calendar_today_outlined,
                    label: dateLabel,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.access.isRegistered
                          ? (item.session.isLive ? 'أنت مسجل ويمكنك الدخول' : 'أنت مسجل في هذه الجلسة')
                          : denialText ??
                              (item.access.canJoin
                                  ? 'افتح الجلسة لمعرفة خطوات الانضمام'
                                  : 'راجع الجلسة لمزيد من التفاصيل'),
                      style: TextStyle(
                        color: denialText != null
                            ? AppColors.warning
                            : AppColors.textSecondary(isDark),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.appBarForeground(isDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

class _MetaChip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.isDark,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.subtleFill(isDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.appBarForeground(isDark),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none_rounded,
              size: 48,
              color: AppColors.appBarForeground(isDark).withAlpha(180),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد جلسات مطابقة لهذا الفلتر',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرّب تبديل الفلتر أو أنشئ جلسة جديدة إذا كانت الصلاحية متاحة لك.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool isDark;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.isDark,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.appBarForeground(isDark).withAlpha(180),
            ),
            const SizedBox(height: 12),
            Text(
              'تعذر تحميل الجلسات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
