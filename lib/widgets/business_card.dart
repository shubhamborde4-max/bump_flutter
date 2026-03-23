import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/data/models/user_model.dart';

/// A flippable business card widget with three style variants.
///
/// Tap to flip with a 3D rotation animation around the Y axis.
class BusinessCard extends StatefulWidget {
  final User user;
  final CardStyle style;

  const BusinessCard({
    super.key,
    required this.user,
    this.style = CardStyle.modern,
  });

  @override
  State<BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<BusinessCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _animation.addListener(() {
      // Swap faces at the midpoint
      final isFront = _animation.value < math.pi / 2;
      if (isFront != _showFront) {
        setState(() => _showFront = isFront);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  /// Returns true if the given field should be shown on the card.
  bool _isVisible(String field) => widget.user.visibleFields.contains(field);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Determine which angle to use for the visible face
          double angle = _animation.value;
          // When showing back, mirror it so text is readable
          if (!_showFront) {
            angle = math.pi - _animation.value;
          }

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: _showFront ? _buildFront() : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    switch (widget.style) {
      case CardStyle.modern:
        return _ModernFront(user: widget.user, isVisible: _isVisible);
      case CardStyle.classic:
        return _ClassicFront(user: widget.user, isVisible: _isVisible);
      case CardStyle.minimal:
        return _MinimalFront(user: widget.user, isVisible: _isVisible);
    }
  }

  Widget _buildBack() {
    switch (widget.style) {
      case CardStyle.modern:
        return _ModernBack(user: widget.user);
      case CardStyle.classic:
        return _ClassicBack(user: widget.user);
      case CardStyle.minimal:
        return _MinimalBack(user: widget.user);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared helpers
// ═══════════════════════════════════════════════════════════════════════════════

const _cardAspectRatio = 1.75;

Widget _cardContainer({
  required Widget child,
  Gradient? gradient,
  Color? color,
  Border? border,
}) {
  return AspectRatio(
    aspectRatio: _cardAspectRatio,
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

Widget _contactRow(IconData icon, String text, Color iconColor, Color textColor) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: textColor,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _buildAvatar(User user, double size) {
  final url = user.avatar ?? user.profilePicUrl;
  if (url != null && url.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsCircle(user, size),
      ),
    );
  }
  return _initialsCircle(user, size);
}

Widget _initialsCircle(User user, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: AppGradients.avatarGradient(user.fullName.hashCode.abs()),
    ),
    alignment: Alignment.center,
    child: Text(
      user.initials,
      style: GoogleFonts.inter(
        fontSize: size * 0.36,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

Widget _buildCompanyLogo(User user, double size) {
  final logo = user.companyLogo;
  if (logo != null && logo.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _logoPlaceholder(user, size),
      ),
    );
  }
  return _logoPlaceholder(user, size);
}

Widget _logoPlaceholder(User user, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    alignment: Alignment.center,
    child: Icon(
      LucideIcons.building2,
      size: size * 0.5,
      color: Colors.white.withValues(alpha: 0.7),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Style 1: Modern (Corporate teal-blue gradient)
// ═══════════════════════════════════════════════════════════════════════════════

const _modernGradient = LinearGradient(
  colors: [Color(0xFF1B4D5C), Color(0xFF3A7D8C)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class _ModernFront extends StatelessWidget {
  final User user;
  final bool Function(String) isVisible;

  const _ModernFront({required this.user, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return _cardContainer(
      gradient: _modernGradient,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company info
                  Row(
                    children: [
                      _buildCompanyLogo(user, 24),
                      const SizedBox(width: 8),
                      if (isVisible('company') && user.company.isNotEmpty)
                        Flexible(
                          child: Text(
                            user.company,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  if (isVisible('department') &&
                      user.department != null &&
                      user.department!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        user.department!,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Name and title
                  if (isVisible('firstName') || isVisible('lastName'))
                    Text(
                      [
                        if (isVisible('firstName')) user.firstName,
                        if (isVisible('lastName')) user.lastName,
                      ].join(' ').trim(),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (isVisible('designation') &&
                      user.designation != null &&
                      user.designation!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.designation!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (isVisible('title') && user.title.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.title,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Contact details
                  if (isVisible('phone') && user.phone.isNotEmpty)
                    _contactRow(LucideIcons.phone, user.phone,
                        Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.8)),
                  if (isVisible('email') && user.email.isNotEmpty)
                    _contactRow(LucideIcons.mail, user.email,
                        Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.8)),
                  if (isVisible('website') &&
                      user.website != null &&
                      user.website!.isNotEmpty)
                    _contactRow(LucideIcons.globe, user.website!,
                        Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.8)),
                  if (isVisible('address') &&
                      user.address != null &&
                      user.address!.isNotEmpty)
                    _contactRow(LucideIcons.mapPin, user.address!,
                        Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.8)),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Right: avatar
            _buildAvatar(user, 60),
          ],
        ),
      ),
    );
  }
}

class _ModernBack extends StatelessWidget {
  final User user;

  const _ModernBack({required this.user});

  @override
  Widget build(BuildContext context) {
    return _cardContainer(
      gradient: _modernGradient,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCompanyLogo(user, 48),
            const SizedBox(height: 12),
            if (user.company.isNotEmpty)
              Text(
                user.company,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            if (user.department != null && user.department!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user.department!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Style 2: Classic (Clean cream/off-white)
// ═══════════════════════════════════════════════════════════════════════════════

const _classicBg = Color(0xFFF5F0EB);
const _classicText = Color(0xFF2C2C2C);
const _classicMuted = Color(0xFF8A8578);

class _ClassicFront extends StatelessWidget {
  final User user;
  final bool Function(String) isVisible;

  const _ClassicFront({required this.user, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return _cardContainer(
      color: _classicBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Left decorative element
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 2,
                  height: 40,
                  color: _classicMuted.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 6),
                Icon(
                  LucideIcons.lamp,
                  size: 20,
                  color: _classicMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 2,
                  height: 40,
                  color: _classicMuted.withValues(alpha: 0.3),
                ),
              ],
            ),

            const SizedBox(width: 20),

            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isVisible('firstName') || isVisible('lastName'))
                    Text(
                      [
                        if (isVisible('firstName')) user.firstName,
                        if (isVisible('lastName')) user.lastName,
                      ].join(' ').trim(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _classicText,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (isVisible('designation') &&
                      user.designation != null &&
                      user.designation!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.designation!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _classicMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ] else if (isVisible('title') &&
                      user.title.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.title,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _classicMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: _classicMuted.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 12),

                  // Contact details
                  if (isVisible('phone') && user.phone.isNotEmpty)
                    _contactRow(LucideIcons.phone, user.phone,
                        _classicMuted, _classicText),
                  if (isVisible('website') &&
                      user.website != null &&
                      user.website!.isNotEmpty)
                    _contactRow(LucideIcons.globe, user.website!,
                        _classicMuted, _classicText),
                  if (isVisible('email') && user.email.isNotEmpty)
                    _contactRow(LucideIcons.mail, user.email,
                        _classicMuted, _classicText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassicBack extends StatelessWidget {
  final User user;

  const _ClassicBack({required this.user});

  @override
  Widget build(BuildContext context) {
    return _cardContainer(
      color: _classicBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCompanyLogoClassic(user, 40),
              const SizedBox(height: 12),
              if (user.company.isNotEmpty)
                Text(
                  user.company,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _classicText,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (user.note != null && user.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  user.note!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _classicMuted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildCompanyLogoClassic(User user, double size) {
  final logo = user.companyLogo;
  if (logo != null && logo.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _logoPlaceholderClassic(size),
      ),
    );
  }
  return _logoPlaceholderClassic(size);
}

Widget _logoPlaceholderClassic(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: _classicMuted.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    alignment: Alignment.center,
    child: Icon(
      LucideIcons.building2,
      size: size * 0.5,
      color: _classicMuted.withValues(alpha: 0.5),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Style 3: Minimal (Clean modern white)
// ═══════════════════════════════════════════════════════════════════════════════

class _MinimalFront extends StatelessWidget {
  final User user;
  final bool Function(String) isVisible;

  const _MinimalFront({required this.user, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return _cardContainer(
      color: Colors.white,
      border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      child: Stack(
        children: [
          // Accent gradient line at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                if (isVisible('firstName') || isVisible('lastName'))
                  Text(
                    [
                      if (isVisible('firstName')) user.firstName,
                      if (isVisible('lastName')) user.lastName,
                    ].join(' ').trim(),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (isVisible('designation') &&
                    user.designation != null &&
                    user.designation!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.designation!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ] else if (isVisible('title') && user.title.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],

                const Spacer(),

                // Contact grid
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isVisible('phone') && user.phone.isNotEmpty)
                            _contactRow(LucideIcons.phone, user.phone,
                                AppColors.accent, AppColors.textSecondary),
                          if (isVisible('email') && user.email.isNotEmpty)
                            _contactRow(LucideIcons.mail, user.email,
                                AppColors.accent, AppColors.textSecondary),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isVisible('website') &&
                              user.website != null &&
                              user.website!.isNotEmpty)
                            _contactRow(LucideIcons.globe, user.website!,
                                AppColors.accent, AppColors.textSecondary),
                          if (isVisible('address') &&
                              user.address != null &&
                              user.address!.isNotEmpty)
                            _contactRow(LucideIcons.mapPin, user.address!,
                                AppColors.accent, AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalBack extends StatelessWidget {
  final User user;

  const _MinimalBack({required this.user});

  @override
  Widget build(BuildContext context) {
    return _cardContainer(
      color: Colors.white,
      border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      child: Stack(
        children: [
          // Accent gradient line at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // QR code placeholder
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.qrCode,
                    size: 36,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 14),
                if (user.company.isNotEmpty)
                  Text(
                    user.company,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (user.website != null && user.website!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.website!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
