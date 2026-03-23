import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/providers/events_provider.dart';
import 'package:bump/providers/nudges_provider.dart';
import 'package:bump/providers/analytics_provider.dart';
import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/data/models/nudge_model.dart';
import 'package:bump/services/export_service.dart';

// ── Colors ──────────────────────────────────────────────────────────────────
const _primary = Color(0xFF5341CD);
const _accent = Color(0xFF6C5CE7);
const _background = Color(0xFFF8F9FE);
const _surface = Color(0xFFFFFFFF);
const _surfaceLight = Color(0xFFF2F3F8);
const _textPrimary = Color(0xFF191C1F);
const _textSecondary = Color(0xFF474554);
const _textMuted = Color(0xFF787586);
const _success = Color(0xFF00C853);
const _warning = Color(0xFFFF9100);
const _info = Color(0xFF0091EA);
const _whatsapp = Color(0xFF25D366);
const _heroGradient = [Color(0xFF6C5CE7), Color(0xFF00D2FF)];

const _statusColors = {
  'new': Color(0xFF00677F),
  'contacted': Color(0xFFFF9100),
  'interested': Color(0xFFE65100),
  'converted': Color(0xFF00C853),
};

const _statusLabels = {
  'new': 'New',
  'contacted': 'Contacted',
  'interested': 'Interested',
  'converted': 'Converted',
};

