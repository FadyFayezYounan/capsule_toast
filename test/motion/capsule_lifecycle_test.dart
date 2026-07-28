// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/motion/capsule_lifecycle.dart';
import 'package:capsule_toast/src/motion/lifecycle_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lifecycle follows hidden seed compact expanded collapse hidden', () {
    final CapsuleLifecycle lifecycle = CapsuleLifecycle();

    lifecycle.begin(CapsuleToastMode.compact);
    expect(lifecycle.state, CapsuleLifecycleState.seed);
    lifecycle.didAppear();
    expect(lifecycle.state, CapsuleLifecycleState.compact);
    lifecycle.expand();
    expect(lifecycle.state, CapsuleLifecycleState.expanded);
    lifecycle.collapse();
    expect(lifecycle.state, CapsuleLifecycleState.compact);
    lifecycle.requestDismiss(CapsuleToastDismissReason.dismissed);
    expect(lifecycle.state, CapsuleLifecycleState.collapsing);
    lifecycle.didHide();
    expect(lifecycle.state, CapsuleLifecycleState.hidden);
  });

  test('hold clock excludes paused time', () {
    final LifecycleClock clock = LifecycleClock()
      ..start(const Duration(seconds: 2));

    expect(clock.advance(const Duration(seconds: 1)), isFalse);
    clock.pause();
    expect(clock.advance(const Duration(seconds: 5)), isFalse);
    clock.resume();
    expect(clock.advance(const Duration(seconds: 1)), isTrue);
  });
}
