import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/data/models/nudge_model.dart';
import 'package:bump/data/repositories/nudge_repository.dart';

class SupabaseNudgeRepository implements NudgeRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  @override
  Future<List<Nudge>> getNudges({String? prospectId}) async {
    var query = _client
        .from('nudges')
        .select()
        .eq('user_id', _userId);

    if (prospectId != null) {
      query = query.eq('prospect_id', prospectId);
    }

    final response = await query.order('sent_at', ascending: false);

    return (response as List)
        .map((json) => Nudge.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Nudge> createNudge(Nudge nudge) async {
    final data = nudge.toJson();
    data['user_id'] = _userId;
    data.remove('id');

    final response = await _client
        .from('nudges')
        .insert(data)
        .select()
        .single();

    return Nudge.fromJson(response);
  }

  @override
  Future<void> updateNudgeStatus(String id, String status) async {
    await _client
        .from('nudges')
        .update({'status': status})
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
