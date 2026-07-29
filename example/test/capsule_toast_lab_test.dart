// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast_example/capsule_toast_lab.dart';
import 'package:capsule_toast_example/lab/lab_phone.dart';
import 'package:capsule_toast_example/lab/lab_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lab demonstrates statuses queue and loading resolution', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CapsuleToastExampleApp());

    expect(find.text('Capsule Toast'), findsOneWidget);
    expect(find.text('Success'), findsWidgets);
    expect(find.text('Saving → Created'), findsOneWidget);
    expect(find.text('Queue 3 events'), findsOneWidget);
    expect(find.text('Right-to-left'), findsOneWidget);
    expect(find.text('Reduced motion'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Queue 3 events'));
    await tester.pump();
    final CapsuleToastManager manager = CapsuleToastHost.of(
      tester.element(find.byType(LabDemoDock)),
    );
    expect(manager.queueLength, 2);

    manager.clear();
    await tester.pump(const Duration(milliseconds: 400));
    tester.view.physicalSize = const Size(800, 600);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the appearance picker drives the phone and the capsule', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CapsuleToastExampleApp());

    Color screenColor() {
      final ColoredBox box = tester.widget(
        find.descendant(
          of: find.byType(LabPhoneScreen),
          matching: find.byType(ColoredBox),
        ),
      );
      return box.color;
    }

    expect(screenColor(), Lab.bg);

    await tester.tap(find.text('Dark app'));
    await tester.pump();
    expect(screenColor(), Lab.darkBg);

    // A toast fired under the dark phone resolves the dark capsule, which the
    // light appearance has no equivalent of.
    await tester.tap(find.text('Success').last);
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    final CapsuleToastThemeData resolved = CapsuleToastTheme.resolve(
      tester.element(find.byType(LabDemoDock)),
    );
    expect(resolved.surfaceColor, const Color(0xFF26231E));
    expect(resolved.innerHighlightColor, const Color(0x1AFFFFFF));

    await tester.tap(find.text('Light app'));
    await tester.pump();
    expect(screenColor(), Lab.bg);

    expect(tester.takeException(), isNull);
  });
}
