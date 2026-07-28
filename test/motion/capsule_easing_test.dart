// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/src/motion/capsule_easing.dart';

void main() {
  test('capsuleEaseOut evaluates the reference polynomial', () {
    expect(capsuleEaseOut.transform(0), 0);
    expect(capsuleEaseOut.transform(1), 1);
    // 1 - (1 - t)^3 at the quarter points.
    expect(capsuleEaseOut.transform(0.25), closeTo(0.578125, 1e-9));
    expect(capsuleEaseOut.transform(0.5), closeTo(0.875, 1e-9));
    expect(capsuleEaseOut.transform(0.75), closeTo(0.984375, 1e-9));
  });

  test('capsuleEaseOut decelerates faster than Curves.easeOut', () {
    // The Bézier approximations Flutter ships lag the polynomial through the
    // first half of the envelope; that gap is what made entrances feel slack.
    for (final double t in <double>[0.15, 0.3, 0.5]) {
      expect(
        capsuleEaseOut.transform(t),
        greaterThan(Curves.easeOut.transform(t)),
      );
    }
  });

  test('capsuleEaseOutAt clamps out-of-range input', () {
    expect(capsuleEaseOutAt(-2), 0);
    expect(capsuleEaseOutAt(4), 1);
  });
}
