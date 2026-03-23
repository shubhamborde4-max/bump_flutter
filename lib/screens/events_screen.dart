import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/providers/profile_provider.dart';
import 'package:bump/providers/events_provider.dart';
import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/data/models/event_model.dart';
import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/screens/nudge_sheet.dart';

// ── Design Tokens ───────────────────────────────────────────────────────────
const _primary = Color(0xFF5341CD);
const _primaryContainer = Color(0xFF6C5CE7);
const _secondary = Color(0xFF00677F);
const _secondaryContainer = Color(0xFF00D2FF);
const _background = Color(0xFFF8F9FE);
const _surface = Color(0xFFFFFFFF);
const _surfaceLow = Color(0xFFF2F3F8);
const _onSurface = Color(0xFF191C1F);
const _onSurfaceVariant = Color(0xFF474554);
const _outline = Color(0xFF787586);
const _outlineVariant = Color(0xFFC8C4D7);

// ── Status Colors ───────────────────────────────────────────────────────────
Color _statusColor(ProspectStatus status) {
  switch (status) {
    case ProspectStatus.newProspect:
      return _secondary;
    case ProspectStatus.contacted:
      return const Color(0xFFFF9100);
    case ProspectStatus.interested:
      return const Color(0xFFE65100);
    case ProspectStatus.converted:
      return const Color(0xFF00C853);
    case ProspectStatus.archived:
      return _outline;
  }
}

String _statusLabel(ProspectStatus status) {
  switch (status) {
    case ProspectStatus.newProspect:
      return 'New';
    case ProspectStatus.contacted:
      return 'Warm';
    case ProspectStatus.interested:
      return 'Hot';
    case ProspectStatus.converted:
      return 'Won';
    case ProspectStatus.archived:
      return 'Cold';
  }
}

