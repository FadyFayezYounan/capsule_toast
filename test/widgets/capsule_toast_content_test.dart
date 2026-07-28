// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('compact content shows glyph title and compact action', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await pumpToast(
      tester,
      CapsuleToastData.success(
        title: 'Saved',
        compactAction: CapsuleToastAction(label: 'Undo', onPressed: noop),
      ),
    );

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('capsule.success.glyph')),
      findsOneWidget,
    );
    expect(CapsuleToastHost.of(context).queueLength, 0);
  });

  testWidgets('expanded content shows message and two actions', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.warning(
        title: 'Connection unstable',
        message: 'Changes will sync when the network recovers.',
        initialMode: CapsuleToastMode.expanded,
        primaryAction: CapsuleToastAction(label: 'Retry', onPressed: noop),
        secondaryAction: CapsuleToastAction(label: 'Dismiss', onPressed: noop),
      ),
    );

    expect(
      find.text('Changes will sync when the network recovers.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('compact remains inside a narrow viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpToast(
      tester,
      CapsuleToastData.information(
        title: 'A very long title that must be constrained',
      ),
    );

    expect(
      tester.getSize(find.byKey(capsuleSurfaceKey)).width,
      lessThanOrEqualTo(248),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('surface is placed below the safe-area inset', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.neutral(title: 'Safe'),
      viewPadding: const EdgeInsets.only(top: 44),
    );

    expect(
      tester.getTopLeft(find.byKey(capsuleSurfaceKey)).dy,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('per-toast visual overrides win over ambient theme', (
    WidgetTester tester,
  ) async {
    const Color override = Color(0xFF301020);
    await pumpToast(
      tester,
      CapsuleToastData.neutral(
        title: 'Custom surface',
        theme: CapsuleToastThemeData(surfaceColor: override),
      ),
    );

    final DecoratedBox box = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey<String>('capsule_toast.decoration')),
    );
    expect((box.decoration as BoxDecoration).color, override);
  });
}
