// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/motion/capsule_lifecycle.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_presentation.dart';

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

  testWidgets('per-toast theme controls the entrance seed geometry', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(
        title: 'Themed seed',
        theme: CapsuleToastThemeData(seedSize: const Size(102, 38)),
      ),
      settle: false,
    );

    expect(capsuleSize(tester).width, closeTo(102, 0.01));
    expect(capsuleSize(tester).height, closeTo(38, 0.01));
  });

  testWidgets('ambient theme controls the entrance seed geometry', (
    WidgetTester tester,
  ) async {
    late BuildContext commandContext;
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return CapsuleToastTheme(
            data: CapsuleToastThemeData(seedSize: const Size(96, 36)),
            child: CapsuleToastHost(child: child!),
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

    CapsuleToastHost.of(
      commandContext,
    ).show(CapsuleToastData.success(title: 'Ambient seed'));
    await tester.pump();

    expect(capsuleSize(tester).width, closeTo(96, 0.01));
    expect(capsuleSize(tester).height, closeTo(36, 0.01));
  });

  testWidgets('themed seed also controls exit geometry', (
    WidgetTester tester,
  ) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.success(
        title: 'Wide exit seed',
        persistent: true,
        theme: CapsuleToastThemeData(seedSize: const Size(220, 40)),
      ),
    );

    harness.handle.dismiss();
    await tester.pump(const Duration(milliseconds: 300));

    expect(capsuleSize(tester).width, greaterThan(180));
  });

  testWidgets('reference timestamps have deterministic geometry', (
    tester,
  ) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.information(
        title: 'Backup ready',
        message: 'Two files were added.',
        persistent: true,
      ),
      settle: false,
    );
    expect(capsuleSize(tester).width, closeTo(84, 0.5));
    expect(capsuleSize(tester).height, closeTo(34, 0.5));

    await tester.pump(const Duration(milliseconds: 140));
    expect(capsuleOpacity(tester), closeTo(1, 0.02));
    expect(capsuleSize(tester).width, greaterThan(84));

    await tester.pump(const Duration(milliseconds: 380));
    // Width bounce can trail the 520 ms reference window by a short margin.
    for (int i = 0; i < 6 && !capsuleMotion(tester).isSettled; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(capsuleMotion(tester).isSettled, isTrue);

    harness.handle.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.binding.transientCallbackCount, 0);
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
    final Element presentationBefore = tester.element(
      find.byType(CapsuleToastPresentation),
    );

    harness.manager.show(
      CapsuleToastData.success(title: 'Uploaded'),
      queuePolicy: CapsuleToastQueuePolicy.replace,
    );
    await tester.pump();

    expect(find.byKey(capsuleSurfaceKey), findsOneWidget);
    expect(tester.element(find.byKey(capsuleSurfaceKey)), same(surfaceBefore));
    expect(
      tester.element(find.byType(CapsuleToastPresentation)),
      same(presentationBefore),
    );
  });

  testWidgets('enqueue after exit promotes with fresh entrance', (
    tester,
  ) async {
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
