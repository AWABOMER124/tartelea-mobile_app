class ContentModel {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String type;
  final String? url;
  final bool isSudanAwareness;
  final DateTime? createdAt;

  ContentModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.type,
    this.url,
    this.isSudanAwareness = false,
    this.createdAt,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'general',
      type: json['type'] ?? 'article',
      url: json['url'],
      isSudanAwareness: json['is_sudan_awareness'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'url': url,
      'is_sudan_awareness': isSudanAwareness,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
