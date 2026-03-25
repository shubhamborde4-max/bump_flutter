import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/core/utils/authenticated_repository.dart';
import 'package:bump/core/utils/safe_cast.dart';
import 'package:bump/data/repositories/exchange_repository.dart';

class SupabaseExchangeRepository
    with AuthenticatedRepository
    implements ExchangeRepository {
  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  Future<Map<String, dynamic>> performExchange({
    required String receiverId,
    required String method,
    String? eventId,
  }) async {
    final response = await client.rpc('handle_exchange', params: {
      'p_initiator_id': currentUserId,
      'p_receiver_id': receiverId,
      'p_method': method,
      'p_event_id': eventId,
    });

    return safeMapCast(response) ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    final response = await client.rpc('get_profile_by_username', params: {
      'p_username': username.toLowerCase(),
    });

    return safeMapCast(response);
  }
}
