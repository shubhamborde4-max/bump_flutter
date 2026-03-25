import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/core/utils/authenticated_repository.dart';
import 'package:bump/core/utils/safe_cast.dart';
import 'package:bump/data/models/nudge_model.dart';
import 'package:bump/data/repositories/nudge_repository.dart';

class SupabaseNudgeRepository
    with AuthenticatedRepository
    implements NudgeRepository {
  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  Future<List<Nudge>> getNudges({String? prospectId}) async {
    var query = client
        .from('nudges')
        .select()
        .eq('user_id', currentUserId);

    if (prospectId != null) {
      query = query.eq('prospect_id', prospectId);
    }

    final response = await query.order('sent_at', ascending: false);

    return safeListCast(response)
        .map((json) => Nudge.fromJson(json))
        .toList();
  }

  @override
  Future<Nudge> createNudge(Nudge nudge) async {
    final data = nudge.toJson();
    data['user_id'] = currentUserId;
    data.remove('id');

    final response = await client
        .from('nudges')
        .insert(data)
        .select()
        .single();

    return Nudge.fromJson(response);
  }

  @override
  Future<void> updateNudgeStatus(String id, String status) async {
    await client
        .from('nudges')
        .update({'status': status})
        .eq('id', id)
        .eq('user_id', currentUserId);
  }
}
