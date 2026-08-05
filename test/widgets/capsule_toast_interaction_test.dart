// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('tap toggles compact and expanded modes', (tester) async {
    await pumpToast(
      tester,
      CapsuleToastData.information(
        title: 'Backup ready',
        message: 'Tap to see the backup details.',
      ),
    );
    final double compactHeight = capsuleSize(tester).height;

    await tester.tap(find.byKey(capsuleSurfaceKey));
    // The expanded target is whatever the expanded layout measures, which is
    // only known once that layout has been through a frame. The spring picks
    // it up on the tick after, rather than moving toward an estimate first.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));
    final double expandedHeight = capsuleSize(tester).height;
    expect(expandedHeight, greaterThan(compactHeight));

    await tester.tap(find.byKey(capsuleSurfaceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));
    expect(capsuleSize(tester).height, closeTo(compactHeight, 1));

    // Both sizes are cached now, so a repeat expand retargets on the same
    // frame as the gesture and settles at exactly the height measured before.
    await tester.tap(find.byKey(capsuleSurfaceKey));
    await tester.pump(const Duration(milliseconds: 520));
    expect(capsuleSize(tester).height, closeTo(expandedHeight, 1));
  });

  testWidgets('tapping a compactOnly toast does not expand it', (tester) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(
        title: 'Saved',
        expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
      ),
    );
    final double compactHeight = capsuleSize(tester).height;

    await tester.tap(find.byKey(capsuleSurfaceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(capsuleSize(tester).height, closeTo(compactHeight, 1));
  });

  testWidgets('tapping an expandedOnly toast does not collapse it', (
    tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.warning(
        title: 'Attention',
        message: 'Review the information before continuing.',
        initialMode: CapsuleToastMode.expanded,
        expansionPolicy: CapsuleToastExpansionPolicy.expandedOnly,
      ),
    );
    final double expandedHeight = capsuleSize(tester).height;

    await tester.tap(find.byKey(capsuleSurfaceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(capsuleSize(tester).height, closeTo(expandedHeight, 1));
  });

  testWidgets('long-pressing a compactOnly toast does not expand it', (
    tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(
        title: 'Saved',
        expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
      ),
    );
    final double compactHeight = capsuleSize(tester).height;

    await tester.longPress(find.byKey(capsuleSurfaceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(capsuleSize(tester).height, closeTo(compactHeight, 1));
  });

  testWidgets('pressing pauses auto-dismiss', (tester) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(
        title: 'Saved',
        displayDuration: const Duration(seconds: 1),
      ),
    );
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(capsuleSurfaceKey)),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(capsuleSurfaceKey), findsOneWidget);

    await gesture.up();
    // The paused controller has released its ticker; establish the resumed
    // ticker's zero-time frame before advancing the remaining hold duration.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(capsuleSurfaceKey), findsNothing);
  });

  testWidgets('a settled paused toast releases its motion ticker', (
    WidgetTester tester,
  ) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.success(
        title: 'Paused efficiently',
        displayDuration: const Duration(seconds: 10),
      ),
    );
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(capsuleSurfaceKey)),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(harness.motion.debugInteractionPaused, isTrue);
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byKey(capsuleSurfaceKey), findsOneWidget);

    await gesture.up();
  });

  testWidgets('elapsed hold completes with timedOut', (tester) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.success(
        title: 'Brief',
        displayDuration: const Duration(milliseconds: 100),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      (await harness.handle.closed).reason,
      CapsuleToastDismissReason.timedOut,
    );
  });

  testWidgets('handle dismiss completes after the exit animation', (
    tester,
  ) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.neutral(title: 'Dismiss me'),
    );

    harness.handle.dismiss();
    expect(harness.handle.isClosed, isFalse);
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      (await harness.handle.closed).reason,
      CapsuleToastDismissReason.dismissed,
    );
  });

  testWidgets('upward swipe dismisses with swiped result', (tester) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.neutral(title: 'Swipe me'),
    );

    await tester.fling(
      find.byKey(capsuleSurfaceKey),
      const Offset(0, -80),
      900,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      (await harness.handle.closed).reason,
      CapsuleToastDismissReason.swiped,
    );
  });

  testWidgets('loading resolves without replacing its handle', (tester) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.loading(title: 'Uploading'),
    );

    harness.handle.resolve(CapsuleToastData.success(title: 'Uploaded'));
    await tester.pump(const Duration(milliseconds: 520));

    expect(find.text('Uploaded'), findsOneWidget);
    expect(harness.handle.isClosed, isFalse);
    expect(find.byKey(capsuleSurfaceKey), findsOneWidget);
  });

  testWidgets('keyboard activates the focused action', (tester) async {
    bool invoked = false;
    await pumpToast(
      tester,
      CapsuleToastData.neutral(
        title: 'Keyboard ready',
        compactAction: CapsuleToastAction(
          label: 'Open',
          onPressed: () => invoked = true,
          dismissOnInvoke: false,
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(invoked, isTrue);
  });

  testWidgets('dismissing action is isolated and returned in result', (
    tester,
  ) async {
    const CapsuleToastAction action = CapsuleToastAction(
      label: 'Undo',
      onPressed: noop,
    );
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.success(title: 'Saved', compactAction: action),
    );
    final double heightBefore = capsuleSize(tester).height;

    await tester.tap(find.text('Undo'));
    await tester.pump(const Duration(milliseconds: 400));
    final CapsuleToastResult result = await harness.handle.closed;

    expect(result.reason, CapsuleToastDismissReason.actionSelected);
    expect(result.action, same(action));
    // Compact chrome with an action sits above the 44px minimum.
    expect(heightBefore, lessThan(70));
  });
}
