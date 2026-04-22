import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../models/notification_model.dart';

class NotificationsRepository {
  final ApiClient _api;

  NotificationsRepository(this._api);

  Future<List<NotificationModel>> list({int limit = 50}) async {
    try {
      final response = await _api.post(
        '/compat/query',
        data: {
          'table': 'notifications',
          'operation': 'select',
          'order': [
            {'column': 'created_at', 'ascending': false},
          ],
          'limit': limit,
          'offset': 0,
        },
      );

      final root = _asMap(response.data);
      final data = root['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((row) => row.map((k, v) => MapEntry(k.toString(), v)))
            .map(NotificationModel.fromMap)
            .toList();
      }

      return const [];
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تحميل الإشعارات.'));
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _api.post(
        '/compat/query',
        data: {
          'table': 'notifications',
          'operation': 'update',
          'payload': {'is_read': true},
          'filters': [
            {'column': 'id', 'operator': 'eq', 'value': notificationId},
          ],
          'maybeSingle': true,
        },
      );
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تحديث حالة الإشعار.'));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.post(
        '/compat/query',
        data: {
          'table': 'notifications',
          'operation': 'update',
          'payload': {'is_read': true},
          'filters': [
            {'column': 'is_read', 'operator': 'eq', 'value': false},
          ],
        },
      );
    } on DioException catch (error) {
      throw Exception(_messageFromError(error, 'تعذر تحديث الإشعارات.'));
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

