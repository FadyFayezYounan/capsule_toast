// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

export 'package:capsule_toast/src/widgets/capsule_toast_surface.dart'
    show capsuleSurfaceKey;

/// No-op action callback for const test fixtures.
void noop() {}

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
  final CapsuleToastMotionTheme motionTheme =
      CapsuleToastMotionTheme.fallback();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        viewPadding: viewPadding,
        padding: viewPadding,
        textScaler: textScaler,
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return CapsuleToastHost(child: child!);
        },
        home: Directionality(
          textDirection: textDirection,
          child: Builder(
            builder: (BuildContext context) {
              commandContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    ),
  );

  CapsuleToastHost.of(commandContext).show(toast);
  await tester.pump();
  if (settle) {
    await tester.pump(motionTheme.appearanceDuration!);
    await tester.pumpAndSettle();
  }
  return commandContext;
}
