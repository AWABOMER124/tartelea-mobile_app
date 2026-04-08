enum ContentCategory {
  tahliya,
  takhliya,
  tajalli,
  psychological,
  sudan,
  general,
}

enum ContentType {
  video,
  audio,
  article,
}

class ContentItem {
  final String id;
  final String title;
  final String? description;
  final ContentCategory category;
  final ContentType type;
  final String? externalUrl;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? duration;
  final bool isSudanAwareness;
  final DateTime? createdAt;

  ContentItem({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.type,
    this.externalUrl,
    this.mediaUrl,
    this.thumbnailUrl,
    this.duration,
    this.isSudanAwareness = false,
    this.createdAt,
  });
}
