import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profile_model.dart';
import 'auth_provider.dart';

final userProfileProvider = FutureProvider<ProfileModel?>((ref) {
  return ref.watch(profileProvider.future);
});
