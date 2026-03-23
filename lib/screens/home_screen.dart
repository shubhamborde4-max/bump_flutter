import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/providers/profile_provider.dart';
import 'package:bump/providers/events_provider.dart';
import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/providers/app_state.dart';
import 'package:bump/data/models/event_model.dart';
import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/data/models/user_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // ── Design tokens ──────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF5341CD);
  static const Color _primaryContainer = Color(0xFF6C5CE7);
  static const Color _secondary = Color(0xFF00677F);
  static const Color _background = Color(0xFFF8F9FE);
  static const Color _surfaceContainerLow = Color(0xFFF2F3F8);
  static const Color _surfaceContainer = Color(0xFFECEEF3);
  static const Color _onSurface = Color(0xFF191C1F);
  static const Color _onSurfaceVariant = Color(0xFF474554);
  static const Color _outlineVariant = Color(0xFFC8C4D7);

  String _timeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final recentProspects = ref.watch(recentProspectsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final stats = ref.watch(totalStatsProvider);

    final user = profileAsync.valueOrNull;
    final events = eventsAsync.valueOrNull ?? [];
    final activeEvents = events.where((e) => e.isActive).toList();

    final firstName = user?.firstName ?? '';
    final fullName = user?.fullName ?? '';
    final userTitle = user?.title ?? '';
    final userEmail = user?.email ?? '';
    final userWebsite = user?.website;

    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          // ── Scrollable content ───────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 96,
              left: 24,
              right: 24,
              bottom: 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome Section ────────────────────────────────────
                _buildWelcomeSection(firstName)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.15, end: 0, duration: 500.ms),

                const SizedBox(height: 48),

                // ── Digital Signature Card ─────────────────────────────
                _buildDigitalCard(
                  fullName: fullName,
                  title: userTitle,
                  email: userEmail,
                  website: userWebsite,
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 100.ms,
                      duration: 500.ms,
                    ),

                const SizedBox(height: 48),

                // ── Stats Row ──────────────────────────────────────────
                _buildStatsRow(stats)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 200.ms,
                      duration: 500.ms,
                    ),

                const SizedBox(height: 48),

                // ── Recent Exchanges ───────────────────────────────────
                _buildRecentExchanges(recentProspects)
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 300.ms,
                      duration: 500.ms,
                    ),

                const SizedBox(height: 48),

                // ── Upcoming Events ────────────────────────────────────
                _buildUpcomingEvents(activeEvents)
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 400.ms,
                      duration: 500.ms,
                    ),
              ],
            ),
          ),

          // ── Glass header ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.6),
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0A5341CD),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: logo
                          Row(
                            children: [
                              Icon(
                                LucideIcons.radio,
                                color: _primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bump',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          // Right: notification + avatar
                          Row(
                            children: [
                              // Notification bell
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    onTap: () {},
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.bell,
                                        size: 22,
                                        color: _onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // User avatar
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _surfaceContainer,
                                  border: Border.all(
                                    color:
                                        _primary.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Welcome Section
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildWelcomeSection(String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OVERVIEW',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          firstName.isNotEmpty ? 'Hey, $firstName' : 'Welcome',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: _onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your networking game is strong today.',
          style: GoogleFonts.inter(
            fontSize: 18,
            color: _onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        // Share Card button
        GestureDetector(
          onTap: () {},
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.share2,
                    size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Share Card',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Digital Signature Card
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildDigitalCard({
    required String fullName,
    required String title,
    required String email,
    String? website,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative blur circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: glass icon + name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Glass icon box
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.radio,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName.isNotEmpty ? fullName : 'Your Name',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title.isNotEmpty ? title : 'Your Title',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      // QR code box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.qrCode,
                          size: 32,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Bottom: chips
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (email.isNotEmpty)
                        _buildCardChip(LucideIcons.mail, email),
                      if (website != null && website.isNotEmpty)
                        _buildCardChip(
                          LucideIcons.link,
                          website
                              .replaceAll('https://', '')
                              .replaceAll('http://', ''),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardChip(IconData icon, String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Stats Row
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildStatsRow(TotalStats stats) {
    return Row(
      children: [
        // Total Bumps
        Expanded(
          child: _buildStatCard(
            iconData: LucideIcons.radio,
            iconColor: _secondary,
            value: '${stats.totalBumps}',
            label: 'Total Bumps',
            badgeText: stats.totalBumps > 0 ? 'Active' : '--',
            badgeColor: _secondary,
          ),
        ),
        const SizedBox(width: 16),
        // Connect Rate
        Expanded(
          child: _buildStatCard(
            iconData: LucideIcons.trendingUp,
            iconColor: _primary,
            value: '${stats.conversionRate.toStringAsFixed(1)}%',
            label: 'Connect Rate',
            badgeText: 'Active',
            badgeColor: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData iconData,
    required Color iconColor,
    required String value,
    required String label,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _outlineVariant.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(iconData, size: 22, color: iconColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Recent Exchanges
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildRecentExchanges(List<Prospect> prospects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Exchanges',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/events'),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (prospects.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No exchanges yet. Start bumping!',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          // Items
          ...prospects.asMap().entries.map((entry) {
            final index = entry.key;
            final prospect = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExchangeItem(prospect, index),
            );
          }),
      ],
    );
  }

  Widget _buildExchangeItem(Prospect prospect, int index) {
    final gradientPair = AppGradients
        .avatarGradients[index % AppGradients.avatarGradients.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with gradient and initials
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientPair,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradientPair[0].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                prospect.initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prospect.fullName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${prospect.title} @ ${prospect.company}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Time + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeAgo(prospect.exchangeTime),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                LucideIcons.checkCircle2,
                size: 16,
                color: _primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Upcoming Events
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildUpcomingEvents(List<Event> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Events',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _surfaceContainer,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/events'),
                  child: const Center(
                    child:
                        Icon(LucideIcons.plus, size: 20, color: _onSurface),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No active events. Create one!',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          // Event cards
          ...events.asMap().entries.map((entry) {
            final event = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEventCard(event),
            );
          }),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    // Get the prospects for this event to show avatar stack
    final eventProspects = ref.watch(prospectsByEventProvider(event.id));

    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _outlineVariant.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date box
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _monthAbbr(event.date.month).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    Text(
                      '${event.date.day}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 14,
                          color: _onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: _onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bottom: avatar stack + View button
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        // Avatar stack
                        _buildAvatarStack(eventProspects),
                        // View button
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.arrowRight,
                              size: 14,
                              color: _primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarStack(List<Prospect> prospects) {
    const maxShown = 3;
    final shown = prospects.take(maxShown).toList();
    final remaining = prospects.length - shown.length;

    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...shown.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final gradientPair = AppGradients.avatarGradients[
                i % AppGradients.avatarGradients.length];
            return Transform.translate(
              offset: Offset(-8.0 * i, 0),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientPair,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    p.initials,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (remaining > 0)
            Transform.translate(
              offset: Offset(-8.0 * shown.length, 0),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surfaceContainer,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
