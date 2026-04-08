class PostModel {
  final String id;
  final String authorId;
  final String title;
  final String? body;
  final String category;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.title,
    this.body,
    required this.category,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'],
      category: json['category'] ?? 'general',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'title': title,
      'body': body,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
