import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/data/repositories/prospect_repository.dart';

class SupabaseProspectRepository implements ProspectRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Session expired. Please sign in again.');
    }
    return user.id;
  }

  @override
  Future<List<Prospect>> getProspects({String? eventId, String? status}) async {
    var query = _client
        .from('prospects')
        .select()
        .eq('user_id', _userId);

    if (eventId != null) {
      query = query.eq('event_id', eventId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('exchange_time', ascending: false);

    return (response as List)
        .map((json) => Prospect.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Prospect?> getProspect(String id) async {
    final response = await _client
        .from('prospects')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return Prospect.fromJson(response);
  }

  @override
  Future<Prospect> createProspect(Prospect prospect) async {
    final data = prospect.toJson();
    data['user_id'] = _userId;
    data.remove('id');

    final response = await _client
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

    await _client.from('prospects').update(data).eq('id', prospect.id);
  }

  @override
  Future<void> updateProspectStatus(String id, String status) async {
    await _client
        .from('prospects')
        .update({'status': status})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<void> deleteProspect(String id) async {
    await _client
        .from('prospects')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<int> getProspectCount({String? eventId}) async {
    var query = _client
        .from('prospects')
        .select()
        .eq('user_id', _userId);

    if (eventId != null) {
      query = query.eq('event_id', eventId);
    }

    final response = await query;
    return (response as List).length;
  }
}
