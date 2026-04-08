class AudioRoomModel {
  final String id;
  final String title;
  final String description;
  final String hostName;
  final String hostAvatar;
  final int listenerCount;
  final bool isLive;
  final String? imageUrl;
  final List<String> speakerIds;
  final DateTime? startedAt;
  final bool isRecording;
  final String? recordingUrl;

  AudioRoomModel({
    required this.id,
    required this.title,
    required this.description,
    required this.hostName,
    required this.hostAvatar,
    this.listenerCount = 0,
    this.isLive = false,
    this.imageUrl,
    this.speakerIds = const [],
    this.startedAt,
    this.isRecording = false,
    this.recordingUrl,
  });

  factory AudioRoomModel.fromJson(Map<String, dynamic> json) {
    return AudioRoomModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      hostName: json['host_name'] ?? json['hostName'] ?? 'مضيف الغرفة',
      hostAvatar: json['host_avatar'] ?? '',
      listenerCount: json['listener_count'] ?? json['participants_count'] ?? 0,
      isLive: json['is_live'] ?? (json['status'] == 'live'),
      imageUrl: json['image_url'],
      speakerIds: List<String>.from(json['speaker_ids'] ?? const []),
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'])
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null),
      isRecording: json['is_recording'] ?? false,
      recordingUrl: json['recording_url'],
    );
  }
}
