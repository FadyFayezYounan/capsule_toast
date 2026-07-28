// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import '../theme/capsule_toast_motion_theme.dart';

/// Deterministic scalar spring with bounded integration steps.
final class DampedSpring {
  /// Creates a spring at rest on [value].
  DampedSpring({required double value})
    : value = value,
      velocity = 0,
      target = value;

  /// Current spring position in logical pixels.
  double value;

  /// Current spring velocity in logical pixels per second.
  double velocity;

  /// Target position the spring is animating toward.
  double target;

  static const double _maxFrameSeconds = 1 / 24;
  static const double _maxSubstepSeconds = 1 / 240;
  static const double _settleDistanceThreshold = 0.06;
  static const double _settleVelocityThreshold = 0.6;

  /// Whether the spring has reached [target] within settlement thresholds.
  bool get isSettled {
    return (target - value).abs() <= _settleDistanceThreshold &&
        velocity.abs() <= _settleVelocityThreshold;
  }

  /// Animates toward a new [target] without changing [value] or [velocity].
  void retarget(double target) {
    this.target = target;
  }

  /// Snaps [value] and [target] to [value] and clears [velocity].
  void jumpTo(double value) {
    this.value = value;
    target = value;
    velocity = 0;
  }

  /// Integrates spring motion for [elapsed] using [description].
  void advance(Duration elapsed, CapsuleToastSpring description) {
    if (isSettled) {
      value = target;
      velocity = 0;
      return;
    }

    final double responseSeconds =
        description.duration.inMicroseconds / Duration.microsecondsPerSecond;
    final double angularFrequency = 2 * math.pi / responseSeconds;
    final double dampingRatio = 1 - description.bounce;

    double remainingSeconds =
        elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    if (remainingSeconds > _maxFrameSeconds) {
      remainingSeconds = _maxFrameSeconds;
    }

    while (remainingSeconds > 0) {
      final double stepSeconds = remainingSeconds > _maxSubstepSeconds
          ? _maxSubstepSeconds
          : remainingSeconds;
      remainingSeconds -= stepSeconds;

      final double displacement = target - value;
      final double acceleration =
          angularFrequency * angularFrequency * displacement -
          2 * dampingRatio * angularFrequency * velocity;
      velocity += acceleration * stepSeconds;
      value += velocity * stepSeconds;
    }

    _snapIfSettled();
  }

  void _snapIfSettled() {
    if (isSettled) {
      value = target;
      velocity = 0;
    }
  }
}
