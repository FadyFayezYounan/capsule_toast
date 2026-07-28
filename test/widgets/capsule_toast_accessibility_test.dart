// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

Widget customCompactBuilder(
  BuildContext context,
  CapsuleToastContentContext details,
) {
  return CapsuleToastAnimatedSlot(
    slot: CapsuleToastSlot.title,
    child: const Text('Custom calendar content'),
  );
}

void main() {
  testWidgets('toast is a live region with a composed label', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.error(
        title: 'Upload failed',
        message: 'Check the connection.',
      ),
    );

    expect(
      tester.getSemantics(find.byKey(capsuleSurfaceKey)),
      matchesSemantics(
        label: 'Error. Upload failed Check the connection.',
        isLiveRegion: true,
        textDirection: TextDirection.ltr,
      ),
    );
  });

  testWidgets('explicit announcement replaces composed semantics', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.custom(
        semanticAnnouncement: 'Calendar updated.',
        compactBuilder: customCompactBuilder,
      ),
    );

    expect(find.bySemanticsLabel('Calendar updated.'), findsOneWidget);
  });

  testWidgets('RTL mirrors structured order and slot travel', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.information(title: 'تم الحفظ'),
      textDirection: TextDirection.rtl,
    );

    expect(
      tester
          .getTopRight(
            find.byKey(const ValueKey<String>('capsule.information.glyph')),
          )
          .dx,
      greaterThan(tester.getTopRight(find.text('تم الحفظ')).dx),
    );
  });

  testWidgets('reduced motion removes overshoot and directional travel', (
    WidgetTester tester,
  ) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.success(title: 'Saved'),
      disableAnimations: true,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(harness.motion.debugHasOvershoot, isFalse);
    expect(harness.motion.debugContentTravel, Offset.zero);
  });

  testWidgets('per-toast reduced-motion policy wins over ambient settings', (
    WidgetTester tester,
  ) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.success(
        title: 'Reduced by override',
        motionTheme: const CapsuleToastMotionTheme(
          reducedMotionPolicy: CapsuleToastReducedMotionPolicy.always,
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(harness.motion.debugHasOvershoot, isFalse);
    expect(harness.motion.debugContentTravel, Offset.zero);
  });

  testWidgets('large text expands height without overflowing', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.warning(
        title: 'Attention',
        message: 'Review the information before continuing.',
        initialMode: CapsuleToastMode.expanded,
      ),
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    expect(capsuleSize(tester).height, greaterThan(88));
  });

  testWidgets('live window resize retargets the mounted surface', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.information(title: 'Window-aware notification'),
    );
    final Element surfaceBefore = tester.element(find.byKey(capsuleSurfaceKey));

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(240, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(tester.getSize(find.byKey(capsuleSurfaceKey)).width, lessThan(208));
    expect(tester.element(find.byKey(capsuleSurfaceKey)), same(surfaceBefore));
  });
}
