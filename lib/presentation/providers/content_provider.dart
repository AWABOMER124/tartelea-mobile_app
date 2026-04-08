import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_provider.dart';
import '../../data/models/content_model.dart';
import '../../data/repositories/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ContentRepository(api);
});

final contentsProvider = FutureProvider.family<List<ContentModel>, String?>((ref, category) {
  return ref.watch(contentRepositoryProvider).getContents(category: category);
});

final sudanAwarenessProvider = FutureProvider<List<ContentModel>>((ref) {
  return ref.watch(contentRepositoryProvider).getContents(isSudanAwareness: true);
});
