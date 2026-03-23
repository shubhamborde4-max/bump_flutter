import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bump/data/models/template_model.dart';
import 'package:bump/data/repositories/template_repository.dart';
import 'package:bump/data/repositories_impl/supabase_template_repository.dart';

/// Provides the [TemplateRepository] backed by Supabase.
final templatesRepositoryProvider = Provider<TemplateRepository>((ref) {
  return SupabaseTemplateRepository();
});

/// Fetches templates from Supabase (system + user templates).
final templatesProvider = FutureProvider<List<Template>>((ref) async {
  final repo = ref.watch(templatesRepositoryProvider);
  return repo.getTemplates();
});
