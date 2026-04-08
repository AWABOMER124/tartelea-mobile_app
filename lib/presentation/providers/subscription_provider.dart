import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_provider.dart';
import '../../core/constants/supabase_config.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final supabase = ref.watch(supabaseProvider);
  return SubscriptionRepository(api, supabase);
});

final subscriptionStatusProvider = StateNotifierProvider<SubscriptionNotifier, AsyncValue<bool>>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionNotifier(repository);
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<bool>> {
  final SubscriptionRepository _repository;

  SubscriptionNotifier(this._repository) : super(const AsyncValue.loading()) {
    checkStatus();
  }

  Future<void> checkStatus() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.checkActiveSubscription();
      state = AsyncValue.data(result['hasSubscription'] == true);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> verify(String subscriptionId) async {
    state = const AsyncValue.loading();
    final success = await _repository.verifyPayPalSubscription(subscriptionId);
    if (success) {
      state = const AsyncValue.data(true);
    } else {
      await checkStatus(); // Fallback to checking DB
    }
    return success;
  }
}
