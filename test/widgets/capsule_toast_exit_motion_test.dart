// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/motion/capsule_lifecycle.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_animated_slot.dart';

import '../support/test_app.dart';

CapsuleToastAnimationScope _scope(WidgetTester tester) {
  return tester.widget<CapsuleToastAnimationScope>(
    find.byType(CapsuleToastAnimationScope),
  );
}

/// Eased reveal progress of [slot] under the live animation scope.
double _slotProgress(WidgetTester tester, CapsuleToastSlot slot) {
  final CapsuleToastAnimationScope scope = _scope(tester);
  final Duration delay = scope.revealing
      ? (scope.motionTheme.slotDelays?[slot] ?? Duration.zero)
      : capsuleToastRetractDelays[slot]!;
  final Duration interval = scope.revealing
      ? scope.motionTheme.slotRevealDuration!
      : capsuleToastRetractInterval;
  final double t =
      (scope.contentElapsed.inMicroseconds - delay.inMicroseconds) /
      interval.inMicroseconds;
  final double eased = 1 - math.pow(1 - t.clamp(0.0, 1.0), 3).toDouble();
  return scope.revealing ? eased : 1 - eased;
}

void main() {
  testWidgets('exit retracts content action-first, icon last', (tester) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.success(
        title: 'Saved',
        message: 'Your changes are safe.',
        initialMode: CapsuleToastMode.expanded,
        persistent: true,
        primaryAction: CapsuleToastAction(label: 'View', onPressed: noop),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    expect(_scope(tester).revealing, isTrue);
    expect(_slotProgress(tester, CapsuleToastSlot.icon), closeTo(1, 0.001));

    harness.handle.dismiss();
    await tester.pump();
    // 110ms in: every slot has started (the icon waits 100ms) and none has
    // finished (each takes 130ms). Before the retract clock was reset at
    // dismissal, this whole envelope collapsed into a single frame.
    await tester.pump(const Duration(milliseconds: 110));

    expect(_scope(tester).revealing, isFalse);
    final double action = _slotProgress(tester, CapsuleToastSlot.action);
    final double message = _slotProgress(tester, CapsuleToastSlot.message);
    final double title = _slotProgress(tester, CapsuleToastSlot.title);
    final double icon = _slotProgress(tester, CapsuleToastSlot.icon);

    expect(action, lessThan(message));
    expect(message, lessThan(title));
    expect(title, lessThan(icon));
    // Mid-retract, not snapped: every slot is strictly between visible and gone.
    expect(action, greaterThan(0));
    expect(icon, lessThan(1));
  });

  group('exit offset', () {
    testWidgets('swipe carries the drag offset and flick momentum', (
      tester,
    ) async {
      final ToastTestHarness harness = await pumpToastHarness(
        tester,
        CapsuleToastData.success(title: 'Saved', persistent: true),
      );
      expect(harness.motion.value.verticalOffset, closeTo(0, 0.01));

      await tester.fling(
        find.byKey(capsuleSurfaceKey),
        const Offset(0, -80),
        1200,
      );
      await tester.pump();

      // The exit begins from where the finger released the capsule, plus a
      // velocity-proportional kick — not from rest.
      expect(harness.motion.value.verticalOffset, lessThan(-60));
    });

    testWidgets('programmatic dismissal only rises the seed 6pt', (
      tester,
    ) async {
      final ToastTestHarness harness = await pumpToastHarness(
        tester,
        CapsuleToastData.success(title: 'Saved', persistent: true),
      );

      harness.handle.dismiss();
      await tester.pump();
      expect(harness.motion.value.verticalOffset, closeTo(0, 0.01));

      // Fade runs 200–340 ms into the exit; by the end the rise is complete.
      await tester.pump(const Duration(milliseconds: 340));
      expect(harness.motion.value.verticalOffset, closeTo(-6, 0.5));
    });

    testWidgets('released drag springs back to rest without dismissing', (
      tester,
    ) async {
      final ToastTestHarness harness = await pumpToastHarness(
        tester,
        CapsuleToastData.success(title: 'Saved', persistent: true),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(capsuleSurfaceKey)),
      );
      // The first move only crosses the touch slop; travel accrues after that.
      await gesture.moveBy(const Offset(0, -20));
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
      expect(harness.motion.value.verticalOffset, lessThan(-5));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(harness.motion.value.verticalOffset, closeTo(0, 0.5));
      expect(harness.handle.isClosed, isFalse);
    });
  });

  group('dismiss while entering', () {
    testWidgets(
      'fades from the current partial appearance instead of snapping open',
      (tester) async {
        final ToastTestHarness harness = await pumpToastHarness(
          tester,
          CapsuleToastData.success(title: 'Saved', persistent: true),
          settle: false,
        );

        // Partway into the ~140ms appearance: still visibly entering, not
        // yet fully opaque.
        await tester.pump(const Duration(milliseconds: 40));
        expect(harness.motion.value.state, CapsuleLifecycleState.seed);
        final double opacityBeforeDismiss = harness.motion.value.opacity;
        expect(opacityBeforeDismiss, lessThan(0.9));

        harness.handle.dismiss();

        // A dismissal mid-entrance should continue fading from wherever the
        // capsule already was, not snap fully open first and then
        // immediately collapse — that reads as the capsule flashing open
        // before taking it back.
        expect(
          harness.motion.value.opacity,
          lessThanOrEqualTo(opacityBeforeDismiss + 0.01),
        );
        expect(harness.motion.value.state, CapsuleLifecycleState.collapsing);
      },
    );
  });

  group('icon travel', () {
    testWidgets('starts at the capsule centre in LTR', (tester) async {
      await pumpToast(
        tester,
        CapsuleToastData.success(title: 'Reminder created', persistent: true),
      );

      final CapsuleToastThemeData theme = CapsuleToastThemeData.fallback();
      final double iconCentre =
          theme.compactPadding!.resolve(TextDirection.ltr).left +
          theme.compactIconSize! / 2;
      final double expected = capsuleSize(tester).width / 2 - iconCentre;

      expect(_scope(tester).iconTravel, closeTo(expected, 1.0));
      expect(_scope(tester).iconTravel, greaterThan(0));
    });

    testWidgets('mirrors under RTL', (tester) async {
      await pumpToast(
        tester,
        CapsuleToastData.success(title: 'تم إنشاء التذكير', persistent: true),
        textDirection: TextDirection.rtl,
      );

      final CapsuleToastThemeData theme = CapsuleToastThemeData.fallback();
      final double iconCentre =
          theme.compactPadding!.resolve(TextDirection.rtl).right +
          theme.compactIconSize! / 2;
      final double expected = -(capsuleSize(tester).width / 2 - iconCentre);

      expect(_scope(tester).iconTravel, closeTo(expected, 1.0));
      expect(_scope(tester).iconTravel, lessThan(0));
    });
  });
}
