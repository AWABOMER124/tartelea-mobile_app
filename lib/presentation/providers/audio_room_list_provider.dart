import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_provider.dart';
import '../../data/models/audio_room_model.dart';
import '../../data/repositories/audio_room_repository.dart';

final audioRoomRepositoryProvider = Provider<AudioRoomRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AudioRoomRepository(api);
});

final liveAudioRoomsProvider = FutureProvider<List<AudioRoomModel>>((ref) {
  return ref.read(audioRoomRepositoryProvider).getLiveRooms();
});
