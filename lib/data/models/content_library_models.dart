class ContentCategoryRef {
  final String id;
  final String? title;
  final String? slug;

  const ContentCategoryRef({
    required this.id,
    this.title,
    this.slug,
  });

  factory ContentCategoryRef.fromJson(Map<String, dynamic> json) {
    return ContentCategoryRef(
      id: json['id']?.toString() ?? '',
      title: json['title'],
      slug: json['slug'],
    );
  }
}

class ContentTrackRef {
  final String id;
  final String? title;
  final String? slug;

  const ContentTrackRef({
    required this.id,
    this.title,
    this.slug,
  });

  factory ContentTrackRef.fromJson(Map<String, dynamic> json) {
    return ContentTrackRef(
      id: json['id']?.toString() ?? '',
      title: json['title'],
      slug: json['slug'],
    );
  }
}

class ContentCategoryModel {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final int sortOrder;
  final bool isActive;

  const ContentCategoryModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory ContentCategoryModel.fromJson(Map<String, dynamic> json) {
    return ContentCategoryModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      sortOrder: json['sort_order'] is int
          ? json['sort_order']
          : int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class ContentTrackModel {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final ContentCategoryRef? category;

  const ContentTrackModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.sortOrder = 0,
    this.isActive = true,
    this.category,
  });

  factory ContentTrackModel.fromJson(Map<String, dynamic> json) {
    return ContentTrackModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      sortOrder: json['sort_order'] is int
          ? json['sort_order']
          : int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      isActive: json['is_active'] ?? true,
      category: json['category'] is Map<String, dynamic>
          ? ContentCategoryRef.fromJson(json['category'])
          : null,
    );
  }
}

class LibraryItemModel {
  final String id;
  final String title;
  final String? slug;
  final String? description;
  final String contentType;
  final ContentCategoryRef? category;
  final ContentTrackRef? track;
  final String? thumbnailPath;
  final String? coverImagePath;
  final String? mediaUrl;
  final String? fileUrl;
  final int? durationSeconds;
  final String? authorName;
  final String requiredPlanCode;
  final bool isFeatured;
  final int sortOrder;
  final DateTime? publishedAt;
  final bool isLocked;

  const LibraryItemModel({
    required this.id,
    required this.title,
    this.slug,
    this.description,
    required this.contentType,
    this.category,
    this.track,
    this.thumbnailPath,
    this.coverImagePath,
    this.mediaUrl,
    this.fileUrl,
    this.durationSeconds,
    this.authorName,
    this.requiredPlanCode = 'free',
    this.isFeatured = false,
    this.sortOrder = 0,
    this.publishedAt,
    this.isLocked = false,
  });

  factory LibraryItemModel.fromJson(Map<String, dynamic> json) {
    return LibraryItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      slug: json['slug'],
      description: json['description'],
      contentType: json['content_type'] ?? 'article',
      category: json['category'] is Map<String, dynamic>
          ? ContentCategoryRef.fromJson(json['category'])
          : null,
      track: json['track'] is Map<String, dynamic>
          ? ContentTrackRef.fromJson(json['track'])
          : null,
      thumbnailPath: json['thumbnail_url'],
      coverImagePath: json['cover_image_url'],
      mediaUrl: json['media_url'],
      fileUrl: json['file_url'],
      durationSeconds: json['duration_seconds'] is int
          ? json['duration_seconds']
          : int.tryParse(json['duration_seconds']?.toString() ?? ''),
      authorName: json['author_name'],
      requiredPlanCode: json['required_plan_code'] ?? 'free',
      isFeatured: json['is_featured'] ?? false,
      sortOrder: json['sort_order'] is int
          ? json['sort_order']
          : int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())
          : null,
      isLocked: json['is_locked'] ?? false,
    );
  }
}

class ProgramModel {
  final String id;
  final String title;
  final String? slug;
  final String? description;
  final ContentCategoryRef? category;
  final ContentTrackRef? track;
  final String? thumbnailPath;
  final String requiredPlanCode;
  final bool isFeatured;
  final int sortOrder;
  final bool isLocked;

  const ProgramModel({
    required this.id,
    required this.title,
    this.slug,
    this.description,
    this.category,
    this.track,
    this.thumbnailPath,
    this.requiredPlanCode = 'free',
    this.isFeatured = false,
    this.sortOrder = 0,
    this.isLocked = false,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      slug: json['slug'],
      description: json['description'],
      category: json['category'] is Map<String, dynamic>
          ? ContentCategoryRef.fromJson(json['category'])
          : null,
      track: json['track'] is Map<String, dynamic>
          ? ContentTrackRef.fromJson(json['track'])
          : null,
      thumbnailPath: json['thumbnail_url'],
      requiredPlanCode: json['required_plan_code'] ?? 'free',
      isFeatured: json['is_featured'] ?? false,
      sortOrder: json['sort_order'] is int
          ? json['sort_order']
          : int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      isLocked: json['is_locked'] ?? false,
    );
  }
}

class ProgramLessonModel {
  final String id;
  final String? programId;
  final String title;
  final String? slug;
  final String? description;
  final String? lessonType;
  final int sortOrder;
  final String? mediaUrl;
  final String? fileUrl;
  final String requiredPlanCode;
  final bool isLocked;

  const ProgramLessonModel({
    required this.id,
    required this.title,
    this.programId,
    this.slug,
    this.description,
    this.lessonType,
    this.sortOrder = 0,
    this.mediaUrl,
    this.fileUrl,
    this.requiredPlanCode = 'free',
    this.isLocked = false,
  });

  factory ProgramLessonModel.fromJson(Map<String, dynamic> json) {
    return ProgramLessonModel(
      id: json['id']?.toString() ?? '',
      programId: json['program_id']?.toString(),
      title: json['title'] ?? '',
      slug: json['slug'],
      description: json['description'],
      lessonType: json['lesson_type'],
      sortOrder: json['sort_order'] is int
          ? json['sort_order']
          : int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      mediaUrl: json['media_url'],
      fileUrl: json['file_url'],
      requiredPlanCode: json['required_plan_code'] ?? 'free',
      isLocked: json['is_locked'] ?? false,
    );
  }
}

class FeaturedBannerModel {
  final String id;
  final String title;
  final String? imagePath;
  final String? link;
  final String? type;

  const FeaturedBannerModel({
    required this.id,
    required this.title,
    this.imagePath,
    this.link,
    this.type,
  });

  factory FeaturedBannerModel.fromJson(Map<String, dynamic> json) {
    return FeaturedBannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      imagePath: json['image_url'],
      link: json['link'],
      type: json['type'],
    );
  }
}

class ContentFeaturedResponse {
  final List<FeaturedBannerModel> banners;
  final List<LibraryItemModel> featuredLibraryItems;
  final List<ProgramModel> featuredPrograms;

  const ContentFeaturedResponse({
    this.banners = const [],
    this.featuredLibraryItems = const [],
    this.featuredPrograms = const [],
  });

  factory ContentFeaturedResponse.fromJson(Map<String, dynamic> json) {
    final banners = (json['banners'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FeaturedBannerModel.fromJson)
        .toList();
    final featuredLibraryItems = (json['featured_library_items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LibraryItemModel.fromJson)
        .toList();
    final featuredPrograms = (json['featured_programs'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProgramModel.fromJson)
        .toList();

    return ContentFeaturedResponse(
      banners: banners,
      featuredLibraryItems: featuredLibraryItems,
      featuredPrograms: featuredPrograms,
    );
  }
}

