import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bump/data/models/nudge_model.dart';
import 'package:bump/data/repositories/nudge_repository.dart';
import 'package:bump/data/repositories_impl/supabase_nudge_repository.dart';

/// Provides the [NudgeRepository] backed by Supabase.
final nudgesRepositoryProvider = Provider<NudgeRepository>((ref) {
  return SupabaseNudgeRepository();
});

/// Async notifier for nudges loaded from Supabase.
final nudgesProvider =
    AsyncNotifierProvider<NudgesNotifier, List<Nudge>>(NudgesNotifier.new);

class NudgesNotifier extends AsyncNotifier<List<Nudge>> {
  @override
  Future<List<Nudge>> build() async {
    return _loadNudges();
  }

  Future<List<Nudge>> _loadNudges() async {
    final repo = ref.read(nudgesRepositoryProvider);
    return repo.getNudges();
  }

  Future<void> loadNudges() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadNudges());
  }

  Future<Nudge> sendNudge(Nudge nudge) async {
    final previous = state;
    // Optimistic update
    state = AsyncData([nudge, ...state.valueOrNull ?? []]);
    try {
      final repo = ref.read(nudgesRepositoryProvider);
      final created = await repo.createNudge(nudge);
      // Replace optimistic with server response
      state = AsyncData([created, ...previous.valueOrNull ?? []]);
      return created;
    } catch (e) {
      state = previous; // Rollback
      rethrow;
    }
  }
}
