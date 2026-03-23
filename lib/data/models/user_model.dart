enum CardStyle { modern, classic, minimal }

class User {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String company;
  final String title;
  final String? avatar;
  final String? linkedIn;
  final String? website;
  final String? bio;
  final CardStyle cardStyle;
  final int totalBumps;
  final int totalNudges;
  final double conversionRate;

  const User({
    required this.id,
    this.username = '',
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.company,
    required this.title,
    this.avatar,
    this.linkedIn,
    this.website,
    this.bio,
    this.cardStyle = CardStyle.modern,
    this.totalBumps = 0,
    this.totalNudges = 0,
    this.conversionRate = 0.0,
  });

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  User copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? company,
    String? title,
    String? avatar,
    String? linkedIn,
    String? website,
    String? bio,
    CardStyle? cardStyle,
    int? totalBumps,
    int? totalNudges,
    double? conversionRate,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      title: title ?? this.title,
      avatar: avatar ?? this.avatar,
      linkedIn: linkedIn ?? this.linkedIn,
      website: website ?? this.website,
      bio: bio ?? this.bio,
      cardStyle: cardStyle ?? this.cardStyle,
      totalBumps: totalBumps ?? this.totalBumps,
      totalNudges: totalNudges ?? this.totalNudges,
      conversionRate: conversionRate ?? this.conversionRate,
    );
  }

  /// Serialise to snake_case keys matching the Supabase `profiles` table.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'company': company,
      'title': title,
      'avatar_url': avatar,
      'linkedin': linkedIn,
      'website': website,
      'bio': bio,
      'card_style': cardStyle.name,
    };
  }

  /// Deserialise from snake_case keys returned by Supabase.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      company: json['company'] as String? ?? '',
      title: json['title'] as String? ?? '',
      avatar: json['avatar_url'] as String?,
      linkedIn: json['linkedin'] as String?,
      website: json['website'] as String?,
      bio: json['bio'] as String?,
      cardStyle: CardStyle.values.firstWhere(
        (e) => e.name == json['card_style'],
        orElse: () => CardStyle.modern,
      ),
      totalBumps: json['total_bumps'] as int? ?? 0,
      totalNudges: json['total_nudges'] as int? ?? 0,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
