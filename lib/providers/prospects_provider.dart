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
    final previous = state;
    final current = state.valueOrNull ?? [];
    // Optimistic update
    state = AsyncData([
      for (final p in current)
        if (p.id == id)
          p.copyWith(status: ProspectStatusX.fromString(status))
        else
          p,
    ]);
    try {
      final repo = ref.read(prospectsRepositoryProvider);
      await repo.updateProspectStatus(id, status);
    } catch (e) {
      state = previous; // Rollback
      rethrow;
    }
  }

  Future<void> updateProspect(Prospect prospect) async {
    final previous = state;
    final current = state.valueOrNull ?? [];
    // Optimistic update
    state = AsyncData([
      for (final p in current)
        if (p.id == prospect.id) prospect else p,
    ]);
    try {
      final repo = ref.read(prospectsRepositoryProvider);
      await repo.updateProspect(prospect);
    } catch (e) {
      state = previous; // Rollback
      rethrow;
    }
  }

  Future<void> addProspect({
    required String firstName,
    required String lastName,
    String email = '',
    String phone = '',
    String company = '',
    String title = '',
    String eventId = '',
    String notes = '',
    String method = 'manual',
  }) async {
    final prospect = Prospect(
      id: '', // Will be assigned by Supabase
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      company: company,
      title: title,
      eventId: eventId,
      notes: notes,
      exchangeMethod: ExchangeMethodX.fromString(method),
      exchangeTime: DateTime.now(),
    );

    final repo = ref.read(prospectsRepositoryProvider);
    final created = await repo.createProspect(prospect);

    final current = state.valueOrNull ?? [];
    state = AsyncData([created, ...current]);
  }

  Future<Prospect> addQuickCaptureProspect({
    required String firstName,
    String lastName = '',
    String company = '',
    String title = '',
    String notes = '',
    String eventId = '',
    List<String> tags = const [],
  }) async {
    // Calculate missing fields
    final missing = <String>[];
    if (firstName.isEmpty) missing.add('name');
    if (company.isEmpty) missing.add('company');
    if (title.isEmpty) missing.add('title');
    missing.add('phone');
    missing.add('email');
    missing.add('linkedIn');

    final enrichment = firstName.isNotEmpty ? 'partial' : 'partial';

    final prospect = Prospect(
      id: '', // Will be assigned by Supabase
      firstName: firstName,
      lastName: lastName,
      email: '',
      phone: '',
      company: company,
      title: title,
      eventId: eventId,
      notes: notes,
      tags: tags,
      exchangeMethod: ExchangeMethod.quickCapture,
      exchangeTime: DateTime.now(),
      exchangeType: 'quick_capture',
      enrichmentStatus: enrichment,
      missingFields: missing,
      exchangeDirection: 'outbound',
    );

    final repo = ref.read(prospectsRepositoryProvider);
    final created = await repo.createProspect(prospect);

    final current = state.valueOrNull ?? [];
    state = AsyncData([created, ...current]);
    return created;
  }

  Future<void> deleteProspect(String id) async {
    final previous = state;
    final current = state.valueOrNull ?? [];
    // Optimistic update
    state = AsyncData(current.where((p) => p.id != id).toList());
    try {
      final repo = ref.read(prospectsRepositoryProvider);
      await repo.deleteProspect(id);
    } catch (e) {
      state = previous; // Rollback
      rethrow;
    }
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
