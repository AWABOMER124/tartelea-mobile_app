import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_payload.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final ApiClient _api;
  final SupabaseClient _supabase;

  SubscriptionRepository(this._api, this._supabase);

  /// Get subscription info from Node.js backend
  Future<SubscriptionModel?> getUserSubscription(String userId) async {
    try {
      final response = await _api.get('/subscriptions/$userId');
      final payload = ApiPayload.unwrap(response.data);
      if (payload == null) return null;
      return SubscriptionModel.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  /// Verify a PayPal subscription via Supabase Edge Function
  Future<bool> verifyPayPalSubscription(String subscriptionId) async {
    try {
      final response = await _supabase.functions.invoke(
        'paypal-subscription',
        body: {
          'action': 'verify',
          'subscriptionId': subscriptionId,
        },
      );
      
      return response.data['success'] == true && response.data['active'] == true;
    } catch (e) {
      // Internal error logging
      return false;
    }
  }

  /// Check if user has an active subscription directly from Supabase
  Future<Map<String, dynamic>> checkActiveSubscription() async {
    try {
      final response = await _supabase.functions.invoke(
        'paypal-subscription',
        body: {'action': 'check'},
      );
      return response.data;
    } catch (e) {
      // Internal error logging
      return {'success': false, 'hasSubscription': false};
    }
  }
}
