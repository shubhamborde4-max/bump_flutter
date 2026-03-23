import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Design Tokens ───────────────────────────────────────────────────────────
const _primary = Color(0xFF5341CD);
const _accent = Color(0xFF6C5CE7);
const _background = Color(0xFFF8F9FE);
const _surface = Color(0xFFFFFFFF);
const _surfaceLight = Color(0xFFF2F3F8);
const _textPrimary = Color(0xFF191C1F);
const _textSecondary = Color(0xFF474554);
const _textMuted = Color(0xFF787586);

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: _textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // App Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _surface,
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/stitch-icon.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // App Name
            Text(
              'Bump',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Version
            Text(
              'Version 1.0.0',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              'Exchange. Connect. Convert.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Description
            Text(
              'Bump is a networking platform that helps professionals exchange '
              'contact information digitally, manage prospects from events, and '
              'convert connections into meaningful business relationships.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Info Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Developer',
                    value: 'Shubham Borde',
                    showDivider: true,
                  ),
                  _InfoRow(
                    label: 'Email',
                    value: 'shubhamborde4@gmail.com',
                    isTappable: true,
                    onTap: () => _launchUrl('mailto:shubhamborde4@gmail.com'),
                    showDivider: true,
                  ),
                  _InfoRow(
                    label: 'GitHub',
                    value: 'github.com/shubhamborde4-max',
                    isTappable: true,
                    onTap: () =>
                        _launchUrl('https://github.com/shubhamborde4-max'),
                    showDivider: true,
                  ),
                  _InfoRow(
                    label: 'Built with',
                    value: 'Flutter + Supabase',
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Privacy Policy Link
            GestureDetector(
              onTap: () => context.push('/privacy-policy'),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.shield, size: 18, color: _primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Privacy Policy',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight,
                        size: 18, color: _textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            Text(
              'Made with \u2764\uFE0F in India',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTappable;
  final VoidCallback? onTap;
  final bool showDivider;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isTappable = false,
    this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: isTappable ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isTappable ? _primary : _textPrimary,
                    ),
                  ),
                ),
                if (isTappable)
                  Icon(
                    LucideIcons.externalLink,
                    size: 14,
                    color: _primary.withValues(alpha: 0.6),
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.black.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}