// ── Events Screen (Connections) ─────────────────────────────────────────────
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  int _activeTabIndex = 0;
  final _tabs = ['Prospects', 'History', 'Export'];

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final prospectsAsync = ref.watch(prospectsProvider);
    final profileAsync = ref.watch(profileNotifierProvider);
    final user = profileAsync.valueOrNull;

    return Scaffold(
      backgroundColor: _background,
      body: eventsAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error),
        data: (events) {
          final prospects = prospectsAsync.valueOrNull ?? [];
          final activeEvent = events.where((e) => e.isActive).isNotEmpty
              ? events.firstWhere((e) => e.isActive)
              : events.isNotEmpty
                  ? events.first
                  : null;

          final eventProspects = activeEvent != null
              ? prospects
                  .where((p) => p.eventId == activeEvent.id)
                  .toList()
              : <Prospect>[];

          // Sort by exchange time descending
          eventProspects
              .sort((a, b) => b.exchangeTime.compareTo(a.exchangeTime));

          final userName = user != null
              ? '${user.firstName} ${user.lastName}'
              : '';
          final initials = user != null
              ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
              : '';

          return RefreshIndicator(
            color: _primary,
            onRefresh: () async {
              await ref.read(eventsProvider.notifier).loadEvents();
              await ref.read(prospectsProvider.notifier).loadProspects();
            },
            child: Stack(
              children: [
                // Scrollable Content
                CustomScrollView(
                  slivers: [
                    // Top padding for glass header
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),

                    // Section Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connections',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your event prospects and leads',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSegmentedControl(),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(
                          begin: 0.05, end: 0, duration: 400.ms),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),

                    // Featured Event Card
                    if (activeEvent != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: GestureDetector(
                            onTap: () =>
                                context.push('/events/${activeEvent.id}'),
                            child: _FeaturedEventCard(
                              event: activeEvent,
                              prospectCount: eventProspects.length,
                            ),
                          ),
                        ).animate().fadeIn(
                            delay: 100.ms, duration: 500.ms).slideY(
                            begin: 0.08,
                            end: 0,
                            delay: 100.ms,
                            duration: 500.ms),
                      ),

                    if (events.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 60, horizontal: 24),
                          child: Column(
                            children: [
                              const Icon(LucideIcons.calendar,
                                  size: 48, color: _primary),
                              const SizedBox(height: 16),
                              Text(
                                'No events yet',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first event to start tracking prospects',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: _onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // Recent Prospects Header
                    if (eventProspects.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Prospects',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _onSurface,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Row(
                                  children: [
                                    Text(
                                      'Filter',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.listFilter,
                                        size: 18, color: _primary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(
                            delay: 200.ms, duration: 400.ms),
                      ),

                    if (eventProspects.isNotEmpty)
                      const SliverToBoxAdapter(
                          child: SizedBox(height: 16)),

                    // Prospect Cards
                    if (eventProspects.isNotEmpty)
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(24, 0, 24, 128),
                        sliver: SliverList.builder(
                          itemCount: eventProspects.length,
                          itemBuilder: (context, index) {
                            final prospect = eventProspects[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 16),
                              child: _ProspectCard(
                                prospect: prospect,
                                index: index,
                              ),
                            ).animate().fadeIn(
                                  delay: Duration(
                                      milliseconds:
                                          250 + index * 80),
                                  duration: 400.ms,
                                ).slideY(
                                  begin: 0.1,
                                  end: 0,
                                  delay: Duration(
                                      milliseconds:
                                          250 + index * 80),
                                  duration: 400.ms,
                                );
                          },
                        ),
                      ),

                    if (eventProspects.isEmpty &&
                        activeEvent != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 40, horizontal: 24),
                          child: Column(
                            children: [
                              const Icon(LucideIcons.users,
                                  size: 48, color: _primary),
                              const SizedBox(height: 16),
                              Text(
                                'No prospects yet',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start exchanging contacts at your event',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: _onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Glass Header
                _GlassHeader(
                  userName: userName,
                  initials: initials,
                ),

                // FAB
                Positioned(
                  right: 24,
                  bottom: 112,
                  child: _buildFAB(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: _primary),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: _primary),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => ref.invalidate(eventsProvider),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = _activeTabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _primary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () => _showCreateEventSheet(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [_primary, _primaryContainer],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5341CD).withValues(alpha: 0.3),
              blurRadius: 35,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
      ),
    );
  }

  void _showCreateEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateEventSheet(
        onSave: (event) async {
          try {
            await ref.read(eventsProvider.notifier).createEvent(event);
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Event created successfully!'),
                  backgroundColor: const Color(0xFF00C853),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create event: $e'),
                  backgroundColor: const Color(0xFFBA1A1A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ── Glass Header ────────────────────────────────────────────────────────────
class _GlassHeader extends StatelessWidget {
  final String userName;
  final String initials;

  const _GlassHeader({required this.userName, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x0A5341CD),
                  blurRadius: 30,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: logo
                Row(
                  children: [
                    const Icon(LucideIcons.radio, size: 24, color: _primary),
                    const SizedBox(width: 12),
                    Text(
                      'Bump',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
                // Right: avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _primary.withValues(alpha: 0.1),
                      width: 2,
                    ),
                    gradient: LinearGradient(
                      colors: [_primaryContainer, _secondaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Featured Event Card ─────────────────────────────────────────────────────
class _FeaturedEventCard extends StatelessWidget {
  final Event event;
  final int prospectCount;

  const _FeaturedEventCard({required this.event, required this.prospectCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background decorations
            Positioned(
              top: -48,
              right: -48,
              child: Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -32,
              left: -32,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _secondaryContainer.withValues(alpha: 0.3),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                height: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Event badge
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'ACTIVE EVENT',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Event name
                        Text(
                          event.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Location
                        Row(
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 14,
                              color:
                                  Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.location,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white
                                      .withValues(alpha: 0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom: Avatar stack
                    Row(
                      children: [
                        // Overlapping avatar circles
                        SizedBox(
                          width: 3 * 32.0 - 2 * 8.0 + 36,
                          height: 32,
                          child: Stack(
                            children: [
                              for (int i = 0;
                                  i < 3 && i < prospectCount;
                                  i++)
                                Positioned(
                                  left: i * 24.0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient:
                                          AppGradients.avatarGradient(i),
                                      border: Border.all(
                                          color: _primary, width: 2),
                                    ),
                                  ),
                                ),
                              if (prospectCount > 3)
                                Positioned(
                                  left: 3 * 24.0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white
                                          .withValues(alpha: 0.25),
                                      border: Border.all(
                                          color: _primary, width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '+${prospectCount - 3}',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'New connections today',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Prospect Card ───────────────────────────────────────────────────────────
class _ProspectCard extends ConsumerWidget {
  final Prospect prospect;
  final int index;

  const _ProspectCard({required this.prospect, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(prospect.status);
    final statusText = _statusLabel(prospect.status);
    final gradientIndex = prospect.id.hashCode.abs();

    return GestureDetector(
      onTap: () => context.push('/prospects/${prospect.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: _outlineVariant.withValues(alpha: 0.1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 30,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppGradients.avatarGradient(gradientIndex),
                boxShadow: [
                  BoxShadow(
                    color: AppGradients.avatarGradients[gradientIndex %
                            AppGradients.avatarGradients.length][0]
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
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
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Status row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prospect.fullName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${prospect.title} @ ${prospect.company}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          statusText.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      // Nudge button
                      Expanded(
                        child: _ActionButton(
                          icon: LucideIcons.pointer,
                          label: 'Nudge',
                          onTap: () =>
                              showNudgeSheet(context, ref, prospect),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Call button
                      Expanded(
                        child: _ActionButton(
                          icon: LucideIcons.phone,
                          label: 'Call',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      // More button
                      GestureDetector(
                        onTap: () =>
                            context.push('/prospects/${prospect.id}'),
                        child: Container(
                          width: 40,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.moreHorizontal,
                            size: 16,
                            color: _primary,
                          ),
                        ),
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
}

// ── Action Button ───────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: _primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Event Sheet ──────────────────────────────────────────────────────
class _CreateEventSheet extends StatefulWidget {
  final void Function(Event) onSave;

  const _CreateEventSheet({required this.onSave});

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _handleCreate() {
    final now = DateTime.now();
    final end = now.add(const Duration(hours: 8));
    widget.onSave(Event(
      id: '', // Supabase will generate the id
      name: _nameCtrl.text,
      date: now,
      endDate: end,
      location: _locationCtrl.text.isEmpty ? 'TBD' : _locationCtrl.text,
      description: _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create Event',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _onSurface,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(LucideIcons.x,
                    size: 24, color: _onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Fields
          _buildField(
              'EVENT NAME', 'e.g. TechCrunch Disrupt 2026', _nameCtrl),
          const SizedBox(height: 16),
          _buildField('LOCATION', 'Venue, City', _locationCtrl),
          const SizedBox(height: 16),
          _buildField(
              'DESCRIPTION', "What's this event about?", _descCtrl,
              maxLines: 3),
          const SizedBox(height: 24),

          // Create button
          GestureDetector(
            onTap:
                _nameCtrl.text.trim().isNotEmpty ? _handleCreate : null,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: _nameCtrl.text.trim().isNotEmpty
                    ? const LinearGradient(
                        colors: [_primary, _primaryContainer],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      )
                    : null,
                color: _nameCtrl.text.trim().isEmpty ? _surfaceLow : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _nameCtrl.text.trim().isNotEmpty
                    ? [
                        BoxShadow(
                          color: _primaryContainer
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                'Create Event',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      String label, String hint, TextEditingController ctrl,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _outline,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          cursorColor: _primary,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(fontSize: 14, color: _onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: _outline),
            filled: true,
            fillColor: _surfaceLow,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
