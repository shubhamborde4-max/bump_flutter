enum ProspectStatus { newProspect, contacted, interested, converted, archived }

enum ExchangeMethod { bump, qr, nfc, link }

extension ProspectStatusX on ProspectStatus {
  String get label {
    switch (this) {
      case ProspectStatus.newProspect:
        return 'new';
      case ProspectStatus.contacted:
        return 'contacted';
      case ProspectStatus.interested:
        return 'interested';
      case ProspectStatus.converted:
        return 'converted';
      case ProspectStatus.archived:
        return 'archived';
    }
  }

  String get displayName {
    switch (this) {
      case ProspectStatus.newProspect:
        return 'New';
      case ProspectStatus.contacted:
        return 'Contacted';
      case ProspectStatus.interested:
        return 'Interested';
      case ProspectStatus.converted:
        return 'Converted';
      case ProspectStatus.archived:
        return 'Archived';
    }
  }

  static ProspectStatus fromString(String value) {
    switch (value) {
      case 'new':
        return ProspectStatus.newProspect;
      case 'contacted':
        return ProspectStatus.contacted;
      case 'interested':
        return ProspectStatus.interested;
      case 'converted':
        return ProspectStatus.converted;
      case 'archived':
        return ProspectStatus.archived;
      default:
        return ProspectStatus.newProspect;
    }
  }
}

extension ExchangeMethodX on ExchangeMethod {
  String get label {
    switch (this) {
      case ExchangeMethod.bump:
        return 'bump';
      case ExchangeMethod.qr:
        return 'qr';
      case ExchangeMethod.nfc:
        return 'nfc';
      case ExchangeMethod.link:
        return 'link';
    }
  }

  String get displayName {
    switch (this) {
      case ExchangeMethod.bump:
        return 'Bump';
      case ExchangeMethod.qr:
        return 'QR Code';
      case ExchangeMethod.nfc:
        return 'NFC';
      case ExchangeMethod.link:
        return 'Link';
    }
  }

  static ExchangeMethod fromString(String value) {
    switch (value) {
      case 'bump':
        return ExchangeMethod.bump;
      case 'qr':
        return ExchangeMethod.qr;
      case 'nfc':
        return ExchangeMethod.nfc;
      case 'link':
        return ExchangeMethod.link;
      default:
        return ExchangeMethod.bump;
    }
  }
}

class Prospect {
  final String id;
  final String? userId;
  final String eventId;
  final String? exchangedWith;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String company;
  final String title;
  final String? avatar;
  final String notes;
  final ProspectStatus status;
  final ExchangeMethod exchangeMethod;
  final DateTime exchangeTime;
  final String? linkedIn;
  final List<String> tags;

  const Prospect({
    required this.id,
    this.userId,
    required this.eventId,
    this.exchangedWith,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.company,
    required this.title,
    this.avatar,
    this.notes = '',
    this.status = ProspectStatus.newProspect,
    this.exchangeMethod = ExchangeMethod.bump,
    required this.exchangeTime,
    this.linkedIn,
    this.tags = const [],
  });

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  Prospect copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? exchangedWith,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? company,
    String? title,
    String? avatar,
    String? notes,
    ProspectStatus? status,
    ExchangeMethod? exchangeMethod,
    DateTime? exchangeTime,
    String? linkedIn,
    List<String>? tags,
  }) {
    return Prospect(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      exchangedWith: exchangedWith ?? this.exchangedWith,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      title: title ?? this.title,
      avatar: avatar ?? this.avatar,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      exchangeMethod: exchangeMethod ?? this.exchangeMethod,
      exchangeTime: exchangeTime ?? this.exchangeTime,
      linkedIn: linkedIn ?? this.linkedIn,
      tags: tags ?? this.tags,
    );
  }

  /// Serialise to snake_case keys matching the Supabase `prospects` table.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'exchanged_with': exchangedWith,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'company': company,
      'title': title,
      'avatar_url': avatar,
      'linkedin': linkedIn,
      'notes': notes,
      'status': status.label,
      'exchange_method': exchangeMethod.label,
      'exchange_time': exchangeTime.toIso8601String(),
      'tags': tags,
    };
  }

  /// Deserialise from snake_case keys returned by Supabase.
  factory Prospect.fromJson(Map<String, dynamic> json) {
    return Prospect(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      eventId: json['event_id'] as String? ?? '',
      exchangedWith: json['exchanged_with'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      company: json['company'] as String? ?? '',
      title: json['title'] as String? ?? '',
      avatar: json['avatar_url'] as String?,
      notes: json['notes'] as String? ?? '',
      status:
          ProspectStatusX.fromString(json['status'] as String? ?? 'new'),
      exchangeMethod: ExchangeMethodX.fromString(json['exchange_method'] as String? ?? 'bump'),
      exchangeTime: json['exchange_time'] != null
          ? DateTime.parse(json['exchange_time'] as String)
          : DateTime.now(),
      linkedIn: json['linkedin'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}
