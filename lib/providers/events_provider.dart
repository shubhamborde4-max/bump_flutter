import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bump/data/models/event_model.dart';
import 'package:bump/data/repositories/event_repository.dart';
import 'package:bump/data/repositories_impl/supabase_event_repository.dart';

/// Provides the [EventRepository] backed by Supabase.
final eventsRepositoryProvider = Provider<EventRepository>((ref) {
  return SupabaseEventRepository();
});

/// Async notifier for events loaded from Supabase.
final eventsProvider =
    AsyncNotifierProvider<EventsNotifier, List<Event>>(EventsNotifier.new);

class EventsNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    return _loadEvents();
  }

  Future<List<Event>> _loadEvents() async {
    final repo = ref.read(eventsRepositoryProvider);
    return repo.getEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadEvents());
  }

  Future<void> createEvent(Event event) async {
    final repo = ref.read(eventsRepositoryProvider);
    final created = await repo.createEvent(event);
    final current = state.valueOrNull ?? [];
    state = AsyncData([created, ...current]);
  }

  Future<void> updateEvent(Event event) async {
    final repo = ref.read(eventsRepositoryProvider);
    await repo.updateEvent(event);
    final current = state.valueOrNull ?? [];
    state = AsyncData([
      for (final e in current)
        if (e.id == event.id) event else e,
    ]);
  }

  Future<void> deleteEvent(String id) async {
    final repo = ref.read(eventsRepositoryProvider);
    await repo.deleteEvent(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((e) => e.id != id).toList());
  }

  Future<void> setActiveEvent(String id) async {
    final repo = ref.read(eventsRepositoryProvider);
    await repo.setActiveEvent(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData([
      for (final e in current)
        if (e.id == id)
          e.copyWith(isActive: true)
        else
          e.copyWith(isActive: false),
    ]);
  }
}

/// Retrieve a single event by its id from the async events list.
final getEventByIdProvider = Provider.family<Event?, String>((ref, eventId) {
  final eventsAsync = ref.watch(eventsProvider);
  return eventsAsync.whenOrNull(
    data: (events) {
      try {
        return events.firstWhere((e) => e.id == eventId);
      } catch (_) {
        return null;
      }
    },
  );
});
