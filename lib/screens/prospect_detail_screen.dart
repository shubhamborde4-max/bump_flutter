import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/providers/events_provider.dart';
import 'package:bump/providers/nudges_provider.dart';
import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/data/models/nudge_model.dart';
import 'package:bump/screens/nudge_sheet.dart';
import 'package:bump/services/contact_service.dart';

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
const _warning = Color(0xFFFF9100);
const _info = Color(0xFF0091EA);
const _heroGradient = [Color(0xFF6C5CE7), Color(0xFF00D2FF)];

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

String _getInitials(String? first, String? last) {
  return '${(first ?? '').isNotEmpty ? first![0] : ''}${(last ?? '').isNotEmpty ? last![0] : ''}'
      .toUpperCase();
}

String _formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

String _formatTime(DateTime date) {
  return DateFormat('h:mm a').format(date);
}

// ── Prospect Detail Screen ──────────────────────────────────────────────────
class ProspectDetailScreen extends ConsumerStatefulWidget {
  final String prospectId;

  const ProspectDetailScreen({super.key, required this.prospectId});

  @override
  ConsumerState<ProspectDetailScreen> createState() =>
      _ProspectDetailScreenState();
}

class _ProspectDetailScreenState extends ConsumerState<ProspectDetailScreen> {
  final _notesController = TextEditingController();
  bool _editingNotes = false;
  Timer? _debounceTimer;

