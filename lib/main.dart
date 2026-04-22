import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/audio_room_detail_screen.dart';
import 'presentation/screens/audio_rooms_screen.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/community_post_detail_screen.dart';
import 'presentation/screens/community_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/library_screen.dart';
import 'presentation/screens/notifications_screen.dart';
import 'presentation/screens/pricing_screen.dart';
import 'presentation/screens/workshops_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TarteleaApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/pricing',
      builder: (context, state) => const PricingScreen(),
    ),
    GoRoute(
      path: '/workshops',
      builder: (context, state) => const WorkshopsScreen(),
    ),
    GoRoute(
      path: '/audio-rooms',
      builder: (context, state) => const AudioRoomsScreen(),
    ),
    GoRoute(
      path: '/audio-room/:id',
      builder: (context, state) => AudioRoomDetailScreen(
        roomId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => LibraryScreen(
        initialSidebarCategory: state.extra as String?,
      ),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityScreen(),
    ),
    GoRoute(
      path: '/community/post/:postId',
      builder: (context, state) => CommunityPostDetailScreen(
        postId: state.pathParameters['postId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);

class TarteleaApp extends ConsumerWidget {
  const TarteleaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Tartelea',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
