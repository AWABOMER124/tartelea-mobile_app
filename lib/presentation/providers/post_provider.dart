import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/supabase_config.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return PostRepository(client);
});

final postsProvider = FutureProvider.family<List<PostModel>, String?>((ref, category) {
  return ref.read(postRepositoryProvider).getPosts(category: category);
});
