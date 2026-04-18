class CommunityContextModel {
  final String id;
  final String type;
  final String sourceSystem;
  final String sourceId;
  final String slug;
  final String title;
  final String? subtitle;
  final String? description;
  final String visibility;
  final bool isActive;

  const CommunityContextModel({
    required this.id,
    required this.type,
    required this.sourceSystem,
    required this.sourceId,
    required this.slug,
    required this.title,
    this.subtitle,
    this.description,
    required this.visibility,
    required this.isActive,
  });

  factory CommunityContextModel.fromJson(Map<String, dynamic> json) {
    return CommunityContextModel(
      id: _asString(json['id']),
      type: _asString(json['type'], fallback: 'general'),
      sourceSystem: _asString(json['source_system']),
      sourceId: _asString(json['source_id']),
      slug: _asString(json['slug']),
      title: _asString(json['title'], fallback: 'المجتمع'),
      subtitle: _asNullableString(json['subtitle']),
      description: _asNullableString(json['description']),
      visibility: _asString(json['visibility'], fallback: 'authenticated'),
      isActive: _asBool(json['is_active'], fallback: true),
    );
  }
}

class CommunityAuthorModel {
  final String id;
  final String name;
  final String? avatarUrl;

  const CommunityAuthorModel({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory CommunityAuthorModel.fromJson(Map<String, dynamic>? json) {
    final payload = json ?? const <String, dynamic>{};

    return CommunityAuthorModel(
      id: _asString(payload['id']),
      name: _asString(payload['name'], fallback: 'عضو المدرسة'),
      avatarUrl: _asNullableString(payload['avatar_url']),
    );
  }
}

class CommunityCountsModel {
  final int comments;
  final int reactions;
  final int attachments;
  final int replies;

  const CommunityCountsModel({
    this.comments = 0,
    this.reactions = 0,
    this.attachments = 0,
    this.replies = 0,
  });

  factory CommunityCountsModel.fromJson(Map<String, dynamic>? json) {
    final payload = json ?? const <String, dynamic>{};

    return CommunityCountsModel(
      comments: _asInt(payload['comments']),
      reactions: _asInt(payload['reactions']),
      attachments: _asInt(payload['attachments']),
      replies: _asInt(payload['replies']),
    );
  }
}

class CommunityViewerStateModel {
  final bool liked;
  final bool canComment;
  final bool canReply;
  final bool canModerate;
  final bool canManage;

  const CommunityViewerStateModel({
    this.liked = false,
    this.canComment = false,
    this.canReply = false,
    this.canModerate = false,
    this.canManage = false,
  });

  factory CommunityViewerStateModel.fromJson(Map<String, dynamic>? json) {
    final payload = json ?? const <String, dynamic>{};

    return CommunityViewerStateModel(
      liked: _asBool(payload['liked']),
      canComment: _asBool(payload['can_comment']),
      canReply: _asBool(payload['can_reply']),
      canModerate: _asBool(payload['can_moderate']),
      canManage: _asBool(payload['can_manage']),
    );
  }
}

class CommunityCommentModel {
  final String id;
  final String postId;
  final String? parentCommentId;
  final int depth;
  final String body;
  final String status;
  final CommunityAuthorModel author;
  final CommunityCountsModel counts;
  final CommunityViewerStateModel viewerState;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? editedAt;
  final List<CommunityCommentModel> replies;

  const CommunityCommentModel({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.depth,
    required this.body,
    required this.status,
    required this.author,
    required this.counts,
    required this.viewerState,
    required this.createdAt,
    this.updatedAt,
    this.editedAt,
    this.replies = const [],
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    return CommunityCommentModel(
      id: _asString(json['id']),
      postId: _asString(json['post_id']),
      parentCommentId: _asNullableString(json['parent_comment_id']),
      depth: _asInt(json['depth']),
      body: _asString(json['body']),
      status: _asString(json['status'], fallback: 'published'),
      author: CommunityAuthorModel.fromJson(_asMapOrNull(json['author'])),
      counts: CommunityCountsModel.fromJson(_asMapOrNull(json['counts'])),
      viewerState: CommunityViewerStateModel.fromJson(_asMapOrNull(json['viewer_state'])),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asNullableDateTime(json['updated_at']),
      editedAt: _asNullableDateTime(json['edited_at']),
      replies: _asList(json['replies'])
          .map((item) => CommunityCommentModel.fromJson(_asMap(item)))
          .toList(),
    );
  }
}

class CommunityPostModel {
  final String id;
  final String kind;
  final String? title;
  final String body;
  final String status;
  final bool isLocked;
  final CommunityContextModel primaryContext;
  final CommunityAuthorModel author;
  final CommunityCountsModel counts;
  final CommunityViewerStateModel viewerState;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActivityAt;
  final DateTime? editedAt;
  final List<CommunityContextModel> scopes;
  final List<CommunityCommentModel> comments;
  final String? pinId;
  final int? pinSortOrder;
  final DateTime? pinEndsAt;

  const CommunityPostModel({
    required this.id,
    required this.kind,
    this.title,
    required this.body,
    required this.status,
    required this.isLocked,
    required this.primaryContext,
    required this.author,
    required this.counts,
    required this.viewerState,
    required this.createdAt,
    this.updatedAt,
    this.lastActivityAt,
    this.editedAt,
    this.scopes = const [],
    this.comments = const [],
    this.pinId,
    this.pinSortOrder,
    this.pinEndsAt,
  });

  bool get isPinned => pinId != null && pinId!.isNotEmpty;

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: _asString(json['id']),
      kind: _asString(json['kind'], fallback: 'discussion'),
      title: _asNullableString(json['title']),
      body: _asString(json['body']),
      status: _asString(json['status'], fallback: 'published'),
      isLocked: _asBool(json['is_locked']),
      primaryContext: CommunityContextModel.fromJson(
        _asMap(json['primary_context']),
      ),
      author: CommunityAuthorModel.fromJson(_asMapOrNull(json['author'])),
      counts: CommunityCountsModel.fromJson(_asMapOrNull(json['counts'])),
      viewerState: CommunityViewerStateModel.fromJson(_asMapOrNull(json['viewer_state'])),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asNullableDateTime(json['updated_at']),
      lastActivityAt: _asNullableDateTime(json['last_activity_at']),
      editedAt: _asNullableDateTime(json['edited_at']),
      scopes: _asList(json['scopes'])
          .map((item) => CommunityContextModel.fromJson(_asMap(item)))
          .toList(),
      comments: _asList(json['comments'])
          .map((item) => CommunityCommentModel.fromJson(_asMap(item)))
          .toList(),
      pinId: _asNullableString(_asMapOrNull(json['pin'])?['id']),
      pinSortOrder: _asNullableInt(_asMapOrNull(json['pin'])?['sort_order']),
      pinEndsAt: _asNullableDateTime(_asMapOrNull(json['pin'])?['ends_at']),
    );
  }
}

class CommunityFeedModel {
  final List<CommunityPostModel> pinnedItems;
  final List<CommunityPostModel> items;
  final String? nextCursor;

  const CommunityFeedModel({
    this.pinnedItems = const [],
    this.items = const [],
    this.nextCursor,
  });

  factory CommunityFeedModel.fromJson(Map<String, dynamic> json) {
    return CommunityFeedModel(
      pinnedItems: _asList(json['pinned_items'])
          .map((item) => CommunityPostModel.fromJson(_asMap(item)))
          .toList(),
      items: _asList(json['items'])
          .map((item) => CommunityPostModel.fromJson(_asMap(item)))
          .toList(),
      nextCursor: _asNullableString(json['next_cursor']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }
  return <String, dynamic>{};
}

Map<String, dynamic>? _asMapOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  final mapped = _asMap(value);
  return mapped.isEmpty ? null : mapped;
}

List<dynamic> _asList(dynamic value) {
  return value is List ? value : const [];
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  final normalized = value.toString().trim();
  return normalized.isEmpty ? fallback : normalized;
}

String? _asNullableString(dynamic value) {
  if (value == null) {
    return null;
  }

  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return fallback;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  return _asInt(value);
}

DateTime _asDateTime(dynamic value) {
  return _asNullableDateTime(value) ?? DateTime.now();
}

DateTime? _asNullableDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
