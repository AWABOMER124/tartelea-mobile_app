import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_provider.dart';
import '../../core/api/api_payload.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../data/models/profile_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthRepositoryImpl(api);
});

// Simple provider to check if a token exists
final authTokenProvider = Provider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('auth_token');
});

final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) return null;
  
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get('/auth/me');
    final profileJson = ApiPayload.unwrapObject(
      response.data,
      preferredKeys: const ['user'],
    );
    return ProfileModel.fromJson(profileJson);
  } catch (e) {
    return null;
  }
});

// Alias for UI compatibility
final userProvider = Provider<ProfileModel?>((ref) {
  return ref.watch(profileProvider).asData?.value;
});

final isAuthorizedProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(profileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile != null && (profile.role == 'trainer' || profile.role == 'admin'),
    orElse: () => false,
  );
});

final isAdminProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(profileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile != null && profile.role == 'admin',
    orElse: () => false,
  );
});
