import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/data/repositories/exchange_repository.dart';

class SupabaseExchangeRepository implements ExchangeRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Map<String, dynamic>> performExchange({
    required String receiverId,
    required String method,
    String? eventId,
  }) async {
    final response = await _client.rpc('handle_exchange', params: {
      'p_receiver_id': receiverId,
      'p_method': method,
      'p_event_id': eventId,
    });

    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    final response = await _client.rpc('get_profile_by_username', params: {
      'p_username': username.toLowerCase(),
    });

    if (response == null || (response is List && response.isEmpty)) {
      return null;
    }

    if (response is List) {
      return response.first as Map<String, dynamic>;
    }

    return response as Map<String, dynamic>;
  }
}
