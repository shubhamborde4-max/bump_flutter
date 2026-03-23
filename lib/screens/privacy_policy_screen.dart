import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ── Design Tokens ───────────────────────────────────────────────────────────
const _primary = Color(0xFF5341CD);
const _background = Color(0xFFF8F9FE);
const _surface = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF191C1F);
const _textSecondary = Color(0xFF474554);

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated
            Text(
              'Last Updated: March 23, 2026',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            Text(
              'Bump ("we", "our", "us") is a digital business card exchange and '
              'networking platform. This Privacy Policy explains how we collect, '
              'use, disclose, and safeguard your information when you use our '
              'mobile application.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),

            // 1. Information We Collect
            _sectionHeader('1. Information We Collect'),
            const SizedBox(height: 8),
            _sectionBody(
              'We collect the following types of information:\n\n'
              '\u2022 Personal Information: Name, email address, phone number, '
              'company, job title, and profile photo.\n\n'
              '\u2022 Device Information: Firebase Cloud Messaging (FCM) tokens '
              'for push notifications.\n\n'
              '\u2022 Usage Data: Events created, prospects managed, and '
              'analytics data related to your use of the app.',
            ),
            const SizedBox(height: 24),

            // 2. How We Use Your Information
            _sectionHeader('2. How We Use Your Information'),
            const SizedBox(height: 8),
            _sectionBody(
              'We use the information we collect to:\n\n'
              '\u2022 Provide and operate the Bump service.\n'
              '\u2022 Facilitate contact exchanges between users.\n'
              '\u2022 Send nudge messages and notifications.\n'
              '\u2022 Provide analytics and insights on your networking activity.\n'
              '\u2022 Improve and enhance our service.',
            ),
            const SizedBox(height: 24),

            // 3. Information Sharing
            _sectionHeader('3. Information Sharing'),
            const SizedBox(height: 8),
            _sectionBody(
              'We do NOT sell your personal data. We only share your '
              'information in the following cases:\n\n'
              '\u2022 With users you exchange cards with \u2014 only the fields '
              'you have selected as visible will be shared.\n\n'
              '\u2022 With service providers: Supabase for secure data storage '
              'and Firebase for push notifications.',
            ),
            const SizedBox(height: 24),

            // 4. Data Storage & Security
            _sectionHeader('4. Data Storage & Security'),
            const SizedBox(height: 8),
            _sectionBody(
              'Your data is stored securely on Supabase with encryption at '
              'rest. Row Level Security (RLS) policies ensure that you can only '
              'access your own data. We take reasonable measures to protect '
              'your information from unauthorized access, alteration, or '
              'destruction.',
            ),
            const SizedBox(height: 24),

            // 5. Your Rights
            _sectionHeader('5. Your Rights'),
            const SizedBox(height: 8),
            _sectionBody(
              'You have the right to:\n\n'
              '\u2022 Access, update, or delete your personal data at any time '
              'through the app.\n'
              '\u2022 Request a full data export in CSV format.\n'
              '\u2022 Delete your account and all associated data permanently.',
            ),
            const SizedBox(height: 24),

            // 6. Contact Us
            _sectionHeader('6. Contact Us'),
            const SizedBox(height: 8),
            _sectionBody(
              'For questions about this Privacy Policy, contact us at '
              'privacy@bumpapp.io.',
            ),
            const SizedBox(height: 24),

            // 7. Changes to This Policy
            _sectionHeader('7. Changes to This Policy'),
            const SizedBox(height: 8),
            _sectionBody(
              'We may update this Privacy Policy from time to time. We will '
              'notify you of any changes by updating the "Last Updated" date '
              'at the top of this page. Your continued use of the app after '
              'any changes constitutes your acceptance of the updated policy.',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  static Widget _sectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
      ),
    );
  }

  static Widget _sectionBody(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: _textSecondary,
        height: 1.6,
      ),
    );
  }
}
