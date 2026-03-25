import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/core/utils/authenticated_repository.dart';
import 'package:bump/core/utils/safe_cast.dart';
import 'package:bump/data/models/template_model.dart';
import 'package:bump/data/repositories/template_repository.dart';

class SupabaseTemplateRepository
    with AuthenticatedRepository
    implements TemplateRepository {
  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  Future<List<Template>> getTemplates() async {
    // Fetch system templates (user_id is null) plus user's own templates
    final response = await client
        .from('templates')
        .select()
        .or('user_id.is.null,user_id.eq.$currentUserId')
        .order('created_at', ascending: false);

    return safeListCast(response)
        .map((json) => Template.fromJson(json))
        .toList();
  }

  @override
  Future<Template> createTemplate(Template template) async {
    final data = template.toJson();
    data['user_id'] = currentUserId;
    data.remove('id');

    final response = await client
        .from('templates')
        .insert(data)
        .select()
        .single();

    return Template.fromJson(response);
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await client
        .from('templates')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUserId);
  }
}