const _avatarGradients = [
  [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
  [Color(0xFF00D2FF), Color(0xFF448AFF)],
  [Color(0xFFFF5252), Color(0xFFFF7675)],
  [Color(0xFF00E676), Color(0xFF69F0AE)],
  [Color(0xFFFFAB40), Color(0xFFFFD740)],
  [Color(0xFFE040FB), Color(0xFFEA80FC)],
];

List<Color> _getAvatarGradient(String name) {
  int hash = 0;
  for (int i = 0; i < name.length; i++) {
    hash = name.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return _avatarGradients[hash.abs() % _avatarGradients.length];
}

String _getInitials(String? first, String? last) {
  return '${(first ?? '').isNotEmpty ? first![0] : ''}${(last ?? '').isNotEmpty ? last![0] : ''}'
      .toUpperCase();
}

// ── Analytics Screen ────────────────────────────────────────────────────────
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedPeriod = '30 Days';
  bool _isExporting = false;

  DateTime? _getCutoffDate() {
    switch (_selectedPeriod) {
      case '30 Days':
        return DateTime.now().subtract(const Duration(days: 30));
      case '90 Days':
        return DateTime.now().subtract(const Duration(days: 90));
      case 'All Time':
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prospectsAsync = ref.watch(prospectsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final nudgesAsync = ref.watch(nudgesProvider);

    // Check if any provider is loading
    final isLoading = prospectsAsync.isLoading ||
        eventsAsync.isLoading ||
        nudgesAsync.isLoading;

    if (isLoading) {
      return Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 40),
                const Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final analytics = ref.watch(analyticsProvider);
    final cutoff = _getCutoffDate();

    // Filter prospects by period
    final filteredProspects = cutoff != null
        ? analytics.allProspects
            .where((p) => p.exchangeTime.isAfter(cutoff))
            .toList()
        : analytics.allProspects;

    // Filter nudges by period (using sentAt)
    final filteredNudges = cutoff != null
        ? analytics.allNudges
            .where((n) => n.sentAt.isAfter(cutoff))
            .toList()
        : analytics.allNudges;

    // Compute filtered stats
    final totalContacts = filteredProspects.length;
    final totalEvents = cutoff != null
        ? analytics.allEvents
            .where((e) => e.date.isAfter(cutoff))
            .length
        : analytics.allEvents.length;
    final nudgesSent = filteredNudges.length;

    final respondedNudges = filteredNudges
        .where((n) =>
            n.status == NudgeStatus.read || n.status == NudgeStatus.replied)
        .length;
    final responseRate = filteredNudges.isNotEmpty
        ? (respondedNudges / filteredNudges.length * 100).round()
        : 0;

    final convertedCount = filteredProspects
        .where((p) => p.status == ProspectStatus.converted)
        .length;
    final conversionRate = filteredProspects.isNotEmpty
        ? (convertedCount / filteredProspects.length * 100).round()
        : 0;

    // Pipeline data
    final pipelineData = <String, int>{};
    for (final status in ['new', 'contacted', 'interested', 'converted']) {
      pipelineData[status] =
          filteredProspects.where((p) => p.status.label == status).length;
    }

    // Event comparison
    final eventChartData = analytics.allEvents
        .map((e) {
          final count =
              filteredProspects.where((p) => p.eventId == e.id).length;
          final name = e.name;
          return {
            'label': name.length > 20 ? '${name.substring(0, 20)}...' : name,
            'value': count,
          };
        })
        .where((e) => (e['value'] as int) > 0)
        .toList()
      ..sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));

    // Top prospects (filtered)
    final prospectNudgeCounts = <String, int>{};
    for (final n in filteredNudges) {
      prospectNudgeCounts[n.prospectId] =
          (prospectNudgeCounts[n.prospectId] ?? 0) + 1;
    }
    final topProspects = filteredProspects
        .map((p) {
          final nudgeCount = prospectNudgeCounts[p.id] ?? 0;
          return _EngagedProspect(prospect: p, nudgeCount: nudgeCount);
        })
        .where((ep) => ep.nudgeCount > 0)
        .toList()
      ..sort((a, b) => b.nudgeCount.compareTo(a.nudgeCount));
    final top5 = topProspects.take(5).toList();

    // Check if everything is empty
    final isEmpty = totalContacts == 0 && nudgesSent == 0 && totalEvents == 0;

    if (isEmpty && _selectedPeriod == 'All Time') {
      return _buildEmptyFullScreen();
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with export button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analytics',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isExporting
                        ? null
                        : () => _exportCSV(filteredProspects),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primary,
                              ),
                            )
                          : const Icon(
                              LucideIcons.download,
                              size: 18,
                              color: _primary,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Period selector
              Row(
                children:
                    ['30 Days', '90 Days', 'All Time'].map((period) {
                  final isActive = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPeriod = period),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              isActive ? _primary : _surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          period,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : _textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Stats grid (2x2 + 1)
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Contacts',
                      value: '$totalContacts',
                      icon: LucideIcons.users,
                      iconColor: const Color(0xFF00D2FF),
                      trend: totalContacts > 0 ? '+$totalContacts' : null,
                      index: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Events Attended',
                      value: '$totalEvents',
                      icon: LucideIcons.calendar,
                      iconColor: _accent,
                      index: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Nudges Sent',
                      value: '$nudgesSent',
                      icon: LucideIcons.messageCircle,
                      iconColor: _primary,
                      index: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Response Rate',
                      value: '$responseRate%',
                      icon: LucideIcons.trendingUp,
                      iconColor: _success,
                      index: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: 'Conversion Rate',
                value: '$conversionRate%',
                icon: LucideIcons.target,
                iconColor: _warning,
                index: 4,
              ),
              const SizedBox(height: 24),

              // Pipeline section
              _buildSection(
                title: 'Pipeline',
                delay: 400,
                child: pipelineData.values.every((v) => v == 0)
                    ? _buildEmptySection('No prospect data yet')
                    : _PipelineChart(data: pipelineData),
              ),
              const SizedBox(height: 16),

              // Event comparison
              _buildSection(
                title: 'Event Comparison',
                delay: 500,
                child: eventChartData.isEmpty
                    ? _buildEmptySection('No event data yet')
                    : Column(
                        children: eventChartData
                            .asMap()
                            .entries
                            .map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          final maxVal = eventChartData.isNotEmpty
                              ? eventChartData
                                  .map((e) => e['value'] as int)
                                  .reduce(
                                      (a, b) => a > b ? a : b)
                              : 1;
                          final fraction =
                              (item['value'] as int) /
                                  max(maxVal, 1);
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: i <
                                        eventChartData.length - 1
                                    ? 12
                                    : 0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    item['label'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w500,
                                      color: _textSecondary,
                                      letterSpacing: 0.3,
                                    ),
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _AnimatedBar(
                                      fraction: fraction),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    '${item['value']}',
                                    textAlign:
                                        TextAlign.right,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: _textPrimary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),

              // Most Engaged Prospects
              _buildSection(
                title: 'Most Engaged Prospects',
                delay: 600,
                child: top5.isEmpty
                    ? _buildEmptySection('No nudge data yet')
                    : Column(
                        children: top5.map((ep) {
                          final firstName = ep.prospect.firstName;
                          final lastName = ep.prospect.lastName;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Color(0x0A000000)),
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildAvatar(
                                    firstName, lastName, 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$firstName $lastName',
                                        style:
                                            GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      Text(
                                        ep.prospect.company,
                                        style:
                                            GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w500,
                                          color:
                                              _textSecondary,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${ep.nudgeCount} nudges',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: _primary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCSV(List<Prospect> prospects) async {
    setState(() => _isExporting = true);
    try {
      final service = ExportService();
      final csvData = service.exportProspectsToCSV(prospects);
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await service.saveAndShareCSV(csvData, 'bump_contacts_$timestamp.csv');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildEmptyFullScreen() {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.barChart2,
                        size: 36,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No analytics data yet',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start networking at events and exchanging\ncontacts to see your analytics here.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, color: _textMuted),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required int delay,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: delay),
          duration: const Duration(milliseconds: 400),
        ).slideY(begin: 0.05, end: 0);
  }

  Widget _buildAvatar(String firstName, String lastName, double size) {
    final initials = _getInitials(firstName, lastName);
    final gradient = _getAvatarGradient('$firstName$lastName');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Helper class for engaged prospects ───────────────────────────────────────
class _EngagedProspect {
  final Prospect prospect;
  final int nudgeCount;

  const _EngagedProspect(
      {required this.prospect, required this.nudgeCount});
}

// ── Stat Card ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? trend;
  final int index;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.trend,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: iconColor),
              if (trend != null)
                Text(
                  trend!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _success,
                    letterSpacing: 0.3,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: index * 100),
          duration: const Duration(milliseconds: 400),
        ).slideY(begin: 0.1, end: 0);
  }
}

// ── Pipeline Chart ──────────────────────────────────────────────────────────
class _PipelineChart extends StatelessWidget {
  final Map<String, int> data;

  const _PipelineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.isEmpty
        ? 1
        : data.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: data.entries.map((entry) {
        final color = _statusColors[entry.key] ?? _textMuted;
        final label = _statusLabels[entry.key] ?? entry.key;
        final fraction = entry.value / max(maxVal, 1);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: _surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction.clamp(0.02, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '${entry.value}',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Animated Bar ────────────────────────────────────────────────────────────
class _AnimatedBar extends StatelessWidget {
  final double fraction;

  const _AnimatedBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: _surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth *
                  fraction.clamp(0.02, 1.0),
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: _heroGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}
