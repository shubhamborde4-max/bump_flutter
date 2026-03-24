import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/providers/events_provider.dart';
import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/data/models/event_model.dart';
import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/screens/nudge_sheet.dart';
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
const _whatsapp = Color(0xFF25D366);
const _info = Color(0xFF0091EA);
const _warning = Color(0xFFFF9100);

const _statusColors = {
  'new': Color(0xFF00677F),
  'contacted': Color(0xFFFF9100),
  'interested': Color(0xFFE65100),
  'converted': Color(0xFF00C853),
  'archived': Color(0xFF787586),
};

const _statusLabels = {
  'new': 'New',
  'contacted': 'Contacted',
  'interested': 'Interested',
  'converted': 'Converted',
  'archived': 'Archived',
};

const _heroGradient = [Color(0xFF6C5CE7), Color(0xFF00D2FF)];

// ── Filter options ──────────────────────────────────────────────────────────
const _filterOptions = [
  {'key': 'all', 'label': 'All'},
  {'key': 'new', 'label': 'New'},
  {'key': 'contacted', 'label': 'Contacted'},
  {'key': 'interested', 'label': 'Interested'},
  {'key': 'converted', 'label': 'Converted'},
  {'key': 'archived', 'label': 'Archived'},
];

// ── Helpers ─────────────────────────────────────────────────────────────────
String _formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

String _formatTime(DateTime date) {
  return DateFormat('h:mm a').format(date);
}

String _getInitials(String? first, String? last) {
  return '${(first ?? '').isNotEmpty ? first![0] : ''}${(last ?? '').isNotEmpty ? last![0] : ''}'
      .toUpperCase();
}

