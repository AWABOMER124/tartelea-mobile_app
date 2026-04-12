import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/audio_room_model.dart';
import '../providers/audio_room_list_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common_app_bar.dart';

class AudioRoomsScreen extends ConsumerWidget {
  const AudioRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthorized = ref.watch(isAuthorizedProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final roomsAsync = ref.watch(liveAudioRoomsProvider);

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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('إنشاء الغرف من التطبيق سيتفعّل في التحديث القادم.'),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.stars_rounded, color: AppColors.accent),
            onPressed: () => context.push('/pricing'),
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
                  _buildLiveIndicator(isDark),
                  const SizedBox(height: 12),
                  _buildInfoPanel(isDark),
                ],
              ),
            ),
            Expanded(
              child: roomsAsync.when(
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return _AudioRoomsEmptyState(isDark: isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(liveAudioRoomsProvider.future),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) => _RoomCard(
                        room: rooms[index],
                        isDark: isDark,
                      ),
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
                error: (_, __) => _AudioRoomsErrorState(
                  isDark: isDark,
                  onRetry: () => ref.refresh(liveAudioRoomsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'يوجد بث صوتي مباشر الآن',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(bool isDark) {
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
            'جلسات مباشرة بهوية المدرسة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'استكشف الغرف المتاحة وتابع المستمعين والمضيفين قبل الانضمام.',
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

class _AudioRoomsEmptyState extends StatelessWidget {
  final bool isDark;

  const _AudioRoomsEmptyState({required this.isDark});

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
              'لا توجد غرف صوتية مباشرة الآن',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'عند بدء غرفة جديدة ستظهر هنا مباشرة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioRoomsErrorState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;

  const _AudioRoomsErrorState({
    required this.isDark,
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
              'تعذر تحميل الغرف الصوتية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDark),
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

class _RoomCard extends StatelessWidget {
  final AudioRoomModel room;
  final bool isDark;

  const _RoomCard({
    required this.room,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: InkWell(
        onTap: () => context.push('/audio-room/${room.id}'),
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
                      color: Colors.redAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'غرفة نشطة',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                room.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              if (room.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  room.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _AvatarStack(isDark: isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.hostName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.appBarForeground(isDark),
                          ),
                        ),
                        Text(
                          '${room.listenerCount} مستمع حالياً',
                          style: TextStyle(
                            color: AppColors.textSecondary(isDark),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
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
}

class _AvatarStack extends StatelessWidget {
  final bool isDark;

  const _AvatarStack({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 40,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.subtleFill(isDark),
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: AppColors.appBarForeground(isDark),
              ),
            ),
          ),
          Positioned(
            left: 20,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.accentSoft,
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: AppColors.accentForeground(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
