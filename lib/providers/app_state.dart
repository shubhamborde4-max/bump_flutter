import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/providers/events_provider.dart';
import 'package:bump/providers/nudges_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Auth / Onboarding state
// ═══════════════════════════════════════════════════════════════════════════

class BoolNotifier extends StateNotifier<bool> {
  BoolNotifier(super.initial);

  void set(bool value) => state = value;
  void toggle() => state = !state;
}

final isAuthenticatedProvider =
    StateNotifierProvider<BoolNotifier, bool>((ref) => BoolNotifier(false));

final hasCompletedOnboardingProvider =
    StateNotifierProvider<BoolNotifier, bool>((ref) => BoolNotifier(false));

final hasCompletedSetupProvider =
    StateNotifierProvider<BoolNotifier, bool>((ref) => BoolNotifier(false));

// ═══════════════════════════════════════════════════════════════════════════
// Aggregate / Derived Stats
// ═══════════════════════════════════════════════════════════════════════════

class TotalStats {
  final int totalBumps;
  final int totalNudges;
  final int totalEvents;
  final int activeEvents;
  final double conversionRate;
  final Map<String, int> statusBreakdown;

  const TotalStats({
    required this.totalBumps,
    required this.totalNudges,
    required this.totalEvents,
    required this.activeEvents,
    required this.conversionRate,
    required this.statusBreakdown,
  });
}

final totalStatsProvider = Provider<TotalStats>((ref) {
  final prospectsAsync = ref.watch(prospectsProvider);
  final nudgesAsync = ref.watch(nudgesProvider);
  final eventsAsync = ref.watch(eventsProvider);

  final prospects = prospectsAsync.valueOrNull ?? [];
  final nudges = nudgesAsync.valueOrNull ?? [];
  final events = eventsAsync.valueOrNull ?? [];

  final statusBreakdown = <String, int>{};
  for (final p in prospects) {
    final key = p.status.label;
    statusBreakdown[key] = (statusBreakdown[key] ?? 0) + 1;
  }

  final converted = statusBreakdown['converted'] ?? 0;
  final conversionRate =
      prospects.isEmpty ? 0.0 : (converted / prospects.length) * 100;

  return TotalStats(
    totalBumps: prospects.length,
    totalNudges: nudges.length,
    totalEvents: events.length,
    activeEvents: events.where((e) => e.isActive).length,
    conversionRate: conversionRate,
    statusBreakdown: statusBreakdown,
  );
});
