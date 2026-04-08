import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_provider.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return PostRepository(api);
});

final postsProvider = FutureProvider.family<List<PostModel>, String?>((ref, category) {
  return ref.read(postRepositoryProvider).getPosts(category: category);
});
