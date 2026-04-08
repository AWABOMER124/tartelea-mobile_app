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
      extendBodyBehindAppBar: true,
      appBar: CommonAppBar(
        actions: [
          if (isAuthorized)
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: isDark ? Colors.white : AppColors.primary,
              ),
              onPressed: () {},
            ),
          IconButton(
            icon: const Icon(
              Icons.stars,
              color: AppColors.accent,
            ),
            onPressed: () => context.push('/pricing'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [Colors.white, AppColors.secondary.withAlpha(51)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildLiveIndicator(isDark),
            Expanded(
              child: roomsAsync.when(
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return _AudioRoomsEmptyState(isDark: isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(liveAudioRoomsProvider.future),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        return _RoomCard(
                          room: rooms[index],
                          isDark: isDark,
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(25)
            : AppColors.secondary.withAlpha(127),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(51) : AppColors.secondary,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'يوجد بث صوتي مباشر الآن',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white : AppColors.primary,
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
              color: isDark ? Colors.white70 : AppColors.primary.withAlpha(180),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد غرف صوتية مباشرة الآن',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'عند بدء غرفة جديدة ستظهر هنا مباشرة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.mutedForeground,
              ),
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
              color: isDark ? Colors.white70 : AppColors.primary.withAlpha(180),
            ),
            const SizedBox(height: 12),
            Text(
              'تعذر تحميل الغرف الصوتية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.foreground,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withAlpha(25),
      color: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? Colors.white.withAlpha(51)
              : AppColors.secondary.withAlpha(127),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/audio-room/${room.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('LIVE', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(
                    'غرفة نشطة',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withAlpha(179)
                          : AppColors.mutedForeground,
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
                  color: isDark ? Colors.white : AppColors.foreground,
                ),
              ),
              if (room.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  room.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withAlpha(180)
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
              const SizedBox(height: 12),
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
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : AppColors.primary,
                          ),
                        ),
                        Text(
                          '${room.listenerCount} مستمع حاليًا',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withAlpha(153)
                                : AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_left,
                    color: isDark
                        ? Colors.white38
                        : AppColors.primary.withAlpha(127),
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
              backgroundColor:
                  isDark ? AppColors.primary : AppColors.secondary,
              child: Icon(
                Icons.person,
                size: 20,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          Positioned(
            left: 20,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accent,
              child: Icon(
                Icons.person,
                size: 20,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
