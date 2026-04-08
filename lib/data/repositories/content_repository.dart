import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/content_model.dart';

class ContentRepository {
  final SupabaseClient _supabase;

  ContentRepository(this._supabase);

  Future<List<ContentModel>> getContents({
    String? category,
    bool? isSudanAwareness,
  }) async {
    try {
      var query = _supabase.from('contents').select();

      if (category != null) {
        query = query.eq('category', category);
      }
      if (isSudanAwareness != null) {
        query = query.eq('is_sudan_awareness', isSudanAwareness);
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => ContentModel.fromJson(json))
          .toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  Future<ContentModel?> getContentById(String id) async {
    try {
      final response = await _supabase
          .from('contents')
          .select()
          .eq('id', id)
          .single();
      
      return ContentModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
