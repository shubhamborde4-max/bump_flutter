import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/widgets/gradient_button.dart';

/// Reusable error state widget displayed when a screen fails to load data.
///
/// Shows a friendly error message with an optional retry button.
/// Designed to match [EmptyState] in visual style.
class ErrorState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.subtitle = 'Please check your connection\nand try again.',
    this.icon = LucideIcons.wifiOff,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .moveY(
                begin: 0,
                end: -6,
                duration: 2500.ms,
                curve: Curves.easeInOut,
              ),

          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),

          // Retry button
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: GradientButton(
                title: 'Try Again',
                onTap: onRetry,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
