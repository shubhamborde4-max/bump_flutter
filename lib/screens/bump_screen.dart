import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/providers/profile_provider.dart';
import 'package:bump/providers/exchange_provider.dart';
import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/widgets/avatar.dart';
import 'package:bump/widgets/glass_card.dart';
import 'package:bump/widgets/qr_display_widget.dart';

class BumpScreen extends ConsumerStatefulWidget {
  const BumpScreen({super.key});

  @override
  ConsumerState<BumpScreen> createState() => _BumpScreenState();
}

class _BumpScreenState extends ConsumerState<BumpScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Bump, 1 = QR Code

  @override
  Widget build(BuildContext context) {
    final recentProspects = ref.watch(recentProspectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Exchange',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildTabButton('Bump', 0),
                    _buildTabButton('QR Code', 1),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tab Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildBumpTab()
                  : _buildQrTab(),
            ),

            // Recent Exchanges
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Exchanges',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: recentProspects.isEmpty
                  ? Center(
                      child: Text(
                        'No exchanges yet',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: recentProspects.length > 3
                          ? 3
                          : recentProspects.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final prospect = recentProspects[index];
                        return _buildExchangeRow(prospect);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBumpTab() {
    final profileAsync = ref.watch(profileNotifierProvider);
    final userId = profileAsync.valueOrNull?.id ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing bump circle
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring 1
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
            )
                .animate(
                  onPlay: (controller) =>
                      controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.15, 1.15),
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                )
                .fadeIn(duration: 300.ms),

            // Outer pulse ring 2
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
            )
                .animate(
                  onPlay: (controller) =>
                      controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.1, 1.1),
                  duration: 1200.ms,
                  delay: 200.ms,
                  curve: Curves.easeInOut,
                ),

            // Main circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.hero,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.smartphone,
                size: 48,
                color: Colors.white,
              ),
            )
                .animate(
                  onPlay: (controller) =>
                      controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                ),
          ],
        ),

        const SizedBox(height: 32),

        Text(
          'NFC Coming Soon',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'NFC bump exchange is coming in a future update. Use QR codes or share your profile link for now.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms),

        const SizedBox(height: 24),

        // Share Profile Link button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: GestureDetector(
            onTap: () {
              final link = 'bump://exchange/$userId';
              Share.share('Connect with me on Bump! $link');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.share2,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Share Profile Link',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 400.ms),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQrTab() {
    final profileAsync = ref.watch(profileNotifierProvider);
    final activeEvent = ref.watch(activeEventProvider);
    final userId = profileAsync.valueOrNull?.id ?? '';
    final eventId = activeEvent?.id ?? '';

    final qrData = eventId.isNotEmpty
        ? 'bump://exchange/$userId?event=$eventId'
        : 'bump://exchange/$userId';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // QR code display
        QrDisplayWidget(
          data: qrData,
          size: 200,
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
            ),

        const SizedBox(height: 12),

        Text(
          'Your QR Code',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),

        const SizedBox(height: 24),

        // Scan QR button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: GestureDetector(
            onTap: () {
              context.push('/qr-scanner');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.scan,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scan QR',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildExchangeRow(Prospect prospect) {
    final timeAgo = _formatTimeAgo(prospect.exchangeTime);

    return GlassCard(
      opacity: 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          BumpAvatar(
            firstName: prospect.firstName,
            lastName: prospect.lastName,
            uri: prospect.avatar,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prospect.fullName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  prospect.company,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
