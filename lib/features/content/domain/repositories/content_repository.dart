import '../entities/content_item.dart';

abstract class ContentRepository {
  Future<List<ContentItem>> getContents({
    ContentCategory? category,
    ContentType? type,
    bool? isSudanAwareness,
  });

  Future<ContentItem> getContentById(String id);

  Future<List<ContentItem>> searchContents(String query);

  Future<bool> hasCachedContents();

  Future<void> clearCache();
}
