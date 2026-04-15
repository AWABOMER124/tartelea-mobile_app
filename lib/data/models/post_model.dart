class PostModel {
  final String id;
  final String authorId;
  final String title;
  final String? body;
  final String category;
  final String? authorName;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.title,
    this.body,
    required this.category,
    this.authorName,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'],
      category: json['category'] ?? 'general',
      authorName: json['author_name']?.toString(),
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
      'author_name': authorName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
