// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/manager/capsule_toast_coordinator.dart';
import 'package:capsule_toast/src/motion/capsule_motion_controller.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_motion_synchronizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('synchronize starts a new record from its themed seed', () {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastMotionTheme motionTheme =
        CapsuleToastMotionTheme.fallback();
    final CapsuleMotionController motion = CapsuleMotionController(
      vsync: const TestVSync(),
      motionTheme: motionTheme,
      onHoldElapsed: coordinator.timeoutActive,
      onExitCompleted: coordinator.finishActiveExit,
    );
    final CapsuleToastMotionSynchronizer synchronizer =
        CapsuleToastMotionSynchronizer(
          coordinator: coordinator,
          motion: motion,
          scheduleSync: () {},
        );
    addTearDown(() {
      motion.dispose();
      coordinator.dispose();
    });

    coordinator.show(
      CapsuleToastData.success(
        title: 'Seeded',
        persistent: true,
        theme: CapsuleToastThemeData(seedSize: const Size(102, 38)),
      ),
    );
    final CapsuleToastThemeData visualTheme = CapsuleToastThemeData.fallback()
        .merge(coordinator.active!.data.theme);

    synchronizer.synchronize(
      record: coordinator.active,
      visualTheme: visualTheme,
      motionTheme: motionTheme,
      reducedMotion: false,
    );

    expect(motion.value.size, const Size(102, 38));
  });
}
