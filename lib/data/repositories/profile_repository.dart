import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../../core/api/api_payload.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final ApiClient _api;

  ProfileRepository(this._api);

  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final response = await _api.get('${ApiConfig.profiles}$userId');
      return ProfileModel.fromJson(ApiPayload.unwrapObject(response.data));
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile(ProfileModel profile) async {
    try {
      await _api.put('${ApiConfig.profiles}${profile.id}', data: profile.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }
}
