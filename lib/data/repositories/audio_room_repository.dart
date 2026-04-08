import '../../core/api/api_client.dart';
import '../../core/api/api_payload.dart';
import '../models/audio_room_model.dart';

class AudioRoomRepository {
  final ApiClient _api;

  AudioRoomRepository(this._api);

  Future<List<AudioRoomModel>> getLiveRooms() async {
    final response = await _api.get('/audio-rooms/live');
    final rooms = ApiPayload.unwrapList(
      response.data,
      preferredKeys: const ['rooms'],
    );
    return rooms.map((json) => AudioRoomModel.fromJson(json)).toList();
  }
}
