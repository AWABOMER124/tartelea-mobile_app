import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_payload.dart';

class MediaRepository {
  final ApiClient _api;

  MediaRepository(this._api);

  Future<String> uploadBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
    });

    final response = await _api.post(
      '/media/upload',
      data: formData,
      contentType: 'multipart/form-data',
    );

    final payload = ApiPayload.unwrapObject(_asMap(response.data));
    final url = payload['url']?.toString() ?? '';
    if (url.isEmpty) {
      throw Exception('تعذر رفع الملف.');
    }
    return url;
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

