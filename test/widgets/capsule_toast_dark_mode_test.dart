// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

/// Key of the painted capsule chrome inside `CapsuleToastSurface`.
const Key decorationKey = ValueKey<String>('capsule_toast.decoration');

BoxDecoration _paintedDecoration(WidgetTester tester) {
  final DecoratedBox box = tester.widget(find.byKey(decorationKey).first);
  return box.decoration as BoxDecoration;
}

Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('a dark app paints the lifted surface and the brighter rim', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(title: 'Reminder created', persistent: true),
      brightness: Brightness.dark,
    );
    await _settle(tester);

    final BoxDecoration decoration = _paintedDecoration(tester);
    expect(decoration.color, const Color(0xFF26231E));
    expect((decoration.border! as Border).top.color, const Color(0x26F9F6F0));
    expect(decoration.boxShadow!.first.color, const Color(0x75000000));
  });

  testWidgets('a light app is unchanged', (WidgetTester tester) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(title: 'Reminder created', persistent: true),
    );
    await _settle(tester);

    final BoxDecoration decoration = _paintedDecoration(tester);
    expect(decoration.color, const Color(0xFF161614));
    expect((decoration.border! as Border).top.color, const Color(0x12F9F9F7));
  });

  testWidgets('the rim highlight is painted only where the token is set', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(title: 'Reminder created', persistent: true),
      brightness: Brightness.dark,
    );
    await _settle(tester);
    expect(find.byKey(capsuleHighlightKey), findsOneWidget);

    await pumpToast(
      tester,
      CapsuleToastData.success(title: 'Reminder created', persistent: true),
    );
    await _settle(tester);
    expect(find.byKey(capsuleHighlightKey), findsNothing);
  });

  testWidgets('an explicit highlight override reaches the painter', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(
        title: 'Reminder created',
        persistent: true,
        theme: CapsuleToastThemeData(
          innerHighlightColor: const Color(0x40FFFFFF),
        ),
      ),
    );
    await _settle(tester);

    // The light base has no highlight, so this proves the token — not the
    // brightness — is what gates the painter.
    expect(find.byKey(capsuleHighlightKey), findsOneWidget);
  });
}
