// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/motion/capsule_motion_controller.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_layer.dart';

export 'package:capsule_toast/src/motion/capsule_motion_controller.dart'
    show CapsuleMotionController, CapsuleMotionSnapshot;
export 'package:capsule_toast/src/widgets/capsule_toast_surface.dart'
    show capsuleSurfaceKey;

/// No-op action callback for const test fixtures.
void noop() {}

/// Bundles manager, handle, and motion controller for widget tests.
final class ToastTestHarness {
  /// Creates a harness around one pumped toast presentation.
  const ToastTestHarness({
    required this.manager,
    required this.handle,
    required this.motion,
  });

  /// Host-owned toast manager.
  final CapsuleToastManager manager;

  /// Handle for the toast shown by [pumpToastHarness].
  final CapsuleToastHandle handle;

  /// Host-owned motion controller driving the active capsule.
  final CapsuleMotionController motion;
}

/// Wraps [child] in a [MaterialApp] with a [CapsuleToastHost] installed via
/// [MaterialApp.builder].
Widget capsuleToastTestApp({required Widget home}) {
  return MaterialApp(
    builder: (BuildContext context, Widget? child) {
      return CapsuleToastHost(child: child!);
    },
    home: home,
  );
}

/// Pumps [toast] through the host and returns the command [BuildContext].
Future<BuildContext> pumpToast(
  WidgetTester tester,
  CapsuleToastData toast, {
  bool settle = true,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
  EdgeInsets viewPadding = EdgeInsets.zero,
}) async {
  late BuildContext commandContext;
  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewPadding: viewPadding,
            padding: viewPadding,
            textScaler: textScaler,
            disableAnimations: disableAnimations,
          ),
          child: Directionality(
            textDirection: textDirection,
            child: CapsuleToastHost(child: child!),
          ),
        );
      },
      home: Builder(
        builder: (BuildContext context) {
          commandContext = context;
          return const SizedBox();
        },
      ),
    ),
  );

  CapsuleToastHost.of(commandContext).show(toast);
  await tester.pump();
  if (settle) {
    // Advance through the reference settle window in steps so bounce springs
    // can reach settlement (a single long pump can leave lifecycle in seed).
    // Avoid pumpAndSettle so persistent loading glyphs and hold clocks do not
    // hang the harness.
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  return commandContext;
}

/// Pumps [toast] and returns manager, handle, and motion for inspection.
Future<ToastTestHarness> pumpToastHarness(
  WidgetTester tester,
  CapsuleToastData toast, {
  bool settle = true,
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final BuildContext context = await pumpToast(
    tester,
    toast,
    settle: settle,
    disableAnimations: disableAnimations,
    textDirection: textDirection,
    textScaler: textScaler,
  );
  final CapsuleToastManager manager = CapsuleToastHost.of(context);
  final CapsuleToastLayer layer = tester.widget(find.byType(CapsuleToastLayer));
  return ToastTestHarness(
    manager: manager,
    handle: layer.coordinator.active!.handle,
    motion: layer.motion,
  );
}

/// Current spring-driven capsule size.
Size capsuleSize(WidgetTester tester) => capsuleMotion(tester).size;

/// Current capsule opacity from the motion snapshot.
double capsuleOpacity(WidgetTester tester) => capsuleMotion(tester).opacity;

/// Current motion snapshot for the active capsule.
CapsuleMotionSnapshot capsuleMotion(WidgetTester tester) {
  final CapsuleToastLayer layer = tester.widget(find.byType(CapsuleToastLayer));
  return layer.motion.value;
}
