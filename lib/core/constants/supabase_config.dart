import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class SupabaseConfig {
  static const url = 'https://lljpwkhilumfdoznxeiq.supabase.co';
  static const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsanB3a2hpbHVtZmRvem54ZWlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2NDY1MDMsImV4cCI6MjA4OTIyMjUwM30.GPhpE5Jhdvr1cUVTCV-WPodrvSYn8_jgFgv61gmUgko';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
