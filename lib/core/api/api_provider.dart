import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'api_config.dart';

// Provider to get SharedPreferences instance (should be overridden in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

// Provider for the ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final token = prefs.getString('auth_token');
  
  return ApiClient(token: token);
});

final livekitApiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final token = prefs.getString('auth_token');

  return ApiClient(
    baseUrl: ApiConfig.livekitBaseUrl,
    token: token,
  );
});
