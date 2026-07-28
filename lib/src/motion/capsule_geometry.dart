// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'damped_spring.dart';

/// Independent springs for capsule width, height, and interactive drag offset.
///
/// Opacity is not a spring: the reference drives it from the appearance and
/// exit envelopes directly, so a spring would only add a tail the design does
/// not have.
final class CapsuleGeometry {
  /// Creates geometry with the given springs.
  const CapsuleGeometry({
    required this.width,
    required this.height,
    required this.verticalOffset,
  });

  /// Spring driving capsule width in logical pixels.
  final DampedSpring width;

  /// Spring driving capsule height in logical pixels.
  final DampedSpring height;

  /// Spring driving the interactive drag offset in logical pixels.
  final DampedSpring verticalOffset;

  /// Whether every spring has settled on its target.
  bool get isSettled {
    return width.isSettled && height.isSettled && verticalOffset.isSettled;
  }
}
