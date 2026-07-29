// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

/// Key of the painted capsule chrome inside [CapsuleToastSurface].
const Key decorationKey = ValueKey<String>('capsule_toast.decoration');

CapsuleToastData _successToast() {
  return CapsuleToastData.success(
    title: 'Reminder created',
    message: 'We’ll notify you tomorrow at 6:00 PM.',
    compactAction: CapsuleToastAction(label: 'View', onPressed: noop),
    primaryAction: CapsuleToastAction(label: 'View reminder', onPressed: noop),
    secondaryAction: CapsuleToastAction(label: 'Dismiss', onPressed: noop),
    persistent: true,
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('compact capsule settles at the reference 44pt height', (
    tester,
  ) async {
    await pumpToast(tester, _successToast());
    await _settle(tester);

    // The reference compact row is a fixed 44pt box: 5pt padding, a 34pt icon,
    // 5pt padding. Anything taller is padding added outside that box.
    expect(capsuleSize(tester).height, closeTo(44, 0.5));
  });

  testWidgets('re-showing identical content re-measures the capsule', (
    tester,
  ) async {
    final BuildContext context = await pumpToast(tester, _successToast());
    await _settle(tester);
    final Size first = capsuleSize(tester);
    expect(first.width, greaterThan(84));

    // Same content, new token: the reference re-seeds and springs back out to
    // the same size. A stale measurement cache leaves it stranded at the seed.
    CapsuleToastHost.of(context).show(_successToast());
    await tester.pump();
    await _settle(tester);

    expect(capsuleSize(tester).width, closeTo(first.width, 0.5));
    expect(capsuleSize(tester).height, closeTo(first.height, 0.5));
  });

  testWidgets('painted chrome tracks the spring in both directions', (
    tester,
  ) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      _successToast(),
    );
    await _settle(tester);
    final Size compact = capsuleSize(tester);

    // The chrome is what the eye follows, so it has to be the thing the spring
    // moves — every frame, growing and shrinking alike. Sampling one frame
    // would miss a snap that happens on any of the others.
    void expectChromeOnSpring() {
      final Size live = capsuleSize(tester);
      final Size painted = tester.getSize(find.byKey(decorationKey));
      expect(painted.width, closeTo(live.width, 0.5));
      expect(painted.height, closeTo(live.height, 0.5));
    }

    Future<List<double>> sampleFrames(int count) async {
      final List<double> heights = <double>[];
      for (int i = 0; i < count; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expectChromeOnSpring();
        heights.add(tester.getSize(find.byKey(decorationKey)).height);
      }
      return heights;
    }

    harness.handle.expand();
    await tester.pump();
    final List<double> growing = await sampleFrames(30);
    await _settle(tester);
    final Size expanded = capsuleSize(tester);
    expect(expanded.height, greaterThan(compact.height));

    harness.handle.collapse();
    await tester.pump();
    final List<double> shrinking = await sampleFrames(30);
    await _settle(tester);
    expect(capsuleSize(tester).height, closeTo(compact.height, 0.5));

    // A snap covers the whole journey in one frame; a spring covers a little
    // of it in each. Bounding the largest single-frame step is what separates
    // the two, and it has to hold on the way back as well as the way out.
    final double travel = expanded.height - compact.height;
    double largestStep(List<double> heights) {
      double largest = 0;
      for (int i = 1; i < heights.length; i++) {
        largest = math.max(largest, (heights[i] - heights[i - 1]).abs());
      }
      return largest;
    }

    expect(largestStep(growing), lessThan(travel * 0.25));
    expect(
      largestStep(shrinking),
      lessThan(travel * 0.25),
      reason: 'Collapse must ease back, not snap to the compact size.',
    );
  });
}
