import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_provider.dart';
import '../../data/models/workshop_model.dart';
import '../../data/repositories/workshop_repository.dart';

final workshopRepositoryProvider = Provider<WorkshopRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return WorkshopRepository(api);
});

final workshopsProvider = FutureProvider<List<WorkshopModel>>((ref) {
  return ref.read(workshopRepositoryProvider).getWorkshops();
});
