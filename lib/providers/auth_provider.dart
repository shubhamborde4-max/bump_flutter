import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/data/repositories/auth_repository.dart';
import 'package:bump/data/repositories_impl/supabase_auth_repository.dart';

/// Provides the raw Supabase client for one-off operations.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provides the [AuthRepository] backed by Supabase.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Emits `true` whenever the user is signed in, `false` when signed out.
final authStateProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.onAuthStateChange();
});

/// Quick accessor for the current user's Supabase UID (or null).
final currentUserIdProvider = Provider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUserId;
});
