import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../data/models/session_models.dart';
import '../../data/repositories/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return SessionRepository(api);
});

final sessionListProvider =
    FutureProvider.family<List<SessionListItemModel>, String?>((ref, status) {
  return ref.read(sessionRepositoryProvider).listSessions(status: status);
});

final sessionDetailsProvider =
    FutureProvider.family<SessionDetailsModel, String>((ref, sessionId) {
  return ref.read(sessionRepositoryProvider).getSessionDetails(sessionId);
});
