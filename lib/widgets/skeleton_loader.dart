import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer colors used by all skeleton widgets.
const _baseColor = Color(0xFFF2F3F8);
const _highlightColor = Color(0xFFFFFFFF);

/// A rounded rectangle shimmer loading placeholder.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A column of [CardSkeleton] widgets for list loading states.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.spacing = 12,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final int itemCount;
  final double itemHeight;
  final double spacing;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(itemCount, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < itemCount - 1 ? spacing : 0),
            child: CardSkeleton(
              height: itemHeight,
              borderRadius: borderRadius,
            ),
          );
        }),
      ),
    );
  }
}

/// A circular shimmer loading placeholder, useful for avatar loading states.
class CircleSkeleton extends StatelessWidget {
  const CircleSkeleton({
    super.key,
    this.size = 40,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: _baseColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
