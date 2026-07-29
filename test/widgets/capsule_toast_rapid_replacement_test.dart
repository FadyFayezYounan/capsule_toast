// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('loading -> resolved -> loading again reuses the glyph state', (
    WidgetTester tester,
  ) async {
    final ToastTestHarness harness = await pumpToastHarness(
      tester,
      CapsuleToastData.loading(title: 'Saving'),
    );

    // Resolve to a static glyph: the glyph state disposes its controller.
    harness.handle.resolve(CapsuleToastData.success(title: 'Saved'));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull, reason: 'resolve should be clean');

    // Show loading again on the same element: the glyph state must build a
    // second ticker.
    harness.manager.show(
      CapsuleToastData.loading(title: 'Saving'),
      queuePolicy: CapsuleToastQueuePolicy.clearAndShow,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });

  testWidgets('hammering the lab loading flow keeps the capsule well formed', (
    WidgetTester tester,
  ) async {
    late BuildContext commandContext;
    await tester.pumpWidget(
      capsuleToastTestApp(
        home: Builder(
          builder: (BuildContext context) {
            commandContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final CapsuleToastManager manager = CapsuleToastHost.of(commandContext);

    for (int spam = 0; spam < 24; spam++) {
      final CapsuleToastHandle handle = manager.show(
        CapsuleToastData.loading(title: 'Saving your capture'),
        queuePolicy: CapsuleToastQueuePolicy.clearAndShow,
      );
      await tester.pump();
      // Uneven gaps: some presses land before the lab's 1.7s resolve, some
      // after, so the glyph crosses loading -> success -> loading repeatedly.
      await tester.pump(Duration(milliseconds: 40 + (spam % 4) * 700));
      if (spam.isEven) {
        handle.resolve(CapsuleToastData.success(title: 'Saved'));
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(tester.takeException(), isNull, reason: 'spam iteration $spam');
      final Size size = capsuleSize(tester);
      expect(
        size.width >= 0 && size.height >= 0,
        isTrue,
        reason: 'iteration $spam produced $size',
      );
    }
  });
}
