// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/animation.dart';

/// The cubic ease-out used by every capsule envelope: `1 - (1 - t)³`.
///
/// [Curves.easeOut] and [Curves.easeOutCubic] are Bézier approximations that
/// decelerate on a visibly different schedule from the reference motion spec,
/// which evaluates the polynomial directly. Envelopes use this curve so the
/// appearance, content reveal, and exit fades stay frame-accurate.
class CapsuleEaseOutCubic extends Curve {
  /// Creates the shared capsule ease-out curve.
  const CapsuleEaseOutCubic();

  @override
  double transformInternal(double t) {
    final double inverse = 1 - t;
    return 1 - inverse * inverse * inverse;
  }
}

/// Shared instance of [CapsuleEaseOutCubic].
const Curve capsuleEaseOut = CapsuleEaseOutCubic();

/// Evaluates [capsuleEaseOut] after clamping [t] into `[0, 1]`.
double capsuleEaseOutAt(double t) {
  return capsuleEaseOut.transform(t.clamp(0.0, 1.0));
}
