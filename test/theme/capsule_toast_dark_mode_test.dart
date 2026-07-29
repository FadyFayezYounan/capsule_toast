// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

/// Alpha channel of [color] as the 0–1 fraction the reference states.
double _alpha(Color color) => color.a;

void main() {
  group('dark fallback matches the reference CAPSULE_DARK tokens', () {
    final CapsuleToastThemeData dark = CapsuleToastThemeData.fallback(
      Brightness.dark,
    );

    test('surface, foreground and rim', () {
      expect(dark.surfaceColor, const Color(0xFF26231E));
      expect(dark.foregroundColor, const Color(0xFFF7F4EE));
      expect(dark.secondaryForegroundColor, const Color(0xA8F7F4EE));
      expect(dark.borderColor, const Color(0x26F9F6F0));
      expect(dark.borderWidth, 0.5);
      expect(dark.actionSurfaceColor, const Color(0x21F9F6F0));
    });

    test('inner top highlight', () {
      expect(dark.innerHighlightColor, const Color(0x1AFFFFFF));
      expect(dark.innerHighlightWidth, 0.5);
    });

    test('shadows drop the warm cast and deepen', () {
      expect(dark.shadows, hasLength(2));
      expect(dark.shadows![0].offset, const Offset(0, 2));
      expect(dark.shadows![0].blurRadius, closeTo(6.06, 0.01));
      expect(dark.shadows![0].color, const Color(0x75000000));
      expect(dark.shadows![1].offset, const Offset(0, 14));
      expect(dark.shadows![1].blurRadius, closeTo(30.31, 0.01));
      expect(dark.shadows![1].color, const Color(0x6B000000));
    });

    test('tints carry the boosted alpha', () {
      expect(dark.tints!.success, const Color(0x3795A584));
      expect(dark.tints!.information, const Color(0x378AA4BD));
      expect(dark.tints!.warning, const Color(0x37D89858));
      expect(dark.tints!.error, const Color(0x3ED67D65));
      expect(dark.tints!.loading, const Color(0x1CF9F9F7));
      expect(dark.tints!.neutral, const Color(0x1CF9F9F7));
      expect(dark.tints!.custom, const Color(0x1CF9F9F7));
    });

    test('action styles follow the dark foreground', () {
      const Set<WidgetState> resting = <WidgetState>{};
      expect(
        dark.primaryActionStyle!.backgroundColor!.resolve(resting),
        const Color(0xFFF7F4EE),
      );
      expect(
        dark.primaryActionStyle!.foregroundColor!.resolve(resting),
        const Color(0xFF211E19),
      );
      expect(
        dark.compactActionStyle!.foregroundColor!.resolve(resting),
        const Color(0xFFF7F4EE),
      );
      expect(
        dark.secondaryActionStyle!.foregroundColor!.resolve(resting),
        const Color(0xA8F7F4EE),
      );
    });
  });

  test('accents do not vary with appearance', () {
    // TONES in the reference is appearance-agnostic: only tint alpha moves.
    // Pinning this keeps a future edit deliberate rather than accidental.
    expect(
      CapsuleToastThemeData.fallback(Brightness.dark).accents,
      CapsuleToastThemeData.fallback(Brightness.light).accents,
    );
  });

  test('dark tint alpha is the light alpha boosted by 1.35', () {
    // Guards the rule, not just the transcribed hex values. The reference
    // applies the boost to the CSS fraction and each appearance then rounds to
    // a byte independently, so the two roundings can drift by up to
    // 0.5/255 + 1.35 * 0.5/255 ≈ 0.0046 without the rule being broken.
    final CapsuleToastTints light = CapsuleToastThemeData.fallback(
      Brightness.light,
    ).tints!;
    final CapsuleToastTints dark = CapsuleToastThemeData.fallback(
      Brightness.dark,
    ).tints!;
    for (final CapsuleToastType type in CapsuleToastType.values) {
      expect(
        _alpha(dark.colorFor(type)),
        closeTo(_alpha(light.colorFor(type)) * 1.35, 0.005),
        reason: 'tintBoost 1.35 not applied to $type',
      );
    }
  });

  test('the light appearance is unchanged and stays the default', () {
    final CapsuleToastThemeData light = CapsuleToastThemeData.fallback(
      Brightness.light,
    );
    expect(light.surfaceColor, const Color(0xFF161614));
    expect(light.borderColor, const Color(0x12F9F9F7));
    expect(light.innerHighlightColor, isNull);
    expect(light.innerHighlightWidth, isNull);
    expect(CapsuleToastThemeData.fallback(), light);
  });

  test('geometry and typography are shared between appearances', () {
    final CapsuleToastThemeData light = CapsuleToastThemeData.fallback(
      Brightness.light,
    );
    final CapsuleToastThemeData dark = CapsuleToastThemeData.fallback(
      Brightness.dark,
    );
    expect(dark.seedSize, light.seedSize);
    expect(dark.maximumWidth, light.maximumWidth);
    expect(dark.radiusCap, light.radiusCap);
    expect(dark.compactMinimumHeight, light.compactMinimumHeight);
    expect(dark.compactPadding, light.compactPadding);
    expect(dark.expandedPadding, light.expandedPadding);
    expect(dark.titleTextStyle, light.titleTextStyle);
    expect(dark.messageTextStyle, light.messageTextStyle);
  });

  test('the new highlight fields survive copyWith and merge', () {
    final CapsuleToastThemeData base = CapsuleToastThemeData.fallback(
      Brightness.dark,
    );
    expect(
      base
          .copyWith(innerHighlightColor: const Color(0xFF00FF00))
          .innerHighlightColor,
      const Color(0xFF00FF00),
    );
    expect(
      base
          .merge(CapsuleToastThemeData(innerHighlightWidth: 2))
          .innerHighlightWidth,
      2,
    );
    expect(base.copyWith().innerHighlightColor, const Color(0x1AFFFFFF));
  });

  group('resolution follows the host application brightness', () {
    Future<CapsuleToastThemeData> resolveUnder(
      WidgetTester tester,
      ThemeData theme,
    ) async {
      late CapsuleToastThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (BuildContext context) {
              resolved = CapsuleToastTheme.resolve(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return resolved;
    }

    testWidgets('a dark app gets the dark base', (WidgetTester tester) async {
      final CapsuleToastThemeData resolved = await resolveUnder(
        tester,
        ThemeData(brightness: Brightness.dark),
      );
      expect(resolved.surfaceColor, const Color(0xFF26231E));
      expect(resolved.borderColor, const Color(0x26F9F6F0));
      expect(resolved.innerHighlightColor, const Color(0x1AFFFFFF));
      expect(resolved.tints!.success, const Color(0x3795A584));
    });

    testWidgets('a light app gets the light base', (WidgetTester tester) async {
      final CapsuleToastThemeData resolved = await resolveUnder(
        tester,
        ThemeData(brightness: Brightness.light),
      );
      expect(resolved.surfaceColor, const Color(0xFF161614));
      expect(resolved.innerHighlightColor, isNull);
    });

    testWidgets('an extension still overrides the dark base', (
      WidgetTester tester,
    ) async {
      const Color custom = Color(0xFF102030);
      final CapsuleToastThemeData resolved = await resolveUnder(
        tester,
        ThemeData(
          brightness: Brightness.dark,
          extensions: <ThemeExtension<dynamic>>[
            CapsuleToastThemeData(surfaceColor: custom),
          ],
        ),
      );
      // The override wins, and everything it did not state still comes from
      // the dark base rather than reverting to light.
      expect(resolved.surfaceColor, custom);
      expect(resolved.foregroundColor, const Color(0xFFF7F4EE));
      expect(resolved.innerHighlightColor, const Color(0x1AFFFFFF));
    });

    testWidgets('a full fallback extension pins the appearance', (
      WidgetTester tester,
    ) async {
      final CapsuleToastThemeData resolved = await resolveUnder(
        tester,
        ThemeData(
          brightness: Brightness.dark,
          extensions: <ThemeExtension<dynamic>>[
            CapsuleToastThemeData.fallback(Brightness.light),
          ],
        ),
      );
      expect(resolved.surfaceColor, const Color(0xFF161614));
      expect(resolved.foregroundColor, const Color(0xFFF9F9F7));
      expect(resolved.tints!.success, const Color(0x2995A584));
    });

    testWidgets('a nested CapsuleToastTheme still wins over both', (
      WidgetTester tester,
    ) async {
      const Color local = Color(0xFF405060);
      late CapsuleToastThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: CapsuleToastTheme(
            data: CapsuleToastThemeData(surfaceColor: local),
            child: Builder(
              builder: (BuildContext context) {
                resolved = CapsuleToastTheme.resolve(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(resolved.surfaceColor, local);
      expect(resolved.foregroundColor, const Color(0xFFF7F4EE));
    });
  });
}
