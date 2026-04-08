// lib/features/content/data/repositories/content_repository_impl.dart
//
// تنفيذ مستودع المحتوى — يجلب من API أولاً، ثم يخزّن محلياً
// ──────────────────────────────────────────────────────────────
// الاستراتيجية: Cache-First with Network Refresh
//   1. نعرض المحتوى المخزّن فوراً (سرعة)
//   2. نجلب من الـ API في الخلفية ونحدّث
//   3. إذا لا يوجد cache ولا API → نعرض mock

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_config.dart';
import '../../../../core/api/api_payload.dart';
import '../../domain/entities/content_item.dart';
import '../../domain/repositories/content_repository.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ApiClient _api;
  static const _cacheKey = 'cached_contents';
  static const _cacheTimestampKey = 'cache_ts_contents';
  static const _cacheDuration = Duration(hours: 2);

  ContentRepositoryImpl(this._api);

  @override
  Future<List<ContentItem>> getContents({
    ContentCategory? category,
    ContentType? type,
    bool? isSudanAwareness,
  }) async {
    try {
      // محاولة جلب من API
      final queryParameters = <String, dynamic>{};
      if (category != null) queryParameters['category'] = category.name;
      if (isSudanAwareness != null) {
        queryParameters['is_sudan_awareness'] = isSudanAwareness;
      }
      final response = await _api.get(ApiConfig.contents, queryParameters: queryParameters);

      final items = ApiPayload.unwrapList(response.data)
          .map((json) => _mapJsonToContentItem(json))
          .toList();

      // حفظ في الـ Cache
      await _saveToCache(items);

      return _applyFilters(items, category: category, type: type, isSudanAwareness: isSudanAwareness);
    } catch (_) {
      // Fallback: Cache أولاً
      final cached = await _loadFromCache();
      if (cached.isNotEmpty) {
        return _applyFilters(cached, category: category, type: type, isSudanAwareness: isSudanAwareness);
      }
      // Fallback أخير: Mock data
      return _applyFilters(_getMockContents(), category: category, type: type, isSudanAwareness: isSudanAwareness);
    }
  }

  @override
  Future<ContentItem> getContentById(String id) async {
    try {
      final response = await _api.get('${ApiConfig.contentDetail}$id');
      return _mapJsonToContentItem(ApiPayload.unwrapObject(response.data));
    } catch (_) {
      // بحث في الـ Cache
      final cached = await _loadFromCache();
      return cached.firstWhere((c) => c.id == id, orElse: () => _getMockContents().first);
    }
  }

  @override
  Future<List<ContentItem>> searchContents(String query) async {
    final allContents = await getContents();
    final q = query.toLowerCase();
    return allContents.where((c) =>
      c.title.toLowerCase().contains(q) ||
      (c.description?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  @override
  Future<bool> hasCachedContents() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_cacheTimestampKey);
    if (ts == null) return false;
    final cached = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(cached) < _cacheDuration;
  }

  @override
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }

  // ─── Cache Helpers ────────────────────────────────────────

  Future<void> _saveToCache(List<ContentItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => {
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'category': item.category.name,
      'type': item.type.name,
      'externalUrl': item.externalUrl,
      'mediaUrl': item.mediaUrl,
      'thumbnailUrl': item.thumbnailUrl,
      'duration': item.duration,
      'isSudanAwareness': item.isSudanAwareness,
      'createdAt': item.createdAt?.toIso8601String(),
    }).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonList));
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<ContentItem>> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];

    final jsonList = jsonDecode(raw) as List;
    return jsonList.map((json) => ContentItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: _parseCategory(json['category']),
      type: _parseType(json['type']),
      externalUrl: json['externalUrl'],
      mediaUrl: json['mediaUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],
      isSudanAwareness: json['isSudanAwareness'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    )).toList();
  }

  // ─── Mappers ──────────────────────────────────────────────

  ContentItem _mapJsonToContentItem(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: _parseCategory(json['category']),
      type: _parseType(json['type']),
      externalUrl: json['url'],
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      duration: json['duration'],
      isSudanAwareness: json['is_sudan_awareness'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  static ContentCategory _parseCategory(String? value) {
    return switch (value) {
      'tahliya' => ContentCategory.tahliya,
      'takhliya' => ContentCategory.takhliya,
      'tajalli' => ContentCategory.tajalli,
      'psychological' => ContentCategory.psychological,
      'sudan' => ContentCategory.sudan,
      _ => ContentCategory.general,
    };
  }

  static ContentType _parseType(String? value) {
    return switch (value) {
      'video' => ContentType.video,
      'audio' => ContentType.audio,
      _ => ContentType.article,
    };
  }

  List<ContentItem> _applyFilters(
    List<ContentItem> items, {
    ContentCategory? category,
    ContentType? type,
    bool? isSudanAwareness,
  }) {
    var result = items;
    if (category != null) result = result.where((c) => c.category == category).toList();
    if (type != null) result = result.where((c) => c.type == type).toList();
    if (isSudanAwareness == true) result = result.where((c) => c.isSudanAwareness).toList();
    return result;
  }

  // ─── Mock Data ────────────────────────────────────────────

  List<ContentItem> _getMockContents() {
    return [
      ContentItem(
        id: 'mock-1',
        title: 'أساسيات اللسان العربي - فيديو',
        description: 'درس مرئي يشرح المفاهيم الأساسية لبداية رحلة التدبر.',
        category: ContentCategory.tahliya,
        type: ContentType.video,
        mediaUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        thumbnailUrl: 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?q=80&w=2070',
        duration: '09:56',
      ),
      ContentItem(
        id: 'mock-2',
        title: 'تدبر سورة الفاتحة - صوتي',
        description: 'تحليل صوتي لعمق معاني أم الكتاب والجذور اللغوية.',
        category: ContentCategory.tahliya,
        type: ContentType.audio,
        mediaUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        thumbnailUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=2070',
        duration: '06:12',
      ),
      ContentItem(
        id: 'mock-3',
        title: 'مفهوم التزكية',
        description: 'مقالة تشرح مفهوم التزكية في ضوء المدرسة الترتيلية.',
        category: ContentCategory.takhliya,
        type: ContentType.article,
        thumbnailUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=1999',
      ),
    ];
  }
}
