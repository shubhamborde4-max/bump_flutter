import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bump/providers/app_state.dart';
import 'package:bump/providers/auth_provider.dart';
import 'package:bump/providers/profile_provider.dart';
import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/providers/events_provider.dart';
import 'package:bump/providers/nudges_provider.dart';
import 'package:bump/services/notification_service.dart';

// ── Colors ──────────────────────────────────────────────────────────────────
const _primary = Color(0xFF5341CD);
const _accent = Color(0xFF6C5CE7);
const _background = Color(0xFFF8F9FE);
const _surface = Color(0xFFFFFFFF);
const _surfaceLight = Color(0xFFF2F3F8);
const _textPrimary = Color(0xFF191C1F);
const _textSecondary = Color(0xFF474554);
const _textMuted = Color(0xFF787586);
const _error = Color(0xFFBA1A1A);
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

// ── Profile Screen ──────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final prospects = ref.watch(prospectsProvider).valueOrNull ?? [];
    final events = ref.watch(eventsProvider).valueOrNull ?? [];
    final nudgeHistory = ref.watch(nudgesProvider).valueOrNull ?? [];

    return profileAsync.when(
      loading: () => Scaffold(
        backgroundColor: _background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: _error),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(profileNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        final firstName = user?.firstName ?? '';
        final lastName = user?.lastName ?? '';
        final title = user?.title ?? '';
        final company = user?.company ?? '';
        final email = user?.email ?? '';
        final phone = user?.phone ?? '';

        final totalBumps = prospects.length;
        final totalEvents = events.length;
        final totalConnections = nudgeHistory.length;

        return Scaffold(
          backgroundColor: _background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Profile',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card preview with gradient
                  _buildCardPreview(
                    firstName: firstName,
                    lastName: lastName,
                    title: title,
                    company: company,
                    email: email,
                    phone: phone,
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      _buildStatItem('$totalBumps', 'Total Bumps'),
                      const SizedBox(width: 12),
                      _buildStatItem('$totalEvents', 'Events'),
                      const SizedBox(width: 12),
                      _buildStatItem('$totalConnections', 'Connections'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Settings section
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: LucideIcons.edit3,
                          label: 'Edit Profile',
                          onTap: () {},
                        ),
                        _SettingsRow(
                          icon: LucideIcons.wallet,
                          label: 'Card Style',
                          onTap: () {},
                        ),
                        _SettingsRow(
                          icon: LucideIcons.bell,
                          label: 'Notifications',
                          onTap: () {},
                        ),
                        _SettingsRow(
                          icon: LucideIcons.shield,
                          label: 'Privacy',
                          onTap: () {},
                        ),
                        _SettingsRow(
                          icon: LucideIcons.helpCircle,
                          label: 'Help',
                          onTap: () {},
                        ),
                        _SettingsRow(
                          icon: LucideIcons.info,
                          label: 'About',
                          onTap: () {},
                        ),
                        _SettingsRow(
                          icon: LucideIcons.logOut,
                          label: 'Sign Out',
                          danger: true,
                          showChevron: false,
                          onTap: () => _handleSignOut(context, ref),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Bump',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Made with love in India',
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardPreview({
    required String firstName,
    required String lastName,
    required String title,
    required String company,
    required String email,
    required String phone,
  }) {
    final gradient = _getAvatarGradient('$firstName$lastName');
    final initials = _getInitials(firstName, lastName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
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
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.edit3,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.edit3,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Edit Card',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
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

  void _handleSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(),
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: _textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Deactivate FCM token before signing out
                await NotificationService.deactivateCurrentToken();

                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.signOut();

                if (context.mounted) {
                  context.go('/auth');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign out failed: $e'),
                      backgroundColor: Colors.red.shade600,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                color: _error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Row ────────────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool showChevron;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Color(0x0A000000))),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: danger ? _error : _textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: danger ? _error : _textPrimary,
                ),
              ),
            ),
            if (showChevron)
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: _textMuted),
          ],
        ),
      ),
    );
  }
}
