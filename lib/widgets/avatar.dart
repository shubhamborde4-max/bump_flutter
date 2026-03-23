import 'package:flutter/material.dart';
import 'package:bump/core/theme/app_theme.dart';

/// Circular avatar widget that displays a network image or initials
/// on a gradient background when no image is available.
class BumpAvatar extends StatelessWidget {
  const BumpAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    this.uri,
    this.size = 40,
  });

  final String firstName;
  final String lastName;
  final String? uri;
  final double size;

  String get _initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  List<Color> get _gradient {
    final name = '$firstName$lastName';
    final hash = name.hashCode.abs();
    final index = hash % AppGradients.avatarGradients.length;
    return AppGradients.avatarGradients[index];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: uri != null && uri!.isNotEmpty
            ? Image.network(
                uri!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitialsAvatar(),
              )
            : _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
