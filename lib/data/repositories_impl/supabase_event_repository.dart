import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/data/models/event_model.dart';
import 'package:bump/data/repositories/event_repository.dart';

class SupabaseEventRepository implements EventRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  @override
  Future<List<Event>> getEvents() async {
    final response = await _client
        .from('events')
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Event?> getEvent(String id) async {
    final response = await _client
        .from('events')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return Event.fromJson(response);
  }

  @override
  Future<Event> createEvent(Event event) async {
    final data = event.toJson();
    data['user_id'] = _userId;
    data.remove('id'); // Let Supabase generate the id

    final response = await _client
        .from('events')
        .insert(data)
        .select()
        .single();

    return Event.fromJson(response);
  }

  @override
  Future<void> updateEvent(Event event) async {
    final data = event.toJson();
    data.remove('id');
    data.remove('user_id');

    await _client.from('events').update(data).eq('id', event.id);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _client.from('events').delete().eq('id', id).eq('user_id', _userId);
  }

  @override
  Future<void> setActiveEvent(String id) async {
    // First deactivate all events for this user
    await _client
        .from('events')
        .update({'is_active': false})
        .eq('user_id', _userId);

    // Then activate the target event
    await _client
        .from('events')
        .update({'is_active': true})
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
