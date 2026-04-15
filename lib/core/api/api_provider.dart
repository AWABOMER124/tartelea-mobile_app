import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'api_config.dart';

// Provider to get SharedPreferences instance (should be overridden in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

final storedAuthTokenProvider = Provider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('auth_token');
});

// Provider for the ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(storedAuthTokenProvider);
  return ApiClient(token: token);
});

final livekitApiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(storedAuthTokenProvider);
  return ApiClient(
    baseUrl: ApiConfig.livekitBaseUrl,
    token: token,
  );
});
