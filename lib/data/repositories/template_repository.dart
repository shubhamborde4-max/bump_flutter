import 'package:bump/data/models/template_model.dart';

abstract class TemplateRepository {
  Future<List<Template>> getTemplates();

  Future<Template> createTemplate(Template template);

  Future<void> deleteTemplate(String id);
}
