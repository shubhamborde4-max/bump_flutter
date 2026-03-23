import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:bump/widgets/gradient_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.title = 'No records found',
    this.subtitle = 'There are no records as of now.\nPlease come back later or create a new one.',
    this.icon = LucideIcons.inbox,
    this.actionLabel,
    this.onAction,
  });

  // Design tokens
  static const _background = Color(0xFFF8F9FE);
  static const _textPrimary = Color(0xFF191C1F);
  static const _textMuted = Color(0xFF787586);
  static const _surfaceLight = Color(0xFFF2F3F8);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
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
              color: _surfaceLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 40,
                color: _textMuted,
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .moveY(
                begin: 0,
                end: -8,
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),

          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _textMuted,
            ),
            textAlign: TextAlign.center,
          ),

          // Optional action button
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: GradientButton(
                title: actionLabel!,
                onTap: onAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
