import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/providers/events_provider.dart';
import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/providers/nudges_provider.dart';
import 'package:bump/providers/templates_provider.dart';
import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/data/models/event_model.dart';
import 'package:bump/data/models/nudge_model.dart';
import 'package:bump/data/models/template_model.dart';

// ── Colors ──────────────────────────────────────────────────────────────────
const _primary = Color(0xFF5341CD);
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

// ── Fallback templates (used when Supabase has none) ────────────────────────
String _generateFallbackMessage(int index, Prospect prospect, Event? event) {
  final firstName = prospect.firstName;
  final eventName = event?.name ?? 'the event';
  final notes = prospect.notes;

  switch (index) {
    case 0:
      final notePart = notes.isNotEmpty
          ? ' about ${notes.split('.')[0].toLowerCase()}'
          : '';
      return 'Hey $firstName! Great meeting you at $eventName. Loved our conversation$notePart. Would love to stay connected!';
    case 1:
      final notePart = notes.isNotEmpty ? '$notes\n\n' : '';
      return 'Hi $firstName,\n\nIt was a pleasure connecting with you at $eventName. ${notePart}I would love to schedule a quick call to explore how we can work together. What does your calendar look like this week?\n\nBest regards';
    default:
      final notePart = notes.isNotEmpty
          ? ' and discussed ${notes.split('.')[0].toLowerCase()}'
          : '';
      return 'Hi $firstName,\n\nHope you have been well! We connected at $eventName a while back$notePart. I wanted to circle back and see if there is still interest in exploring this further.\n\nWould love to reconnect!';
  }
}

// ── Public function to show the nudge sheet ─────────────────────────────────
void showNudgeSheet(
  BuildContext context,
  WidgetRef ref,
  Prospect prospect, {
  Event? event,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NudgeSheetContent(prospect: prospect, event: event),
  );
}

// ── Nudge Sheet Content ─────────────────────────────────────────────────────
class _NudgeSheetContent extends ConsumerStatefulWidget {
  final Prospect prospect;
  final Event? event;

  const _NudgeSheetContent({required this.prospect, this.event});

  @override
  ConsumerState<_NudgeSheetContent> createState() =>
      _NudgeSheetContentState();
}

class _NudgeSheetContentState extends ConsumerState<_NudgeSheetContent> {
  int _selectedTemplate = 0;
  late TextEditingController _messageCtrl;
  String _selectedChannel = 'whatsapp';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  void _generateMessage(List<Template> templates) {
    final event = widget.event ??
        ref.read(getEventByIdProvider(widget.prospect.eventId));

    if (templates.isNotEmpty && _selectedTemplate < templates.length) {
      // Use template message with variable substitution
      var message = templates[_selectedTemplate].message;
      message = message.replaceAll('{firstName}', widget.prospect.firstName);
      message = message.replaceAll(
          '{eventName}', event?.name ?? 'the event');
      message =
          message.replaceAll('{notes}', widget.prospect.notes);
      _messageCtrl.text = message;
    } else {
      // Fallback
      _messageCtrl.text = _generateFallbackMessage(
          _selectedTemplate, widget.prospect, event);
    }
  }

  NudgeType _channelToNudgeType(String channel) {
    switch (channel) {
      case 'email':
        return NudgeType.email;
      case 'sms':
        return NudgeType.sms;
      default:
        return NudgeType.whatsapp;
    }
  }

  Future<void> _handleSend() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    final now = DateTime.now();
    final nudge = Nudge(
      id: '',
      prospectId: widget.prospect.id,
      type: _channelToNudgeType(_selectedChannel),
      message: _messageCtrl.text,
      sentAt: now,
      status: NudgeStatus.sent,
    );

