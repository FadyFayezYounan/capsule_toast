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
          extensions: <ThemeExtension<dynamic>>[
            CapsuleToastThemeData(surfaceColor: extensionColor),
          ],
        ),
        home: CapsuleToastTheme(
          data: CapsuleToastThemeData(surfaceColor: localColor),
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

  group('motion theme validation', () {
    test('spring rejects non-positive duration and invalid bounce', () {
      expect(
        () => CapsuleToastSpring(duration: Duration.zero, bounce: 0),
        throwsAssertionError,
      );
      expect(
        () => CapsuleToastSpring(
          duration: const Duration(milliseconds: 1),
          bounce: -0.01,
        ),
        throwsAssertionError,
      );
      expect(
        () => CapsuleToastSpring(
          duration: const Duration(milliseconds: 1),
          bounce: 1,
        ),
        throwsAssertionError,
      );
    });

    test('slot delays reject negative durations', () {
      expect(
        () => CapsuleToastMotionTheme(
          slotDelays: const <CapsuleToastSlot, Duration>{
            CapsuleToastSlot.title: Duration(milliseconds: -1),
          },
        ),
        throwsAssertionError,
      );
    });
  });

  test('visual theme rejects negative padding and invalid seed dimensions', () {
    expect(
      () => CapsuleToastThemeData(
        compactPadding: const EdgeInsets.only(left: -1),
      ),
      throwsAssertionError,
    );
    expect(
      () => CapsuleToastThemeData(
        compactActionPadding: const EdgeInsets.only(top: -1),
      ),
      throwsAssertionError,
    );
    expect(
      () => CapsuleToastThemeData(seedSize: const Size(0, 34)),
      throwsAssertionError,
    );
    expect(
      () => CapsuleToastThemeData(seedSize: const Size(84, -1)),
      throwsAssertionError,
    );
  });

  test(
    'partial motion themes interpolate without requiring fallback fields',
    () {
      final CapsuleToastMotionTheme a = CapsuleToastMotionTheme(
        appearanceDuration: Duration(milliseconds: 100),
      );
      final CapsuleToastMotionTheme b = CapsuleToastMotionTheme(
        appearanceDuration: Duration(milliseconds: 300),
        warningDuration: Duration(milliseconds: 400),
      );

      final CapsuleToastMotionTheme middle = a.lerp(b, 0.5);

      expect(middle.appearanceDuration, const Duration(milliseconds: 200));
      expect(middle.warningDuration, const Duration(milliseconds: 400));
      expect(middle.successDuration, isNull);
    },
  );

  test(
    'equal slot-delay maps have equal hashes regardless of insertion order',
    () {
      final CapsuleToastMotionTheme a = CapsuleToastMotionTheme(
        slotDelays: <CapsuleToastSlot, Duration>{
          CapsuleToastSlot.icon: Duration(milliseconds: 10),
          CapsuleToastSlot.title: Duration(milliseconds: 20),
        },
      );
      final CapsuleToastMotionTheme b = CapsuleToastMotionTheme(
        slotDelays: <CapsuleToastSlot, Duration>{
          CapsuleToastSlot.title: Duration(milliseconds: 20),
          CapsuleToastSlot.icon: Duration(milliseconds: 10),
        },
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    },
  );

  test('theme collections are detached from mutable caller-owned inputs', () {
    final Map<CapsuleToastSlot, Duration> delays = <CapsuleToastSlot, Duration>{
      CapsuleToastSlot.icon: const Duration(milliseconds: 10),
    };
    final List<BoxShadow> shadows = <BoxShadow>[const BoxShadow(blurRadius: 4)];
    final CapsuleToastMotionTheme motion = CapsuleToastMotionTheme(
      slotDelays: delays,
    );
    final CapsuleToastThemeData visual = CapsuleToastThemeData(
      shadows: shadows,
    );

    delays[CapsuleToastSlot.icon] = const Duration(milliseconds: 20);
    shadows.clear();

    expect(
      motion.slotDelays![CapsuleToastSlot.icon],
      const Duration(milliseconds: 10),
    );
    expect(visual.shadows, hasLength(1));
    expect(
      () => motion.slotDelays![CapsuleToastSlot.title] = Duration.zero,
      throwsUnsupportedError,
    );
    expect(() => visual.shadows!.clear(), throwsUnsupportedError);
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
