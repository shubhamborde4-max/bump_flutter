import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/providers/app_state.dart';
import 'package:bump/providers/profile_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    try {
      await _performNavigation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (mounted) context.go('/auth');
        },
      );
    } catch (_) {
      if (mounted) context.go('/auth');
    }
  }

  Future<void> _performNavigation() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final hasCompletedOnboarding = ref.read(hasCompletedOnboardingProvider);
    final session = Supabase.instance.client.auth.currentSession;

    if (!hasCompletedOnboarding) {
      context.go('/onboarding');
      return;
    }

    if (session != null) {
      // User is authenticated -- check profile completeness
      try {
        final profileRepo = ref.read(profileRepositoryProvider);
        final profile = await profileRepo.getMyProfile();

        if (!mounted) return;

        if (profile != null && profile.firstName.isNotEmpty) {
          context.go('/home');
        } else {
          context.go('/profile-setup');
        }
      } catch (_) {
        if (!mounted) return;
        context.go('/profile-setup');
      }
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing glow orb behind the icon
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow orb
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                )
                    .animate(
                      onPlay: (controller) =>
                          controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 1500.ms,
                      curve: Curves.easeInOut,
                    ),

                // Gradient container with app icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: AppGradients.hero,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/stitch-icon.png',
                      width: 56,
                      height: 56,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback icon if image not found
                        return const Icon(
                          Icons.handshake_rounded,
                          size: 48,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
              ],
            ),

            const SizedBox(height: 32),

            // "Bump" text
            Text(
              'Bump',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 300.ms,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                ),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Exchange. Connect. Convert.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 500.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 600.ms,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                ),
          ],
        ),
      ),
    );
  }
}
