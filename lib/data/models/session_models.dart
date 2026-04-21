class SessionUserSummaryModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? roomRole;

  const SessionUserSummaryModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.roomRole,
  });

  factory SessionUserSummaryModel.fromJson(Map<String, dynamic>? json) {
    final payload = json ?? const <String, dynamic>{};

    return SessionUserSummaryModel(
      id: _asString(payload['id']),
      name: _asString(payload['name'], fallback: 'عضو المدرسة'),
      avatarUrl: _asNullableString(payload['avatar_url']),
      roomRole: _asNullableString(payload['room_role']),
    );
  }
}

class SessionAccessModel {
  final String roomRole;
  final bool isRegistered;
  final bool canJoin;
  final bool canListen;
  final bool canSpeak;
  final bool canModerate;
  final bool canPublish;
  final bool canPublishData;
  final bool canSubscribe;
  final bool canStartSession;
  final bool canEndSession;
  final bool canPromoteSpeaker;
  final bool canPromoteCoHost;
  final bool canPromoteModerator;
  final bool canKick;
  final String? denialReason;

  const SessionAccessModel({
    this.roomRole = 'guest',
    this.isRegistered = false,
    this.canJoin = false,
    this.canListen = false,
    this.canSpeak = false,
    this.canModerate = false,
    this.canPublish = false,
    this.canPublishData = false,
    this.canSubscribe = false,
    this.canStartSession = false,
    this.canEndSession = false,
    this.canPromoteSpeaker = false,
    this.canPromoteCoHost = false,
    this.canPromoteModerator = false,
    this.canKick = false,
    this.denialReason,
  });

  bool get isLiveSpeaker => canSpeak || canPublish;

  factory SessionAccessModel.fromJson(Map<String, dynamic>? json) {
    final payload = json ?? const <String, dynamic>{};

    return SessionAccessModel(
      roomRole: _asString(payload['room_role'], fallback: 'guest'),
      isRegistered: _asBool(payload['is_registered']),
      canJoin: _asBool(payload['canJoin']),
      canListen: _asBool(payload['canListen']),
      canSpeak: _asBool(payload['canSpeak']),
      canModerate: _asBool(payload['canModerate']),
      canPublish: _asBool(payload['canPublish']),
      canPublishData: _asBool(payload['canPublishData']),
      canSubscribe: _asBool(payload['canSubscribe']),
      canStartSession: _asBool(payload['canStartSession']),
      canEndSession: _asBool(payload['canEndSession']),
      canPromoteSpeaker: _asBool(payload['canPromoteSpeaker']),
      canPromoteCoHost: _asBool(payload['canPromoteCoHost']),
      canPromoteModerator: _asBool(payload['canPromoteModerator']),
      canKick: _asBool(payload['canKick']),
      denialReason: _asNullableString(payload['denialReason']),
    );
  }
}

class SessionContractModel {
  final String id;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final DateTime? actualStartedAt;
  final String status;
  final String visibility;
  final String category;
  final String? imageUrl;
  final double price;
  final List<SessionUserSummaryModel> speakers;

  const SessionContractModel({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledAt,
    this.actualStartedAt,
    required this.status,
    required this.visibility,
    required this.category,
    this.imageUrl,
    this.price = 0,
    this.speakers = const [],
  });

  bool get isLive => status == 'live';
  bool get isEnded => status == 'ended';

  factory SessionContractModel.fromJson(Map<String, dynamic> json) {
    return SessionContractModel(
      id: _asString(json['id']),
      title: _asString(json['title'], fallback: 'جلسة صوتية'),
      description: _asNullableString(json['description']),
      scheduledAt: _asDateTime(json['scheduled_at']),
      actualStartedAt: _asNullableDateTime(json['actual_started_at']),
      status: _asString(json['status'], fallback: 'scheduled'),
      visibility: _asString(json['visibility'], fallback: 'public'),
      category: _asString(json['category'], fallback: 'community'),
      imageUrl: _asNullableString(json['image_url']),
      price: _asDouble(json['price']),
      speakers: _asList(json['speakers'])
          .map((item) => SessionUserSummaryModel.fromJson(_asMap(item)))
          .toList(),
    );
  }
}

class SessionRoomModel {
  final String roomId;
  final String sessionId;
  final String roomType;
  final String hostId;
  final SessionUserSummaryModel host;
  final List<SessionUserSummaryModel> speakers;
  final List<SessionUserSummaryModel> moderators;
  final bool allowListeners;
  final int maxParticipants;
  final int participantCount;

  const SessionRoomModel({
    required this.roomId,
    required this.sessionId,
    required this.roomType,
    required this.hostId,
    required this.host,
    this.speakers = const [],
    this.moderators = const [],
    this.allowListeners = true,
    this.maxParticipants = 50,
    this.participantCount = 0,
  });

