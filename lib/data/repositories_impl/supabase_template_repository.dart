import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/data/models/template_model.dart';
import 'package:bump/data/repositories/template_repository.dart';

class SupabaseTemplateRepository implements TemplateRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Session expired. Please sign in again.');
    }
    return user.id;
  }

  @override
  Future<List<Template>> getTemplates() async {
    // Fetch system templates (user_id is null) plus user's own templates
    final response = await _client
        .from('templates')
        .select()
        .or('user_id.is.null,user_id.eq.$_userId')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Template.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Template> createTemplate(Template template) async {
    final data = template.toJson();
    data['user_id'] = _userId;
    data.remove('id');

    final response = await _client
        .from('templates')
        .insert(data)
        .select()
        .single();

    return Template.fromJson(response);
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _client
        .from('templates')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
