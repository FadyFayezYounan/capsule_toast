// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/motion/damped_spring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retarget preserves current velocity', () {
    final DampedSpring spring = DampedSpring(value: 84)
      ..retarget(280)
      ..advance(
        const Duration(milliseconds: 80),
        CapsuleToastSpring(duration: Duration(milliseconds: 420), bounce: 0.16),
      );
    final double velocityBeforeRetarget = spring.velocity;

    spring.retarget(180);

    expect(spring.velocity, velocityBeforeRetarget);
    expect(spring.value, isNot(180));
  });

  test('large frame gaps produce the same bounded integration', () {
    final CapsuleToastSpring description = CapsuleToastSpring(
      duration: Duration(milliseconds: 400),
      bounce: 0.12,
    );
    final DampedSpring largeGap = DampedSpring(value: 34)..retarget(120);
    final DampedSpring clampedGap = DampedSpring(value: 34)..retarget(120);

    largeGap.advance(const Duration(milliseconds: 100), description);
    clampedGap.advance(const Duration(microseconds: 41667), description);

    expect(largeGap.value, closeTo(clampedGap.value, 0.01));
    expect(largeGap.velocity, closeTo(clampedGap.velocity, 0.01));
  });

  test('a settled spring stops exactly at its target', () {
    final DampedSpring spring = DampedSpring(value: 0)..retarget(100);
    for (int index = 0; index < 300; index += 1) {
      spring.advance(
        const Duration(milliseconds: 4),
        CapsuleToastSpring(duration: Duration(milliseconds: 300), bounce: 0),
      );
    }

    expect(spring.isSettled, isTrue);
    expect(spring.value, 100);
    expect(spring.velocity, 0);
  });
}
