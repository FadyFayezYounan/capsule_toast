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

  testWidgets('compact action label is legible against the capsule', (
    WidgetTester tester,
  ) async {
    // A light host theme is the trap: without an explicit colour the chip
    // label inherits `bodyMedium`, which is near-black on the dark capsule.
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        builder: (BuildContext context, Widget? child) =>
            CapsuleToastHost(child: child!),
        home: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              onPressed: () => CapsuleToastHost.of(context).show(
                CapsuleToastData.success(
                  title: 'Saved',
                  compactAction: CapsuleToastAction(
                    label: 'Undo',
                    onPressed: noop,
                  ),
                ),
              ),
              child: const Text('show'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    final Text label = tester.widget<Text>(find.text('Undo'));
    final TextStyle resolved = DefaultTextStyle.of(
      tester.element(find.text('Undo')),
    ).style.merge(label.style);
    expect(resolved.color, const Color(0xFFF9F9F7));
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

    // 44 view padding plus the default 15 vertical offset.
    expect(
      tester.getTopLeft(find.byKey(capsuleSurfaceKey)).dy,
      closeTo(59, 0.01),
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

  testWidgets('expanded mode does not reuse a compact custom builder', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.custom(
        title: 'Structured expanded fallback',
        initialMode: CapsuleToastMode.expanded,
        compactBuilder:
            (BuildContext context, CapsuleToastContentContext details) {
              return const SizedBox(
                key: ValueKey<String>('compact-builder-marker'),
                width: 180,
                height: 44,
              );
            },
      ),
    );

    expect(find.text('Structured expanded fallback'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('compact-builder-marker')),
      findsNothing,
    );
  });

  testWidgets('compact mode does not reuse an expanded custom builder', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.custom(
        title: 'Structured compact fallback',
        expandedBuilder:
            (BuildContext context, CapsuleToastContentContext details) {
              return const SizedBox(
                key: ValueKey<String>('expanded-builder-marker'),
                width: 240,
                height: 96,
              );
            },
      ),
    );

    expect(find.text('Structured compact fallback'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('expanded-builder-marker')),
      findsNothing,
    );
  });
}
