// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('appearance begins at seed and settles compact', (tester) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(title: 'Saved'),
      settle: false,
    );

    expect(capsuleSize(tester).width, closeTo(84, 0.5));
    expect(capsuleSize(tester).height, closeTo(34, 0.5));
    await tester.pump(const Duration(milliseconds: 520));
    expect(capsuleSize(tester).height, greaterThanOrEqualTo(44));
  });

  testWidgets('expand retarget preserves width velocity', (tester) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.information(
        title: 'Syncing',
        message: 'Two files remain.',
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 80));
    final double before = harness.motion.debugWidthVelocity;

    harness.handle.expand();
    await tester.pump();

    expect(harness.motion.debugWidthVelocity, before);
  });

  testWidgets('replace keeps exactly one surface mounted', (tester) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.loading(title: 'Uploading'),
    );
    await tester.pump(const Duration(milliseconds: 180));
    final Element surfaceBefore = tester.element(find.byKey(capsuleSurfaceKey));

    harness.manager.show(
      CapsuleToastData.success(title: 'Uploaded'),
      queuePolicy: CapsuleToastQueuePolicy.replace,
    );
    await tester.pump();

    expect(find.byKey(capsuleSurfaceKey), findsOneWidget);
    expect(tester.element(find.byKey(capsuleSurfaceKey)), same(surfaceBefore));
  });
}
