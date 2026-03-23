enum TemplateCategory { followUp, intro, meeting }

extension TemplateCategoryX on TemplateCategory {
  String get label => name;

  String get displayName {
    switch (this) {
      case TemplateCategory.followUp:
        return 'Follow Up';
      case TemplateCategory.intro:
        return 'Introduction';
      case TemplateCategory.meeting:
        return 'Meeting';
    }
  }

  static TemplateCategory fromString(String value) {
    switch (value) {
      case 'followUp':
      case 'follow_up':
        return TemplateCategory.followUp;
      case 'intro':
        return TemplateCategory.intro;
      case 'meeting':
        return TemplateCategory.meeting;
      default:
        return TemplateCategory.followUp;
    }
  }
}

class Template {
  final String id;
  final String? userId;
  final String name;
  final String message;
  final TemplateCategory category;
  final bool isAiGenerated;

  const Template({
    required this.id,
    this.userId,
    required this.name,
    required this.message,
    required this.category,
    this.isAiGenerated = false,
  });

  Template copyWith({
    String? id,
    String? userId,
    String? name,
    String? message,
    TemplateCategory? category,
    bool? isAiGenerated,
  }) {
    return Template(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      message: message ?? this.message,
      category: category ?? this.category,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
    );
  }

  /// Serialise to snake_case keys matching the Supabase `templates` table.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'message': message,
      'category': category.label,
      'is_ai_generated': isAiGenerated,
    };
  }

  /// Deserialise from snake_case keys returned by Supabase.
  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String? ?? '',
      message: json['message'] as String? ?? '',
      category: TemplateCategoryX.fromString(json['category'] as String? ?? 'followUp'),
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
    );
  }
}
