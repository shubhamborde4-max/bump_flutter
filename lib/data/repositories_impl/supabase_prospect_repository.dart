import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/core/utils/authenticated_repository.dart';
import 'package:bump/core/utils/safe_cast.dart';
import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/data/repositories/prospect_repository.dart';

class SupabaseProspectRepository
    with AuthenticatedRepository
    implements ProspectRepository {
  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  Future<List<Prospect>> getProspects({String? eventId, String? status}) async {
    var query = client
        .from('prospects')
        .select()
        .eq('user_id', currentUserId);

    if (eventId != null) {
      query = query.eq('event_id', eventId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('exchange_time', ascending: false);

    return safeListCast(response)
        .map((json) => Prospect.fromJson(json))
        .toList();
  }

  @override
  Future<Prospect?> getProspect(String id) async {
    final response = await client
        .from('prospects')
        .select()
        .eq('id', id)
        .eq('user_id', currentUserId)
        .maybeSingle();

    if (response == null) return null;
    return Prospect.fromJson(response);
  }

  @override
  Future<Prospect> createProspect(Prospect prospect) async {
    final data = prospect.toJson();
    data['user_id'] = currentUserId;
    data.remove('id');

    final response = await client
        .from('prospects')
        .insert(data)
        .select()
        .single();

    return Prospect.fromJson(response);
  }

  @override
  Future<void> updateProspect(Prospect prospect) async {
    final data = prospect.toJson();
    data.remove('id');
    data.remove('user_id');

    await client.from('prospects').update(data).eq('id', prospect.id);
  }

  @override
  Future<void> updateProspectStatus(String id, String status) async {
    await client
        .from('prospects')
        .update({'status': status})
        .eq('id', id)
        .eq('user_id', currentUserId);
  }

  @override
  Future<void> deleteProspect(String id) async {
    await client
        .from('prospects')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUserId);
  }

  @override
  Future<int> getProspectCount({String? eventId}) async {
    var query = client
        .from('prospects')
        .select()
        .eq('user_id', currentUserId);

    if (eventId != null) {
      query = query.eq('event_id', eventId);
    }

    final response = await query;
    return safeListCast(response).length;
  }
}
