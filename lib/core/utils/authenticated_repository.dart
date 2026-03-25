import 'package:supabase_flutter/supabase_flutter.dart';

mixin AuthenticatedRepository {
  SupabaseClient get client;

  String get currentUserId {
    final user = client.auth.currentUser;
    if (user == null) {
      throw AuthException('Session expired. Please sign in again.');
    }
    return user.id;
  }
}
