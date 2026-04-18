import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../data/models/community_models.dart';
import '../../data/repositories/community_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CommunityRepository(api);
});

final communityContextsProvider = FutureProvider<List<CommunityContextModel>>((ref) {
  return ref.read(communityRepositoryProvider).listContexts();
});

final communityFeedProvider = FutureProvider.family<CommunityFeedModel, String?>((ref, contextId) {
  return ref.read(communityRepositoryProvider).listFeed(contextId: contextId);
});

final communityPostDetailsProvider = FutureProvider.family<CommunityPostModel, String>((ref, postId) {
  return ref.read(communityRepositoryProvider).getPostDetails(postId);
});