  factory SessionRoomModel.fromJson(Map<String, dynamic> json) {
    return SessionRoomModel(
      roomId: _asString(json['room_id']),
      sessionId: _asString(json['session_id']),
      roomType: _asString(json['room_type'], fallback: 'stage'),
      hostId: _asString(json['host_id']),
      host: SessionUserSummaryModel.fromJson(_asMap(json['host'])),
      speakers: _asList(json['speakers'])
          .map((item) => SessionUserSummaryModel.fromJson(_asMap(item)))
          .toList(),
      moderators: _asList(json['moderators'])
          .map((item) => SessionUserSummaryModel.fromJson(_asMap(item)))
          .toList(),
      allowListeners: _asBool(json['allow_listeners'], fallback: true),
      maxParticipants: _asInt(json['max_participants'], fallback: 50),
      participantCount: _asInt(json['participant_count']),
    );
  }
}

class SessionParticipantModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final String roomRole;
  final bool isHost;
  final bool isPresent;
  final bool hasRaisedHand;
  final DateTime? joinedAt;

  const SessionParticipantModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    required this.roomRole,
    this.isHost = false,
    this.isPresent = false,
    this.hasRaisedHand = false,
    this.joinedAt,
  });

  bool get canSpeak =>
      const {'host', 'co_host', 'moderator', 'speaker'}.contains(roomRole);

  factory SessionParticipantModel.fromJson(Map<String, dynamic> json) {
    return SessionParticipantModel(
      id: _asString(json['id']),
      name: _asString(json['name'], fallback: 'عضو المدرسة'),
      avatarUrl: _asNullableString(json['avatar_url']),
      bio: _asNullableString(json['bio']),
      roomRole: _asString(json['room_role'], fallback: 'listener'),
      isHost: _asBool(json['is_host']),
      isPresent: _asBool(json['is_present']),
      hasRaisedHand: _asBool(json['has_raised_hand']),
      joinedAt: _asNullableDateTime(json['joined_at']),
    );
  }
}

class SessionHandRaiseModel {
  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;

  const SessionHandRaiseModel({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  factory SessionHandRaiseModel.fromJson(Map<String, dynamic> json) {
    return SessionHandRaiseModel(
      id: _asString(json['id']),
      userId: _asString(json['user_id']),
      name: _asString(json['name'], fallback: 'عضو المدرسة'),
      avatarUrl: _asNullableString(json['avatar_url']),
      createdAt: _asDateTime(json['created_at']),
    );
  }
}

class SessionListItemModel {
  final SessionContractModel session;
  final SessionRoomModel room;
  final SessionAccessModel access;

  const SessionListItemModel({
    required this.session,
    required this.room,
    required this.access,
  });

  bool get isLive => session.isLive;
  bool get isScheduled => session.status == 'scheduled';
  bool get isEnded => session.isEnded;

  factory SessionListItemModel.fromJson(Map<String, dynamic> json) {
    return SessionListItemModel(
      session: SessionContractModel.fromJson(_asMap(json['session'])),
      room: SessionRoomModel.fromJson(_asMap(json['room'])),
      access: SessionAccessModel.fromJson(_asMap(json['access'])),
    );
  }
}

class SessionDetailsModel {
  final SessionContractModel session;
  final SessionRoomModel room;
  final SessionAccessModel access;
  final List<SessionParticipantModel> participants;
  final List<SessionHandRaiseModel> handRaises;

  const SessionDetailsModel({
    required this.session,
    required this.room,
    required this.access,
    this.participants = const [],
    this.handRaises = const [],
  });

  SessionParticipantModel? participantById(String userId) {
    for (final participant in participants) {
      if (participant.id == userId) {
        return participant;
      }
    }
    return null;
  }

  factory SessionDetailsModel.fromJson(Map<String, dynamic> json) {
    return SessionDetailsModel(
      session: SessionContractModel.fromJson(_asMap(json['session'])),
      room: SessionRoomModel.fromJson(_asMap(json['room'])),
      access: SessionAccessModel.fromJson(_asMap(json['access'])),
      participants: _asList(json['participants'])
          .map((item) => SessionParticipantModel.fromJson(_asMap(item)))
          .toList(),
      handRaises: _asList(json['hand_raises'])
          .map((item) => SessionHandRaiseModel.fromJson(_asMap(item)))
          .toList(),
    );
  }
}

class SessionJoinResultModel {
  final SessionContractModel session;
  final SessionRoomModel room;
  final SessionAccessModel access;
  final String? token;

  const SessionJoinResultModel({
    required this.session,
    required this.room,
    required this.access,
    this.token,
  });

  factory SessionJoinResultModel.fromJson(Map<String, dynamic> json) {
    return SessionJoinResultModel(
      session: SessionContractModel.fromJson(_asMap(json['session'])),
      room: SessionRoomModel.fromJson(_asMap(json['room'])),
      access: SessionAccessModel.fromJson(_asMap(json['access'])),
      token: _asNullableString(json['token']),
    );
  }
}

class LivekitTokenModel {
  final String token;
  final String url;
  final bool canPublish;
  final String role;

  const LivekitTokenModel({
    required this.token,
    required this.url,
    required this.canPublish,
    required this.role,
  });

  factory LivekitTokenModel.fromJson(Map<String, dynamic> json) {
    return LivekitTokenModel(
      token: _asString(json['token']),
      url: _asString(json['url']),
      canPublish: _asBool(json['canPublish']),
      role: _asString(json['role'], fallback: 'listener'),
    );
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
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
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

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
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
