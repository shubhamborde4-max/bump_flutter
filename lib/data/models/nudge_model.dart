enum NudgeType { whatsapp, email, sms }

enum NudgeStatus { sent, delivered, read, replied }

extension NudgeTypeX on NudgeType {
  String get label => name;

  String get displayName {
    switch (this) {
      case NudgeType.whatsapp:
        return 'WhatsApp';
      case NudgeType.email:
        return 'Email';
      case NudgeType.sms:
        return 'SMS';
    }
  }
}

extension NudgeStatusX on NudgeStatus {
  String get label => name;

  String get displayName {
    switch (this) {
      case NudgeStatus.sent:
        return 'Sent';
      case NudgeStatus.delivered:
        return 'Delivered';
      case NudgeStatus.read:
        return 'Read';
      case NudgeStatus.replied:
        return 'Replied';
    }
  }
}

class Nudge {
  final String id;
  final String? userId;
  final String prospectId;
  final NudgeType type;
  final String message;
  final DateTime sentAt;
  final NudgeStatus status;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  const Nudge({
    required this.id,
    this.userId,
    required this.prospectId,
    required this.type,
    required this.message,
    required this.sentAt,
    this.status = NudgeStatus.sent,
    this.deliveredAt,
    this.readAt,
    this.metadata,
  });

  Nudge copyWith({
    String? id,
    String? userId,
    String? prospectId,
    NudgeType? type,
    String? message,
    DateTime? sentAt,
    NudgeStatus? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return Nudge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      prospectId: prospectId ?? this.prospectId,
      type: type ?? this.type,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Serialise to snake_case keys matching the Supabase `nudges` table.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'prospect_id': prospectId,
      'type': type.label,
      'message': message,
      'status': status.label,
      'sent_at': sentAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Deserialise from snake_case keys returned by Supabase.
  factory Nudge.fromJson(Map<String, dynamic> json) {
    return Nudge(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      prospectId: json['prospect_id'] as String? ?? '',
      type: NudgeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NudgeType.whatsapp,
      ),
      message: json['message'] as String? ?? '',
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : DateTime.now(),
      status: NudgeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NudgeStatus.sent,
      ),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
