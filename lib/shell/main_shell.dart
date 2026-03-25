import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design Tokens ───────────────────────────────────────────────────────────
const _primaryContainer = Color(0xFF6C5CE7);
const _inactiveColor = Color(0xFF94A3B8); // slate-400

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/home') return 0;
    if (location == '/bump') return 1;
    if (location == '/events') return 2;
    if (location == '/analytics') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F6C5CE7),
                  blurRadius: 40,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: LucideIcons.home,
                      label: 'Home',
                      isActive: index == 0,
                      onTap: () => context.go('/home'),
                    ),
                    _NavItem(
                      icon: LucideIcons.zap,
                      label: 'Bump',
                      isActive: index == 1,
                      onTap: () => context.go('/bump'),
                    ),
                    _NavItem(
                      icon: LucideIcons.calendar,
                      label: 'Events',
                      isActive: index == 2,
                      onTap: () => context.go('/events'),
                    ),
                    _NavItem(
                      icon: LucideIcons.barChart2,
                      label: 'Analytics',
                      isActive: index == 3,
                      onTap: () => context.go('/analytics'),
                    ),
                    _NavItem(
                      icon: LucideIcons.user,
                      label: 'Profile',
                      isActive: index == 4,
                      onTap: () => context.go('/profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? _primaryContainer.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _primaryContainer.withValues(alpha: 0.2),
                    blurRadius: 15,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? _primaryContainer : _inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive ? _primaryContainer : _inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
