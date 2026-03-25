import 'package:flutter/material.dart';
import 'package:bump/core/theme/app_theme.dart';

/// A translucent card with a frosted-glass appearance.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.opacity = 0.6,
    this.borderRadius = 16,
    this.shadowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double opacity;
  final double borderRadius;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: opacity.clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? AppColors.primary).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
