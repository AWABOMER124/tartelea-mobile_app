import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/api/api_payload.dart';
import '../models/post_model.dart';

class PostRepository {
  final ApiClient _api;

  PostRepository(this._api);

  Future<List<PostModel>> getPosts({String? category}) async {
    try {
      final response = await _api.get(
        ApiConfig.posts,
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );

      return ApiPayload.unwrapList(
        response.data,
        preferredKeys: const ['posts'],
      ).map((json) => PostModel.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<PostModel?> createPost({
    required String title,
    String? body,
    required String category,
  }) async {
    try {
      final response = await _api.post(ApiConfig.posts, data: {
        'title': title,
        'body': body,
        'category': category,
      });

      return PostModel.fromJson(
        ApiPayload.unwrapObject(
          response.data,
          preferredKeys: const ['post'],
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> likePost(String postId) async {
    await _api.post('${ApiConfig.posts}/$postId/like');
  }

  Future<void> addComment(String postId, String text) async {
    await _api.post('${ApiConfig.posts}/$postId/comment', data: {
      'content': text,
    });
  }
}
