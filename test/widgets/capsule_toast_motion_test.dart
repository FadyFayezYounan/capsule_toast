// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/motion/capsule_lifecycle.dart';

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

  testWidgets('enqueue after exit promotes with fresh entrance', (tester) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.success(title: 'First', persistent: true),
    );

    harness.manager.show(
      CapsuleToastData.success(title: 'Second', persistent: true),
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
    );
    await tester.pump();
    expect(find.text('First'), findsOneWidget);

    harness.handle.dismiss();
    await tester.pump();
    // Full exit (340ms) then finishActiveExit promotes the queued toast.
    await tester.pump(const Duration(milliseconds: 340));
    await tester.pump();

    expect(find.text('Second'), findsOneWidget);
    expect(capsuleMotion(tester).state, CapsuleLifecycleState.seed);

    await tester.pump(const Duration(milliseconds: 80));
    expect(capsuleOpacity(tester), greaterThan(0));

    await tester.pump(const Duration(milliseconds: 520));
    expect(capsuleSize(tester).height, greaterThanOrEqualTo(44));
    expect(capsuleOpacity(tester), closeTo(1, 0.05));
  });

  testWidgets('replace while collapsing starts fresh entrance', (tester) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.success(title: 'Leaving', persistent: true),
    );
    final Future<CapsuleToastResult> firstClosed = harness.handle.closed;

    harness.handle.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(capsuleMotion(tester).state, CapsuleLifecycleState.collapsing);

    final CapsuleToastHandle second = harness.manager.show(
      CapsuleToastData.success(title: 'Incoming', persistent: true),
      queuePolicy: CapsuleToastQueuePolicy.replace,
    );
    await tester.pump();

    expect(await firstClosed, isA<CapsuleToastResult>());
    expect(second.isClosed, isFalse);
    expect(find.text('Incoming'), findsOneWidget);
    expect(capsuleMotion(tester).state, CapsuleLifecycleState.seed);

    await tester.pump(const Duration(milliseconds: 520));
    expect(second.isClosed, isFalse);
    expect(capsuleOpacity(tester), closeTo(1, 0.05));
    expect(capsuleSize(tester).height, greaterThanOrEqualTo(44));
  });
}
