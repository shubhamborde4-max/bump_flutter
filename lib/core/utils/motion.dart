import 'package:flutter/widgets.dart';

/// Returns [Duration.zero] when the user has enabled reduced-motion
/// (accessibility setting), otherwise returns [normal].
Duration animDuration(BuildContext context, Duration normal) {
  if (MediaQuery.of(context).disableAnimations) return Duration.zero;
  return normal;
}
