import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class BumpToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colors = {
      ToastType.success: const Color(0xFF00C853),
      ToastType.error: const Color(0xFFBA1A1A),
      ToastType.info: const Color(0xFF5341CD),
      ToastType.warning: const Color(0xFFFF9100),
    };
    final icons = {
      ToastType.success: Icons.check_circle_outline,
      ToastType.error: Icons.error_outline,
      ToastType.info: Icons.info_outline,
      ToastType.warning: Icons.warning_amber_rounded,
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(icons[type], color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: colors[type],
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }
}