    try {
      // Save nudge to Supabase FIRST
      await ref.read(nudgesProvider.notifier).sendNudge(nudge);

      // THEN launch the deep link
      switch (_selectedChannel) {
        case 'whatsapp':
          final phone = widget.prospect.phone
              .replaceAll(RegExp(r'\s+'), '')
              .replaceAll('+', '');
          final encoded = Uri.encodeComponent(_messageCtrl.text);
          final url = 'https://wa.me/$phone?text=$encoded';
          await launchUrl(Uri.parse(url)).catchError((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('WhatsApp not available'),
                  backgroundColor: const Color(0xFFBA1A1A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
            return false;
          });
          break;
        case 'email':
          final email = widget.prospect.email;
          final subject = Uri.encodeComponent(
              'Following up - ${widget.prospect.firstName}');
          final body = Uri.encodeComponent(_messageCtrl.text);
          await launchUrl(
              Uri.parse('mailto:$email?subject=$subject&body=$body'));
          break;
        case 'sms':
          final phone = widget.prospect.phone;
          final body = Uri.encodeComponent(_messageCtrl.text);
          await launchUrl(Uri.parse('sms:$phone?body=$body'));
          break;
      }

      // Update prospect status to 'contacted' after sending
      if (widget.prospect.status == ProspectStatus.newProspect) {
        await ref
            .read(prospectsProvider.notifier)
            .updateProspectStatus(
                widget.prospect.id, 'contacted');
      }

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nudge sent! Status updated.'),
            backgroundColor: _success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send nudge: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.prospect.firstName;
    final lastName = widget.prospect.lastName;
    final gradient = _getAvatarGradient('$firstName$lastName');
    final initials = _getInitials(firstName, lastName);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final templatesAsync = ref.watch(templatesProvider);
    final templates = templatesAsync.valueOrNull ?? [];

    // Generate message on first build or when templates load
    if (_messageCtrl.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _generateMessage(templates);
      });
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8C4D7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Send Nudge to $firstName',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(LucideIcons.x,
                      size: 24, color: _textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recipient row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$firstName $lastName',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Template selector (horizontal scroll)
            SizedBox(
              height: 72,
              child: templates.isEmpty
                  ? _buildFallbackTemplateSelector()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: templates.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final template = templates[i];
                        final isActive = _selectedTemplate == i;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTemplate = i;
                              _generateMessage(templates);
                            });
                          },
                          child: Container(
                            width: 130,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _surfaceLight,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? _primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  template.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  template.message.length > 30
                                      ? '${template.message.substring(0, 30)}...'
                                      : template.message,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: _textMuted,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Message editor
            TextField(
              controller: _messageCtrl,
              maxLines: null,
              minLines: 5,
              cursorColor: _primary,
              style: GoogleFonts.inter(
                  fontSize: 14, color: _textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: _surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_messageCtrl.text.length} characters',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Channel selector icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ChannelButton(
                  icon: LucideIcons.messageCircle,
                  label: 'WhatsApp',
                  color: _whatsapp,
                  isSelected: _selectedChannel == 'whatsapp',
                  onTap: () =>
                      setState(() => _selectedChannel = 'whatsapp'),
                ),
                const SizedBox(width: 16),
                _ChannelButton(
                  icon: LucideIcons.mail,
                  label: 'Email',
                  color: _warning,
                  isSelected: _selectedChannel == 'email',
                  onTap: () =>
                      setState(() => _selectedChannel = 'email'),
                ),
                const SizedBox(width: 16),
                _ChannelButton(
                  icon: LucideIcons.smartphone,
                  label: 'SMS',
                  color: _info,
                  isSelected: _selectedChannel == 'sms',
                  onTap: () =>
                      setState(() => _selectedChannel = 'sms'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Send Nudge button
            _GradientButton(
              title: _isSending ? 'Sending...' : 'Send Nudge',
              icon: LucideIcons.send,
              onPressed: _isSending ? null : _handleSend,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackTemplateSelector() {
    final fallbackNames = [
      'Quick Follow-up',
      'Meeting Request',
      'Introduction'
    ];
    final fallbackPreviews = [
      'Hey! Great meeting you at...',
      'Following up from our...',
      "Been a while since we...",
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: fallbackNames.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        final isActive = _selectedTemplate == i;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTemplate = i;
              _generateMessage([]);
            });
          },
          child: Container(
            width: 130,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? _primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fallbackNames[i],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  fallbackPreviews[i],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Channel Button ──────────────────────────────────────────────────────────
class _ChannelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : _surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? color : _textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient Button ─────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;

  const _GradientButton({
    required this.title,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : const LinearGradient(
                  colors: _heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: disabled ? _surfaceLight : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
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
