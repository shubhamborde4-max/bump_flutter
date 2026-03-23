import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/data/repositories/prospect_repository.dart';
import 'package:bump/data/repositories_impl/supabase_prospect_repository.dart';

/// Provides the [ProspectRepository] backed by Supabase.
final prospectsRepositoryProvider = Provider<ProspectRepository>((ref) {
  return SupabaseProspectRepository();
});

/// Async notifier for prospects loaded from Supabase.
final prospectsProvider =
    AsyncNotifierProvider<ProspectsNotifier, List<Prospect>>(
        ProspectsNotifier.new);

class ProspectsNotifier extends AsyncNotifier<List<Prospect>> {
  @override
  Future<List<Prospect>> build() async {
    return _loadProspects();
  }

  Future<List<Prospect>> _loadProspects() async {
    final repo = ref.read(prospectsRepositoryProvider);
    return repo.getProspects();
  }

  Future<void> loadProspects() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadProspects());
  }

  Future<void> updateProspectStatus(String id, String status) async {
    final repo = ref.read(prospectsRepositoryProvider);
    await repo.updateProspectStatus(id, status);
    final current = state.valueOrNull ?? [];
    state = AsyncData([
      for (final p in current)
        if (p.id == id)
          p.copyWith(status: ProspectStatusX.fromString(status))
        else
          p,
    ]);
  }

  Future<void> updateProspect(Prospect prospect) async {
    final repo = ref.read(prospectsRepositoryProvider);
    await repo.updateProspect(prospect);
    final current = state.valueOrNull ?? [];
    state = AsyncData([
      for (final p in current)
        if (p.id == prospect.id) prospect else p,
    ]);
  }

  Future<void> deleteProspect(String id) async {
    final repo = ref.read(prospectsRepositoryProvider);
    await repo.deleteProspect(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((p) => p.id != id).toList());
  }
}

/// Prospects filtered by eventId.
final prospectsByEventProvider =
    Provider.family<List<Prospect>, String>((ref, eventId) {
  final prospectsAsync = ref.watch(prospectsProvider);
  return prospectsAsync.whenOrNull(
        data: (prospects) =>
            prospects.where((p) => p.eventId == eventId).toList(),
      ) ??
      [];
});

/// Prospect count for a given event.
final prospectCountByEventProvider =
    Provider.family<int, String>((ref, eventId) {
  final prospects = ref.watch(prospectsByEventProvider(eventId));
  return prospects.length;
});

/// The five most recently exchanged prospects (across all events).
final recentProspectsProvider = Provider<List<Prospect>>((ref) {
  final prospectsAsync = ref.watch(prospectsProvider);
  return prospectsAsync.whenOrNull(
        data: (prospects) {
          final sorted = [...prospects]
            ..sort((a, b) => b.exchangeTime.compareTo(a.exchangeTime));
          return sorted.take(5).toList();
        },
      ) ??
      [];
});
