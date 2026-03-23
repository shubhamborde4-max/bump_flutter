import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/data/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
      },
    );
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<bool> hasSession() async {
    return _client.auth.currentSession != null;
  }

  @override
  Stream<bool> onAuthStateChange() {
    return _client.auth.onAuthStateChange.map(
      (data) => data.session != null,
    );
  }

  @override
  String? get currentUserId => _client.auth.currentUser?.id;
}
