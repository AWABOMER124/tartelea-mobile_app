import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/audio_room_model.dart';
import '../providers/audio_room_list_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common_app_bar.dart';

class AudioRoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const AudioRoomDetailScreen({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = ref.watch(userProvider);
    final roomsAsync = ref.watch(liveAudioRoomsProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: 'تفاصيل الغرفة'),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(isDark),
        ),
        child: roomsAsync.when(
          data: (rooms) {
            final AudioRoomModel? room =
                rooms.where((item) => item.id == roomId).firstOrNull;

            if (room == null) {
              return Center(
                child: Text(
                  'هذه الغرفة غير متاحة حالياً.',
                  style: TextStyle(color: AppColors.textSecondary(isDark)),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient(isDark),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        room.description.isEmpty ? 'غرفة صوتية مباشرة داخل المدرسة.' : room.description,
                        style: TextStyle(color: Colors.white.withAlpha(222), height: 1.6),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MetaChip(label: room.hostName),
                          _MetaChip(label: '${room.listenerCount} مستمع'),
                          const _MetaChip(label: 'بث مباشر'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.panelColor(isDark),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderColor(isDark)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'جاهزية الدخول',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user == null
                            ? 'سجّل الدخول أولاً ليتاح لك الانضمام إلى الغرفة عند اكتمال الجلسة الصوتية.'
                            : 'المسار الخلفي للغرف الصوتية متصل، وتبقى خطوة جلسة البث نفسها مرتبطة بتفعيل عميل LiveKit في هذه النسخة.',
                        style: TextStyle(
                          color: AppColors.textSecondary(isDark),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: user == null
                              ? () => context.go('/auth')
                              : null,
                          child: Text(user == null ? 'تسجيل الدخول للمتابعة' : 'الانضمام الصوتي قيد التفعيل'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