  // BUG-008: Phone number validation helper
  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleaned);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prospectsAsync = ref.watch(prospectsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final nudgesAsync = ref.watch(nudgesProvider);

    return prospectsAsync.when(
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
              Text('Error loading prospect',
                  style: GoogleFonts.inter(color: _textPrimary)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => ref.invalidate(prospectsProvider),
                child: Text('Retry',
                    style: GoogleFonts.inter(
                        color: _primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
      data: (prospects) {
        final prospect = prospects
            .where((p) => p.id == widget.prospectId)
            .firstOrNull;

        if (prospect == null) {
          return Scaffold(
            backgroundColor: _background,
            body: Center(
              child: Text(
                'Prospect not found',
                style:
                    GoogleFonts.inter(color: _textPrimary, fontSize: 16),
              ),
            ),
          );
        }

        final events = eventsAsync.valueOrNull ?? [];
        final nudges = nudgesAsync.valueOrNull ?? [];

        final event =
            events.where((e) => e.id == prospect.eventId).firstOrNull;

        final prospectNudges = nudges
            .where((n) => n.prospectId == widget.prospectId)
            .toList();

        final firstName = prospect.firstName;
        final lastName = prospect.lastName;
        final status = prospect.status.label;

        if (!_editingNotes) {
          _notesController.text = prospect.notes;
        }

        return Scaffold(
          backgroundColor: _background,
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero section with gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accent.withValues(alpha: 0.3),
                            _background,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            // Back button
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 8, 20, 20),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => context.pop(),
                                    child: const Icon(
                                      LucideIcons.chevronLeft,
                                      size: 24,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Avatar + name
                            _buildAvatar(firstName, lastName, 80),
                            const SizedBox(height: 16),
                            Text(
                              '$firstName $lastName',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${prospect.title} at ${prospect.company}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: _textSecondary,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildStatusBadge(status),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Contact action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ActionCircle(
                            icon: LucideIcons.phone,
                            color: const Color(0xFF00BCD4),
                            label: 'Call',
                            onTap: () {
                              final phone = prospect.phone;
                              if (phone.isEmpty || !_isValidPhone(phone)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Invalid or missing phone number'),
                                    backgroundColor: Colors.red.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                                return;
                              }
                              launchUrl(Uri.parse('tel:$phone'));
                            },
                          ),
                          const SizedBox(width: 24),
                          _ActionCircle(
                            icon: LucideIcons.messageCircle,
                            color: _whatsapp,
                            label: 'WhatsApp',
                            onTap: () => showNudgeSheet(
                                context, ref, prospect),
                          ),
                          const SizedBox(width: 24),
                          _ActionCircle(
                            icon: LucideIcons.mail,
                            color: _warning,
                            label: 'Email',
                            onTap: () {
                              final email = prospect.email;
                              if (email.isNotEmpty) {
                                launchUrl(
                                    Uri.parse('mailto:$email'));
                              }
                            },
                          ),
                          const SizedBox(width: 24),
                          _ActionCircle(
                            icon: LucideIcons.link2,
                            color: _primary,
                            label: 'LinkedIn',
                            onTap: () {
                              final url = prospect.linkedIn;
                              if (url != null && url.isNotEmpty) {
                                launchUrl(Uri.parse(url));
                              }
                            },
                          ),
                          const SizedBox(width: 24),
                          _ActionCircle(
                            icon: LucideIcons.userPlus,
                            color: const Color(0xFF4CAF50),
                            label: 'Save',
                            onTap: () async {
                              final saved = await ContactService.saveToContacts(
                                firstName: prospect.firstName,
                                lastName: prospect.lastName,
                                phone: prospect.phone,
                                email: prospect.email,
                                company: prospect.company,
                                title: prospect.title,
                                linkedIn: prospect.linkedIn,
                                note: prospect.notes,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(saved ? 'Contact saved!' : 'Permission denied'),
                                  backgroundColor: saved ? Colors.green.shade600 : Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(
                        delay: 200.ms, duration: 400.ms),

                    // Info sections
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: Column(
                        children: [
                          // Contact Info card
                          _InfoCard(
                            title: 'CONTACT INFO',
                            children: [
                              if (prospect.phone.isNotEmpty)
                                _InfoRow(
                                  icon: LucideIcons.phone,
                                  label: 'Phone',
                                  value: prospect.phone,
                                  copyable: true,
                                ),
                              if (prospect.email.isNotEmpty)
                                _InfoRow(
                                  icon: LucideIcons.mail,
                                  label: 'Email',
                                  value: prospect.email,
                                  copyable: true,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Company card
                          _InfoCard(
                            title: 'COMPANY',
                            children: [
                              _InfoRow(
                                  label: 'Company',
                                  value: prospect.company),
                              _InfoRow(
                                  label: 'Title',
                                  value: prospect.title),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // LinkedIn
                          if (prospect.linkedIn != null &&
                              prospect.linkedIn!.isNotEmpty) ...[
                            _InfoCard(
                              title: 'SOCIAL LINKS',
                              children: [
                                _InfoRow(
                                  icon: LucideIcons.link2,
                                  label: 'LinkedIn',
                                  value: prospect.linkedIn!,
                                  onTap: () => launchUrl(Uri.parse(
                                      prospect.linkedIn!)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Notes card (editable)
                          _InfoCard(
                            title: 'NOTES',
                            children: [
                              TextField(
                                controller: _notesController,
                                maxLines: null,
                                minLines: 2,
                                maxLength: 2000,
                                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                cursorColor: _primary,
                                onTap: () => setState(
                                    () => _editingNotes = true),
                                onChanged: (val) {
                                  _debounceTimer?.cancel();
                                  _debounceTimer = Timer(const Duration(milliseconds: 800), () {
                                    ref
                                        .read(prospectsProvider
                                            .notifier)
                                        .updateProspect(
                                            prospect.copyWith(
                                                notes: val));
                                  });
                                },
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _textSecondary,
                                  height: 1.57,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add notes...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: _textMuted,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Status selector
                          _InfoCard(
                            title: 'STATUS',
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _statusLabels.entries
                                    .map((entry) {
                                  final isActive =
                                      status == entry.key;
                                  final color =
                                      _statusColors[entry.key]!;
                                  return GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(prospectsProvider
                                              .notifier)
                                          .updateProspectStatus(
                                            widget.prospectId,
                                            entry.key,
                                          );
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? color.withValues(
                                                alpha: 0.15)
                                            : _surfaceLight,
                                        borderRadius:
                                            BorderRadius.circular(
                                                20),
                                        border: Border.all(
                                          color: isActive
                                              ? color
                                              : Colors
                                                  .transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration:
                                                BoxDecoration(
                                              color: color,
                                              shape: BoxShape
                                                  .circle,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: 6),
                                          Text(
                                            entry.value,
                                            style:
                                                GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                              color: isActive
                                                  ? color
                                                  : _textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Exchange Details card
                          _InfoCard(
                            title: 'EXCHANGE DETAILS',
                            children: [
                              _InfoRow(
                                icon: LucideIcons.calendar,
                                label: 'Event',
                                value:
                                    event?.name ?? 'Unknown',
                              ),
                              _InfoRow(
                                icon: LucideIcons.calendar,
                                label: 'Date',
                                value:
                                    '${_formatDate(prospect.exchangeTime)}, ${_formatTime(prospect.exchangeTime)}',
                              ),
                              if (event != null &&
                                  event.location.isNotEmpty)
                                _InfoRow(
                                  icon: LucideIcons.mapPin,
                                  label: 'Location',
                                  value: event.location,
                                ),
                              _InfoRow(
                                icon: LucideIcons.zap,
                                label: 'Method',
                                value: prospect.exchangeMethod
                                    .displayName,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Nudge History
                          _InfoCard(
                            title: 'NUDGE HISTORY',
                            children: [
                              if (prospectNudges.isEmpty)
                                _buildNoNudges(prospect)
                              else
                                _buildTimeline(
                                    prospectNudges),
                            ],
                          ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom CTA bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white.withValues(alpha: 0.95),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0x10000000))),
                  ),
                  child: _GradientButton(
                    title: 'Send Nudge',
                    icon: LucideIcons.send,
                    onPressed: () =>
                        showNudgeSheet(context, ref, prospect),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Widget _buildStatusBadge(String status) {
    final color = _statusColors[status] ?? _textMuted;
    final label = (_statusLabels[status] ?? status).toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoNudges(Prospect prospect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            'No messages sent yet',
            style: GoogleFonts.inter(fontSize: 14, color: _textMuted),
          ),
          const SizedBox(height: 12),
          _GradientButton(
            title: 'Send First Nudge',
            small: true,
            onPressed: () => showNudgeSheet(context, ref, prospect),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<Nudge> nudges) {
    return Column(
      children: nudges.asMap().entries.map((entry) {
        final i = entry.key;
        final nudge = entry.value;
        final isLast = i == nudges.length - 1;
        final channel = nudge.type.displayName;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: _primary.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.messageCircle,
                            size: 12,
                            color: _whatsapp,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$channel message',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nudge.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(nudge.sentAt)} · ${nudge.status.displayName}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: _textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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

// ── Action Circle ───────────────────────────────────────────────────────────
class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card ───────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ── Info Row ────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final bool copyable;
  final VoidCallback? onTap;

  const _InfoRow({
    this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x0A000000))),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: _textMuted),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (copyable)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied!'),
                      backgroundColor: _success,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                child: const Icon(LucideIcons.copy,
                    size: 14, color: _textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient Button ─────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool small;
  final IconData? icon;

  const _GradientButton({
    required this.title,
    this.onPressed,
    this.small = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: small ? 36 : 56,
        padding: small ? const EdgeInsets.symmetric(horizontal: 16) : null,
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : const LinearGradient(
                  colors: _heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: disabled ? _surfaceLight : null,
          borderRadius: BorderRadius.circular(small ? 10 : 14),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color:
                        const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: small ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: small ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
