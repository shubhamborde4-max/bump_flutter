import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/core/utils/authenticated_repository.dart';
import 'package:bump/core/utils/safe_cast.dart';
import 'package:bump/data/models/event_model.dart';
import 'package:bump/data/repositories/event_repository.dart';

class SupabaseEventRepository
    with AuthenticatedRepository
    implements EventRepository {
  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  Future<List<Event>> getEvents() async {
    final response = await client
        .from('events')
        .select()
        .eq('user_id', currentUserId)
        .order('date', ascending: false);

    return safeListCast(response)
        .map((json) => Event.fromJson(json))
        .toList();
  }

  @override
  Future<Event?> getEvent(String id) async {
    final response = await client
        .from('events')
        .select()
        .eq('id', id)
        .eq('user_id', currentUserId)
        .maybeSingle();

    if (response == null) return null;
    return Event.fromJson(response);
  }

  @override
  Future<Event> createEvent(Event event) async {
    final data = event.toJson();
    data['user_id'] = currentUserId;
    data.remove('id'); // Let Supabase generate the id

    final response = await client
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

    await client.from('events').update(data).eq('id', event.id);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await client.from('events').delete().eq('id', id).eq('user_id', currentUserId);
  }

  @override
  Future<void> setActiveEvent(String id) async {
    // Atomic: deactivate all then activate target in a single RPC call
    await client.rpc('set_active_event', params: {
      'p_user_id': currentUserId,
      'p_event_id': id,
    });
  }
}
