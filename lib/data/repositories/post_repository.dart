import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

class PostRepository {
  final SupabaseClient _supabase;

  PostRepository(this._supabase);

  Future<List<PostModel>> getPosts({String? category}) async {
    try {
      var query = _supabase.from('posts').select();
      
      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<PostModel?> createPost({
    required String title,
    String? body,
    required String category,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      final response = await _supabase.from('posts').insert({
        'author_id': user.id,
        'title': title,
        'body': body,
        'category': category,
      }).select().single();

      return PostModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> likePost(String postId) async {
    // Basic implementation for now
    debugPrint('Liking post: $postId');
  }

  Future<void> addComment(String postId, String text) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      await _supabase.from('comments').insert({
        'post_id': postId,
        'user_id': user.id,
        'content': text,
      });
    } catch (e) {
      // Handle error
    }
  }
}
