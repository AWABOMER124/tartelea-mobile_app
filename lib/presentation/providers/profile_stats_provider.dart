import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'session_provider.dart';

final sessionsAttendedCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return 0;

  final sessions =
      await ref.watch(sessionRepositoryProvider).listSessions(status: 'ended');
  return sessions.where((item) => item.access.isRegistered).length;
});

