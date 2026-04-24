import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/api/api_payload.dart';
import '../models/content_library_models.dart';

class ContentRepository {
  final ApiClient _api;

  ContentRepository(this._api);

  Future<List<ContentCategoryModel>> getCategories() async {
    try {
      final response = await _api.get(ApiConfig.contentCategories);
      final categories = ApiPayload.unwrapList(response.data)
          .map((json) => ContentCategoryModel.fromJson(json))
          .toList();

      if (kDebugMode) {
        debugPrint('ContentRepository.getCategories: ${categories.length}');
      }

      return categories;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('ContentRepository.getCategories failed: $error');
      }
      rethrow;
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

      final tracks = ApiPayload.unwrapList(response.data)
          .map((json) => ContentTrackModel.fromJson(json))
          .toList();

      if (kDebugMode) {
        debugPrint(
          'ContentRepository.getTracks(${categorySlug ?? 'all'}): ${tracks.length}',
        );
      }

      return tracks;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('ContentRepository.getTracks failed: $error');
      }
      rethrow;
    }
  }

  Future<ContentFeaturedResponse?> getFeatured() async {
    try {
      final response = await _api.get(ApiConfig.featuredContent);
      if (kDebugMode) {
        debugPrint('ContentRepository.getFeatured: ok');
      }
      return ContentFeaturedResponse.fromJson(
        ApiPayload.unwrapObject(response.data),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('ContentRepository.getFeatured failed: $error');
      }
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

      final items = ApiPayload.unwrapList(response.data)
          .map((json) => LibraryItemModel.fromJson(json))
          .toList();

      if (kDebugMode) {
        debugPrint(
          'ContentRepository.getLibraryItems(category=$categorySlug track=$trackSlug type=$contentType featured=$featured): ${items.length}',
        );
      }

      return items;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('ContentRepository.getLibraryItems failed: $error');
      }
      rethrow;
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

      final programs = ApiPayload.unwrapList(response.data)
          .map((json) => ProgramModel.fromJson(json))
          .toList();

      if (kDebugMode) {
        debugPrint(
          'ContentRepository.getPrograms(category=$categorySlug track=$trackSlug featured=$featured): ${programs.length}',
        );
      }

      return programs;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('ContentRepository.getPrograms failed: $error');
      }
      rethrow;
    }
  }

  Future<List<ProgramLessonModel>> getProgramLessons(String programId) async {
    try {
      final response = await _api.get(ApiConfig.programLessons(programId));
      final lessons = ApiPayload.unwrapList(response.data)
          .map((json) => ProgramLessonModel.fromJson(json))
          .toList();

      if (kDebugMode) {
        debugPrint(
          'ContentRepository.getProgramLessons($programId): ${lessons.length}',
        );
      }

      return lessons;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('ContentRepository.getProgramLessons failed: $error');
      }
      rethrow;
    }
  }
}
