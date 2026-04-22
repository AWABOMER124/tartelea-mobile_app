import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../data/repositories/media_repository.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MediaRepository(api);
});

