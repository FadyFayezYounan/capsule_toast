// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

void main() {
  testWidgets('nearest theme overrides ThemeData extension', (tester) async {
    const Color extensionColor = Color(0xFF010101);
    const Color localColor = Color(0xFF020202);
    late CapsuleToastThemeData resolved;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            CapsuleToastThemeData(surfaceColor: extensionColor),
          ],
        ),
        home: CapsuleToastTheme(
          data: const CapsuleToastThemeData(surfaceColor: localColor),
          child: Builder(
            builder: (BuildContext context) {
              resolved = CapsuleToastTheme.resolve(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(resolved.surfaceColor, localColor);
    expect(resolved.maximumWidth, 340);
    expect(resolved.seedSize, const Size(84, 34));
  });

  test('motion fallback matches the approved reference values', () {
    final CapsuleToastMotionTheme theme = CapsuleToastMotionTheme.fallback();

    expect(theme.appearanceDuration, const Duration(milliseconds: 140));
    expect(theme.heightLead, const Duration(milliseconds: 28));
    expect(theme.slotRevealDuration, const Duration(milliseconds: 220));
    expect(theme.longPressDuration, const Duration(milliseconds: 320));
    expect(theme.dismissalDistance, 26);
  });

  test('custom content requires an announcement when title is absent', () {
    expect(
      () => CapsuleToastData.custom(
        compactBuilder:
            (BuildContext context, CapsuleToastContentContext value) {
              return const SizedBox();
            },
      ),
      throwsAssertionError,
    );
  });
}
