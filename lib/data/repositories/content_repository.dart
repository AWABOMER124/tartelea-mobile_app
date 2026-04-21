import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/api/api_payload.dart';
import '../models/content_library_models.dart';

class ContentRepository {
  final ApiClient _api;

  ContentRepository(this._api);

  Future<List<ContentCategoryModel>> getCategories() async {
    try {
      final response = await _api.get(
        ApiConfig.contentCategories,
      );

      return ApiPayload.unwrapList(response.data)
          .map((json) => ContentCategoryModel.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ContentTrackModel>> getTracks({String? categorySlug}) async {
    try {
      final response = await _api.get(
        ApiConfig.contentTracks,
        queryParameters: {
          if (categorySlug != null && categorySlug.isNotEmpty)
            'category_slug': categorySlug,
        },
      );

      return ApiPayload.unwrapList(response.data)
          .map((json) => ContentTrackModel.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ContentFeaturedResponse?> getFeatured() async {
    try {
      final response = await _api.get(ApiConfig.featuredContent);
      return ContentFeaturedResponse.fromJson(
        ApiPayload.unwrapObject(response.data),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<LibraryItemModel>> getLibraryItems({
    String? categorySlug,
    String? trackSlug,
    String? contentType,
    bool? featured,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.libraryItems,
        queryParameters: {
          if (categorySlug != null && categorySlug.isNotEmpty)
            'category_slug': categorySlug,
          if (trackSlug != null && trackSlug.isNotEmpty) 'track_slug': trackSlug,
          if (contentType != null && contentType.isNotEmpty)
            'content_type': contentType,
          if (featured != null) 'featured': featured,
        },
      );

      return ApiPayload.unwrapList(response.data)
          .map((json) => LibraryItemModel.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ProgramModel>> getPrograms({
    String? categorySlug,
    String? trackSlug,
    bool? featured,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.programs,
        queryParameters: {
          if (categorySlug != null && categorySlug.isNotEmpty)
            'category_slug': categorySlug,
          if (trackSlug != null && trackSlug.isNotEmpty) 'track_slug': trackSlug,
          if (featured != null) 'featured': featured,
        },
      );

      return ApiPayload.unwrapList(response.data)
          .map((json) => ProgramModel.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ProgramLessonModel>> getProgramLessons(String programId) async {
    try {
      final response = await _api.get(ApiConfig.programLessons(programId));
      return ApiPayload.unwrapList(response.data)
          .map((json) => ProgramLessonModel.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
