import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_provider.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/models/subscription_contract.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return SubscriptionRepository(api);
});

final subscriptionContractProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionContract?>>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionNotifier(repository);
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<SubscriptionContract?>> {
  final SubscriptionRepository _repository;

  SubscriptionNotifier(this._repository) : super(const AsyncValue.data(null)) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final contract = await _repository.getMySubscription();
      state = AsyncValue.data(contract);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> verify(String subscriptionId) async {
    state = const AsyncValue.loading();
    final success = await _repository.verifyPayPalSubscription(subscriptionId);
    await refresh();
    return success;
  }
}
