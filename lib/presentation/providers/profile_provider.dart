import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_provider.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import 'auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ProfileRepository(api);
});

final userProfileProvider = FutureProvider<ProfileModel?>((ref) {
  return ref.watch(profileProvider.future);
});
