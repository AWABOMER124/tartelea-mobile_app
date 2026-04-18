import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../models/community_models.dart';

class CommunityRepository {
  final ApiClient _api;

  CommunityRepository(this._api);

  Future<List<CommunityContextModel>> listContexts() async {
    try {
      final response = await _api.get(ApiConfig.communityContexts);
      final payload = _asMap(response.data);
      final items = payload['contexts'] as List? ?? const [];
      return items
          .map((item) => CommunityContextModel.fromJson(_asMap(item)))
          .toList();
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تحميل مساحات المجتمع.'));
    }
  }

  Future<CommunityFeedModel> listFeed({
    String? contextId,
    String? cursor,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.communityFeed,
        queryParameters: {
          if (contextId != null && contextId.isNotEmpty) 'context_id': contextId,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
      );
      return CommunityFeedModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تحميل منشورات المجتمع.'));
    }
  }

  Future<CommunityPostModel> getPostDetails(String postId) async {
    try {
      final response = await _api.get('${ApiConfig.communityPosts}/$postId');
      final payload = _asMap(response.data);
      return CommunityPostModel.fromJson(_asMap(payload['post']));
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تحميل تفاصيل المنشور.'));
    }
  }

  Future<CommunityPostModel> createPost({
    required String primaryContextId,
    required String body,
    String? title,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.communityPosts,
        data: {
          'primary_context_id': primaryContextId,
          'body': body,
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        },
      );
      final payload = _asMap(response.data);
      return CommunityPostModel.fromJson(_asMap(payload['post']));
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر إنشاء المنشور.'));
    }
  }

  Future<CommunityCommentModel> addComment({
    required String postId,
    required String body,
    String? parentCommentId,
  }) async {
    try {
      final response = await _api.post(
        '${ApiConfig.communityPosts}/$postId/comments',
        data: {
          'body': body,
          if (parentCommentId != null && parentCommentId.isNotEmpty)
            'parent_comment_id': parentCommentId,
        },
      );
      final payload = _asMap(response.data);
      return CommunityCommentModel.fromJson(_asMap(payload['comment']));
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر إضافة التعليق.'));
    }
  }

  Future<int> setPostLike({
    required String postId,
    required bool active,
  }) async {
    try {
      final response = await _api.put(
        '${ApiConfig.communityPosts}/$postId/reaction',
        data: {
          'reaction_type': 'like',
          'active': active,
        },
      );
      final payload = _asMap(response.data);
      return _asInt(_asMap(payload['reaction'])['count']);
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تحديث الإعجاب.'));
    }
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _messageFromError(DioException error, String fallback) {
  final data = error.response?.data;
  final payload = _asMap(data);
  final rootMessage = payload['message']?.toString().trim();
  final nestedMessage = _asMap(payload['error'])['message']?.toString().trim();

  if (nestedMessage != null && nestedMessage.isNotEmpty) {
    return nestedMessage;
  }
  if (rootMessage != null && rootMessage.isNotEmpty) {
    return rootMessage;
  }
  return error.message ?? fallback;
}
