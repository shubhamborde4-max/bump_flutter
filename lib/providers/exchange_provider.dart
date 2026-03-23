import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bump/data/repositories/exchange_repository.dart';
import 'package:bump/data/repositories_impl/supabase_exchange_repository.dart';
import 'package:bump/data/models/event_model.dart';
import 'package:bump/providers/events_provider.dart';

/// Provides the [ExchangeRepository] backed by Supabase.
final exchangeRepositoryProvider = Provider<ExchangeRepository>((ref) {
  return SupabaseExchangeRepository();
});

/// Returns the current active event (if any).
final activeEventProvider = Provider<Event?>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  return eventsAsync.whenOrNull(
    data: (events) {
      try {
        return events.firstWhere((e) => e.isActive);
      } catch (_) {
        return events.isNotEmpty ? events.first : null;
      }
    },
  );
});