// ── Avatar gradients ────────────────────────────────────────────────────────
const _avatarGradients = [
  [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
  [Color(0xFF00D2FF), Color(0xFF448AFF)],
  [Color(0xFFFF5252), Color(0xFFFF7675)],
  [Color(0xFF00E676), Color(0xFF69F0AE)],
  [Color(0xFFFFAB40), Color(0xFFFFD740)],
  [Color(0xFFE040FB), Color(0xFFEA80FC)],
  [Color(0xFFFF6E40), Color(0xFFFFAB40)],
  [Color(0xFF18FFFF), Color(0xFF00E5FF)],
];

List<Color> _getAvatarGradient(String name) {
  int hash = 0;
  for (int i = 0; i < name.length; i++) {
    hash = name.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return _avatarGradients[hash.abs() % _avatarGradients.length];
}

// ── Event Detail Screen ─────────────────────────────────────────────────────
class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  String _activeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final prospectsAsync = ref.watch(prospectsProvider);

    return eventsAsync.when(
      loading: () => Scaffold(
        backgroundColor: _background,
        body: const Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading event',
                  style: GoogleFonts.inter(color: _textPrimary)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => ref.invalidate(eventsProvider),
                child: Text('Retry',
                    style: GoogleFonts.inter(
                        color: _primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
      data: (events) {
        final event = events.where((e) => e.id == widget.eventId).firstOrNull;

        if (event == null) {
          return Scaffold(
            backgroundColor: _background,
            body: Center(
              child: Text('Event not found',
                  style: GoogleFonts.inter(color: _textPrimary)),
            ),
          );
        }

        final allProspects = prospectsAsync.valueOrNull ?? [];
        final eventProspects = allProspects
            .where((p) => p.eventId == widget.eventId)
            .toList();

        final filteredProspects = _activeFilter == 'all'
            ? eventProspects
            : eventProspects
                .where((p) => p.status.label == _activeFilter)
                .toList();

        int getFilterCount(String key) {
          if (key == 'all') return eventProspects.length;
          return eventProspects
              .where((p) => p.status.label == key)
              .length;
        }

        final convertedCount = eventProspects
            .where((p) => p.status == ProspectStatus.converted)
            .length;

        return Scaffold(
          backgroundColor: _background,
          floatingActionButton: _buildEventActionsFab(event),
          body: RefreshIndicator(
            color: _primary,
            onRefresh: () async {
              await ref.read(eventsProvider.notifier).loadEvents();
              await ref
                  .read(prospectsProvider.notifier)
                  .loadProspects();
            },
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nav row
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: const Icon(
                                  LucideIcons.chevronLeft,
                                  size: 24,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      event.location,
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
                              GestureDetector(
                                onTap: () => _exportEventProspects(
                                    eventProspects, event.name),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _surfaceLight,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    LucideIcons.download,
                                    size: 18,
                                    color: _primary,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 400.ms).slideY(
                              begin: -0.1, end: 0),
                          const SizedBox(height: 16),

                          // Stats row
                          Row(
                            children: [
                              _StatBox(
                                icon: LucideIcons.users,
                                iconColor: const Color(0xFF00D2FF),
                                value: '${eventProspects.length}',
                                label: 'Contacts',
                              ),
                              const SizedBox(width: 12),
                              _StatBox(
                                icon: LucideIcons.zap,
                                iconColor: _primary,
                                value: '${event.nudgesSent}',
                                label: 'Nudges',
                              ),
                              const SizedBox(width: 12),
                              _StatBox(
                                icon: LucideIcons.arrowUpRight,
                                iconColor: _success,
                                value: '$convertedCount',
                                label: 'Converted',
                              ),
                            ],
                          ).animate().fadeIn(
                              delay: 100.ms, duration: 400.ms),
                          const SizedBox(height: 16),

                          // Filter chips
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filterOptions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final f = _filterOptions[index];
                                final key = f['key']!;
                                final isActive =
                                    _activeFilter == key;
                                final count = getFilterCount(key);
                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _activeFilter = key),
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 200),
                                    padding: const EdgeInsets
                                        .symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? _primary
                                          : _surfaceLight,
                                      borderRadius:
                                          BorderRadius.circular(
                                              20),
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        if (key != 'all') ...[
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  _statusColors[
                                                          key] ??
                                                      _textMuted,
                                              shape:
                                                  BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: 6),
                                        ],
                                        Text(
                                          '${f['label']} ($count)',
                                          style:
                                              GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: isActive
                                                ? Colors.white
                                                : _textSecondary,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // Prospect list or empty state
                if (filteredProspects.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final prospect = filteredProspects[index];
                          return _ProspectCard(
                            prospect: prospect,
                            event: event,
                            index: index,
                            onTap: () => context.push(
                                '/prospects/${prospect.id}'),
                            onNudge: () => showNudgeSheet(
                                context, ref, prospect),
                          );
                        },
                        childCount: filteredProspects.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventActionsFab(Event event) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scan QR
        FloatingActionButton.small(
          heroTag: 'scan_qr',
          backgroundColor: _accent,
          onPressed: () => context.push('/qr-scanner', extra: event.id),
          child: const Icon(LucideIcons.scan, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        // Bump / NFC
        FloatingActionButton.small(
          heroTag: 'nfc_bump',
          backgroundColor: _primary,
          onPressed: () => context.go('/bump'),
          child: const Icon(LucideIcons.zap, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        // Main FAB
        FloatingActionButton.extended(
          heroTag: 'add_contact',
          backgroundColor: _primary,
          onPressed: () => _showAddContactSheet(event),
          icon: const Icon(LucideIcons.userPlus, color: Colors.white),
          label: Text(
            'Add Contact',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddContactSheet(Event event) {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final titleCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Contact',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Met at ${event.name}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _sheetField(firstNameCtrl, 'First Name')),
                  const SizedBox(width: 12),
                  Expanded(child: _sheetField(lastNameCtrl, 'Last Name')),
                ],
              ),
              const SizedBox(height: 12),
              _sheetField(emailCtrl, 'Email'),
              const SizedBox(height: 12),
              _sheetField(phoneCtrl, 'Phone'),
              const SizedBox(height: 12),
              _sheetField(companyCtrl, 'Company'),
              const SizedBox(height: 12),
              _sheetField(titleCtrl, 'Title / Designation'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (firstNameCtrl.text.isEmpty && lastNameCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name is required')),
                      );
                      return;
                    }

                    try {
                      await ref.read(prospectsProvider.notifier).addProspect(
                        firstName: firstNameCtrl.text.trim(),
                        lastName: lastNameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        company: companyCtrl.text.trim(),
                        title: titleCtrl.text.trim(),
                        eventId: event.id,
                        notes: 'Met at ${event.name}',
                        method: 'manual',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Contact added!'),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: Colors.red.shade600,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Add Contact',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: _textMuted),
        filled: true,
        fillColor: _surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: GoogleFonts.inter(fontSize: 14, color: _textPrimary),
    );
  }

  Future<void> _exportEventProspects(
      List<Prospect> prospects, String eventName) async {
    try {
      final service = ExportService();
      final csvData = service.exportProspectsToCSV(prospects);
      final safeName =
          eventName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await service.saveAndShareCSV(
          csvData, 'bump_${safeName}_$timestamp.csv');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(LucideIcons.users, size: 48, color: _primary),
          const SizedBox(height: 16),
          Text(
            'No contacts exchanged yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start bumping phones at the event to collect contacts',
            style: GoogleFonts.inter(fontSize: 14, color: _textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Stat Box ────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Prospect Card ───────────────────────────────────────────────────────────
class _ProspectCard extends StatelessWidget {
  final Prospect prospect;
  final Event event;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onNudge;

  const _ProspectCard({
    required this.prospect,
    required this.event,
    required this.index,
    required this.onTap,
    required this.onNudge,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = prospect.firstName;
    final lastName = prospect.lastName;
    final status = prospect.status.label;
    final statusColor = _statusColors[status] ?? _textMuted;
    final statusLabel = _statusLabels[status] ?? status;
    final notes = prospect.notes;
    final exchangeMethod = prospect.exchangeMethod.displayName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(firstName: firstName, lastName: lastName, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${prospect.title} · ${prospect.company}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"$notes"',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: _textMuted,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(LucideIcons.moreVertical,
                    size: 18, color: _textMuted),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons row
            Row(
              children: [
                _ActionChip(
                  icon: LucideIcons.messageCircle,
                  label: 'Nudge',
                  color: _whatsapp,
                  onTap: onNudge,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: LucideIcons.phone,
                  label: 'Call',
                  color: _info,
                  onTap: () {
                    final phone = prospect.phone;
                    if (phone.isNotEmpty) {
                      launchUrl(Uri.parse('tel:$phone'));
                    }
                  },
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: LucideIcons.mail,
                  label: 'Email',
                  color: _warning,
                  onTap: () {
                    final email = prospect.email;
                    if (email.isNotEmpty) {
                      launchUrl(Uri.parse('mailto:$email'));
                    }
                  },
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: LucideIcons.tag,
                  label: 'Tag',
                  color: _primary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Coming soon!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Footer
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0x10000000)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Met: ${_formatDate(prospect.exchangeTime)}, '
                      '${_formatTime(prospect.exchangeTime)} · via $exchangeMethod',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _textMuted,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: status),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 200 + index * 60),
          duration: const Duration(milliseconds: 400),
        ).slideY(
          begin: 0.05,
          end: 0,
          delay: Duration(milliseconds: 200 + index * 60),
          duration: const Duration(milliseconds: 400),
        );
  }
}

// ── Action Chip ─────────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[status] ?? _textMuted;
    final label = (_statusLabels[status] ?? status).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String firstName;
  final String lastName;
  final double size;
  final String? imageUrl;

  const _Avatar({
    required this.firstName,
    required this.lastName,
    this.size = 48,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(firstName, lastName);
    final gradient = _getAvatarGradient('$firstName$lastName');

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

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
