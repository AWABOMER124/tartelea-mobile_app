import '../../core/api/api_client.dart';
import '../../core/api/api_payload.dart';
import '../models/subscription_contract.dart';

class SubscriptionRepository {
  final ApiClient _api;

  SubscriptionRepository(this._api);

  /// Backend-owned subscription contract (single source of truth).
  Future<SubscriptionContract?> getMySubscription() async {
    try {
      final response = await _api.get('/subscriptions/me');
      final payload = ApiPayload.unwrapObject(response.data);
      return SubscriptionContract.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  /// Verify a PayPal subscription through the backend compatibility gateway.
  /// The backend may mint/extend the monthly subscription if the provider returns ACTIVE.
  Future<bool> verifyPayPalSubscription(String subscriptionId) async {
    try {
      final response = await _api.post('/compat/functions/paypal-subscription', data: {
        'action': 'verify',
        'subscriptionId': subscriptionId,
      });

      final payload = ApiPayload.unwrapObject(response.data);
      return payload['success'] == true && payload['active'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Check monthly subscription status through the backend compatibility gateway.
  Future<Map<String, dynamic>> checkActiveSubscription() async {
    try {
      final response = await _api.post('/compat/functions/paypal-subscription', data: {
        'action': 'check',
      });
      return ApiPayload.unwrapObject(response.data);
    } catch (_) {
      return {'success': false, 'hasSubscription': false};
    }
  }
}
