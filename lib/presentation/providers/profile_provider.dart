import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/supabase_config.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import 'auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return ProfileRepository(client);
});

final userProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;
  
  return ref.read(profileRepositoryProvider).getProfile(user.id);
});
