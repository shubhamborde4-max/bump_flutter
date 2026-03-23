import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/data/models/event_model.dart';
import 'package:bump/data/models/nudge_model.dart';
import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/providers/events_provider.dart';
import 'package:bump/providers/nudges_provider.dart';

class AnalyticsData {
  final int totalContacts;
  final int totalEvents;
  final int totalNudgesSent;
  final int responseRate;
  final int conversionRate;
  final Map<String, int> statusBreakdown;
  final Map<String, int> contactsPerEvent;
  final Map<String, int> contactsOverTime;
  final List<TopProspect> topProspects;
  final List<Prospect> allProspects;
  final List<Event> allEvents;
  final List<Nudge> allNudges;

  const AnalyticsData({
    required this.totalContacts,
    required this.totalEvents,
    required this.totalNudgesSent,
    required this.responseRate,
    required this.conversionRate,
    required this.statusBreakdown,
    required this.contactsPerEvent,
    required this.contactsOverTime,
    required this.topProspects,
    required this.allProspects,
    required this.allEvents,
    required this.allNudges,
  });
}

class TopProspect {
  final Prospect prospect;
  final int nudgeCount;

  const TopProspect({required this.prospect, required this.nudgeCount});
}

final analyticsProvider = Provider<AnalyticsData>((ref) {
  final prospectsAsync = ref.watch(prospectsProvider);
  final eventsAsync = ref.watch(eventsProvider);
  final nudgesAsync = ref.watch(nudgesProvider);

  final prospects = prospectsAsync.valueOrNull ?? [];
  final events = eventsAsync.valueOrNull ?? [];
  final nudges = nudgesAsync.valueOrNull ?? [];

  // Total counts
  final totalContacts = prospects.length;
  final totalEvents = events.length;
  final totalNudgesSent = nudges.length;

  // Response rate: nudges with status 'read' or 'replied' / total nudges
  final respondedNudges = nudges
      .where((n) =>
          n.status == NudgeStatus.read || n.status == NudgeStatus.replied)
      .length;
  final responseRate = nudges.isNotEmpty
      ? (respondedNudges / nudges.length * 100).round()
      : 0;

  // Conversion rate: prospects with status 'converted' / total prospects
  final convertedCount =
      prospects.where((p) => p.status == ProspectStatus.converted).length;
  final conversionRate = prospects.isNotEmpty
      ? (convertedCount / prospects.length * 100).round()
      : 0;

  // Status breakdown
  final statusBreakdown = <String, int>{};
  for (final status in ['new', 'contacted', 'interested', 'converted']) {
    statusBreakdown[status] =
        prospects.where((p) => p.status.label == status).length;
  }

  // Contacts per event
  final contactsPerEvent = <String, int>{};
  for (final event in events) {
    final count = prospects.where((p) => p.eventId == event.id).length;
    contactsPerEvent[event.name] = count;
  }

  // Contacts over time (grouped by month)
  final contactsOverTime = <String, int>{};
  final monthFormat = DateFormat('MMM yyyy');
  for (final p in prospects) {
    final key = monthFormat.format(p.exchangeTime);
    contactsOverTime[key] = (contactsOverTime[key] ?? 0) + 1;
  }

  // Top prospects (most nudges sent to)
  final prospectNudgeCounts = <String, int>{};
  for (final n in nudges) {
    prospectNudgeCounts[n.prospectId] =
        (prospectNudgeCounts[n.prospectId] ?? 0) + 1;
  }

  final topProspects = prospects
      .map((p) {
        final nudgeCount = prospectNudgeCounts[p.id] ?? 0;
        return TopProspect(prospect: p, nudgeCount: nudgeCount);
      })
      .where((tp) => tp.nudgeCount > 0)
      .toList()
    ..sort((a, b) => b.nudgeCount.compareTo(a.nudgeCount));

  return AnalyticsData(
    totalContacts: totalContacts,
    totalEvents: totalEvents,
    totalNudgesSent: totalNudgesSent,
    responseRate: responseRate,
    conversionRate: conversionRate,
    statusBreakdown: statusBreakdown,
    contactsPerEvent: contactsPerEvent,
    contactsOverTime: contactsOverTime,
    topProspects: topProspects.take(5).toList(),
    allProspects: prospects,
    allEvents: events,
    allNudges: nudges,
  );
});
