import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/api/api_payload.dart';
import '../models/session_models.dart';

class SessionRepository {
  final ApiClient _api;

  SessionRepository(this._api);

  Future<List<SessionListItemModel>> listSessions({String? status}) async {
    try {
      final response = await _api.get(
        ApiConfig.sessions,
        queryParameters: {
          if (status != null && status.isNotEmpty && status != 'all') 'status': status,
          'limit': 50,
          'offset': 0,
        },
      );

      final items = ApiPayload.unwrapList(
        _asMap(response.data),
        preferredKeys: const ['items'],
      );

      return items
          .map((item) => SessionListItemModel.fromJson(_asMap(item)))
          .toList();
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تحميل الجلسات الصوتية.'));
    }
  }

  Future<SessionJoinResultModel> createSession({
    required String title,
    String? description,
    String category = 'community',
    DateTime? scheduledAt,
    int durationMinutes = 30,
    int maxParticipants = 50,
    String accessType = 'public',
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.sessions,
        data: {
          'title': title,
          'description': description,
          'category': category,
          'scheduled_at':
              (scheduledAt ?? DateTime.now()).toUtc().toIso8601String(),
          'duration_minutes': durationMinutes,
          'max_participants': maxParticipants,
          'access_type': accessType,
        },
      );

      return SessionJoinResultModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر إنشاء الجلسة الصوتية.'));
    }
  }

  Future<SessionDetailsModel> getSessionDetails(String sessionId) async {
    try {
      final response = await _api.get('${ApiConfig.sessions}/$sessionId');
      return SessionDetailsModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تحميل تفاصيل الجلسة.'));
    }
  }

  Future<SessionJoinResultModel> joinSession(String sessionId) async {
    try {
      final response = await _api.post('${ApiConfig.sessions}/$sessionId/join');
      return SessionJoinResultModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تجهيز دخول الجلسة.'));
    }
  }

  Future<SessionJoinResultModel> leaveSession(String sessionId) async {
    try {
      final response = await _api.post('${ApiConfig.sessions}/$sessionId/leave');
      return SessionJoinResultModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تحديث حالة الانضمام.'));
    }
  }

  Future<SessionDetailsModel> applyAction({
    required String sessionId,
    required String action,
    String? targetUserId,
  }) async {
    try {
      final response = await _api.post(
        '${ApiConfig.sessions}/$sessionId/actions',
        data: {
          'action': action,
          if (targetUserId != null && targetUserId.isNotEmpty)
            'target_user_id': targetUserId,
        },
      );

      return SessionDetailsModel.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تنفيذ الإجراء داخل الجلسة.'));
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

String _messageFromError(DioException error, String fallback) {
  final data = _asMap(error.response?.data);
  final rootMessage = data['message']?.toString().trim();
  final nestedMessage = _asMap(data['error'])['message']?.toString().trim();

  if (nestedMessage != null && nestedMessage.isNotEmpty) {
    return nestedMessage;
  }
  if (rootMessage != null && rootMessage.isNotEmpty) {
    return rootMessage;
  }
  return error.message ?? fallback;
}
