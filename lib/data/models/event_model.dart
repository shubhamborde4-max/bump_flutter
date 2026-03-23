class Event {
  final String id;
  final String? userId;
  final String name;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final String? description;
  final int totalProspects;
  final int nudgesSent;
  final bool isActive;

  const Event({
    required this.id,
    this.userId,
    required this.name,
    required this.date,
    this.endDate,
    required this.location,
    this.description,
    this.totalProspects = 0,
    this.nudgesSent = 0,
    this.isActive = false,
  });

  Event copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? date,
    DateTime? endDate,
    String? location,
    String? description,
    int? totalProspects,
    int? nudgesSent,
    bool? isActive,
  }) {
    return Event(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      description: description ?? this.description,
      totalProspects: totalProspects ?? this.totalProspects,
      nudgesSent: nudgesSent ?? this.nudgesSent,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Serialise to snake_case keys matching the Supabase `events` table.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'date': date.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'description': description,
      'is_active': isActive,
    };
  }

  /// Deserialise from snake_case keys returned by Supabase.
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      location: json['location'] as String? ?? '',
      description: json['description'] as String?,
      totalProspects: json['total_prospects'] as int? ?? 0,
      nudgesSent: json['nudges_sent'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}
