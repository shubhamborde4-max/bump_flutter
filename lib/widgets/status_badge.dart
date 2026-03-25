import 'package:flutter/material.dart';
import 'package:bump/core/theme/app_theme.dart';

/// The size of a [StatusBadge].
enum StatusBadgeSize { small, normal }

/// A small pill/chip widget showing a prospect status.
///
/// Displays a colored dot followed by the status label text.
/// The background uses the status color at 15% opacity, and the text
/// and dot use the full status color.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.size = StatusBadgeSize.normal,
  });

  final String status;
  final StatusBadgeSize size;

  static String _capitalize(String s) {
    if (s.isEmpty) return 'Unknown';
    if (s.length == 1) return s.toUpperCase();
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();

    final color = AppColors.statusColor(status);
    final isSmall = size == StatusBadgeSize.small;
    final fontSize = isSmall ? 10.0 : 12.0;
    final dotSize = isSmall ? 6.0 : 8.0;
    final horizontalPadding = isSmall ? 8.0 : 10.0;
    final verticalPadding = isSmall ? 3.0 : 5.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            _capitalize(status),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
