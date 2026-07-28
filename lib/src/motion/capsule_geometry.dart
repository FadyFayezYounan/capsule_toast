// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'damped_spring.dart';

/// Independent springs for capsule width, height, opacity, and vertical offset.
final class CapsuleGeometry {
  /// Creates geometry with the given springs.
  const CapsuleGeometry({
    required this.width,
    required this.height,
    required this.opacity,
    required this.verticalOffset,
  });

  /// Spring driving capsule width in logical pixels.
  final DampedSpring width;

  /// Spring driving capsule height in logical pixels.
  final DampedSpring height;

  /// Spring driving capsule opacity in `[0, 1]`.
  final DampedSpring opacity;

  /// Spring driving vertical offset in logical pixels.
  final DampedSpring verticalOffset;

  /// Whether every spring has settled on its target.
  bool get isSettled {
    return width.isSettled &&
        height.isSettled &&
        opacity.isSettled &&
        verticalOffset.isSettled;
  }
}
