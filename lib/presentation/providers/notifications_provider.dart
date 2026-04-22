import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notifications_repository.dart';
import 'auth_provider.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return NotificationsRepository(api);
});

final notificationsListProvider = FutureProvider<List<NotificationModel>>((ref) {
  final token = ref.watch(authTokenProvider);
  if (token == null || token.isEmpty) {
    return const [];
  }
  return ref.watch(notificationsRepositoryProvider).list(limit: 80);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsListProvider);
  return async.maybeWhen(
    data: (items) => items.where((item) => !item.isRead).length,
    orElse: () => 0,
  );
});
