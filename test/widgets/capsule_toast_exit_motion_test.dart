// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_animated_slot.dart';

import '../support/test_app.dart';

CapsuleToastAnimationScope _scope(WidgetTester tester) {
  return tester.widget<CapsuleToastAnimationScope>(
    find.byType(CapsuleToastAnimationScope),
  );
}

void main() {
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
