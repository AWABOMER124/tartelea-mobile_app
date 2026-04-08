import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/api/api_payload.dart';
import '../models/content_model.dart';

class ContentRepository {
  final ApiClient _api;

  ContentRepository(this._api);

  Future<List<ContentModel>> getContents({
    String? category,
    bool? isSudanAwareness,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.contents,
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
          if (isSudanAwareness != null)
            'is_sudan_awareness': isSudanAwareness,
        },
      );

      return ApiPayload.unwrapList(response.data)
          .map((json) => ContentModel.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ContentModel?> getContentById(String id) async {
    try {
      final response = await _api.get('${ApiConfig.contentDetail}$id');
      return ContentModel.fromJson(ApiPayload.unwrapObject(response.data));
    } catch (_) {
      return null;
    }
  }
}
