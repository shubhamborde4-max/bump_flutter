import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bump/data/models/user_model.dart';
import 'package:bump/data/repositories/profile_repository.dart';
import 'package:bump/data/repositories_impl/supabase_profile_repository.dart';

/// Provides the [ProfileRepository] backed by Supabase.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository();
});

/// Fetches the current user's profile from Supabase.
/// Call `ref.invalidate(profileProvider)` to refetch.
final profileProvider = FutureProvider<User?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMyProfile();
});

/// Async notifier for profile mutations (update profile, upload avatar).
final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, User?>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getMyProfile();
  }

  Future<void> updateProfile(User user) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(user);
      return user;
    });
  }

  Future<String?> uploadAvatar(String filePath) async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final url = await repo.uploadAvatar(filePath);

      // Update the profile with the new avatar URL
      final current = state.valueOrNull;
      if (current != null) {
        final updated = current.copyWith(avatar: url);
        await repo.updateProfile(updated);
        state = AsyncData(updated);
      }

      return url;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
