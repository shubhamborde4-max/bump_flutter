import 'package:flutter/material.dart';
import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/widgets/animated_pressable.dart';

/// Full-width button with a hero gradient background.
/// When disabled, shows a solid surfaceLight color instead.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.title,
    this.onTap,
    this.disabled = false,
    this.icon,
    this.small = false,
  });

  final String title;
  final VoidCallback? onTap;
  final bool disabled;
  final Widget? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final height = small ? 48.0 : 56.0;
    final fontSize = small ? 14.0 : 16.0;

    return AnimatedPressable(
      onTap: onTap,
      disabled: disabled,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: disabled ? null : AppGradients.hero,
          color: disabled ? AppColors.surfaceLight : null,
          borderRadius: BorderRadius.circular(small ? 8 : 12),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: disabled ? AppColors.textMuted : Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
