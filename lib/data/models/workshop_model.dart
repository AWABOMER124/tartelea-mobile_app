class WorkshopModel {
  final String id;
  final String title;
  final String? description;
  final String trainerId;
  final String? category;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String? imageUrl;
  final bool isLive;
  final double price;
  final int maxParticipants;

  WorkshopModel({
    required this.id,
    required this.title,
    this.description,
    required this.trainerId,
    this.category,
    this.scheduledAt,
    this.durationMinutes = 60,
    this.imageUrl,
    this.isLive = false,
    this.price = 0.0,
    this.maxParticipants = 100,
  });

  factory WorkshopModel.fromJson(Map<String, dynamic> json) {
    return WorkshopModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      trainerId: json['trainer_id'] as String? ?? '',
      category: json['category'] as String?,
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String) : null,
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      imageUrl: json['image_url'] as String?,
      isLive: json['is_live'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      maxParticipants: json['max_participants'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'trainer_id': trainerId,
      'category': category,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'image_url': imageUrl,
      'is_live': isLive,
      'price': price,
      'max_participants': maxParticipants,
    };
  }
}
