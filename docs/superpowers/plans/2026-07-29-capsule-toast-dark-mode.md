# Capsule Toast Dark Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `capsule_toast` a second appearance so that a host app in dark mode gets the reference's dark capsule automatically, with every token customisable.

**Architecture:** The brightness-varying tokens move into a private `_CapsuleToastPalette` with `light` and `dark` constants, consumed by a single `CapsuleToastThemeData.fallback([Brightness])` factory. `CapsuleToastTheme.resolve` reads `Theme.of(context).brightness` to choose the base, then merges the `ThemeData` extension and the inherited theme exactly as it does today. The dark rim's inset top highlight — which `BoxDecoration` cannot express — is painted by a `CustomPaint` that is only built when the token is non-null.

**Tech Stack:** Flutter (>=3.44.0), Dart (^3.12.2), `flutter_test`, no new dependencies.

## Global Constraints

- Every colour is transcribed from the cloud design project `1c722c25-a682-455b-9fa8-d06d729fdac7`, files `toast-capsule.jsx` (`CAPSULE_LIGHT` / `CAPSULE_DARK` / `TONES`) and `toast-lab.jsx` (`ModeSpecTable`). Invent no colours.
- Alpha conversion: CSS fractional alpha × 255, rounded to nearest.
- Blur conversion: CSS blur `B` → Flutter `blurRadius = (B / 2 - 0.5) / 0.57735`.
- Motion, geometry, layout, typography, spacing and the queue are **identical** between appearances. Do not touch `capsule_toast_motion_theme.dart`, `CapsuleToastTheme.resolveMotion`, or anything under `lib/src/motion/`.
- `CapsuleToastAccents` is **identical** between appearances — `TONES[*].fg` does not vary with appearance in the reference. Only tint alpha does.
- `CapsuleToastThemeData.fallback()` called with no argument must stay byte-identical in behaviour to today. Existing call sites must not need edits.
- Copyright header on every new file: `// Copyright 2026 The Capsule Toast Authors. All rights reserved.`
- Follow the existing file style: explicit types on locals (`final CapsuleToastThemeData theme = ...`), `<Widget>[]` style generic literals, dartdoc on every public member.
- Run `dart analyze` before every commit; it must be clean.

## File Structure

| File | Responsibility | Task |
|---|---|---|
| `lib/src/theme/capsule_toast_theme_data.dart` | Add `_CapsuleToastPalette` (private, directly above `CapsuleToastThemeData`), the two new public fields, and the `Brightness` parameter on `fallback`. Kept in this file because the palette is an implementation detail of one factory and would have to become public-in-`src` to move out. | 1 |
| `lib/src/theme/capsule_toast_theme.dart` | `resolve` reads ambient brightness to choose its base. | 2 |
| `lib/src/widgets/capsule_toast_surface.dart` | `capsuleHighlightKey` and `_CapsuleInnerHighlightPainter`; conditional `CustomPaint`. | 3 |
| `test/support/test_app.dart` | `brightness` parameter on `pumpToast`, `pumpToastHarness`, `pumpGoldenGrid`; re-export `capsuleHighlightKey`; dark golden canvas colour. | 3, 4 |
| `test/theme/capsule_toast_dark_mode_test.dart` | New. Token table, shared accents, ×1.35 rule, back-compat, resolution, override, pinning. | 1, 2 |
| `test/widgets/capsule_toast_dark_mode_test.dart` | New. Painted chrome and highlight presence. | 3 |
| `test/widgets/capsule_toast_golden_test.dart` | One new dark golden case. | 4 |
| `example/lib/lab/lab_tokens.dart` | Dark app-surface tokens from `theme-dark.js`. | 5 |
| `example/lib/lab/lab_phone.dart` | `dark` flag on the frame, screen and dock. | 5 |
| `example/lib/lab/lab_panel.dart` | `brightness` on `LabSpecimen`. | 5 |
| `example/lib/lab/lab_specimens.dart` | `brightness` threaded to `fallback`. | 5 |
| `example/lib/capsule_toast_lab.dart` | Appearance state, the Light app / Dark app picker, `Theme` around the phone. | 5 |
| `README.md`, `CHANGELOG.md`, `pubspec.yaml` | Docs and 0.4.0. | 6 |

---

### Task 1: Dark palette and the brightness-aware fallback

**Files:**
- Modify: `lib/src/theme/capsule_toast_theme_data.dart`
- Test: `test/theme/capsule_toast_dark_mode_test.dart` (create)

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `factory CapsuleToastThemeData.fallback([Brightness brightness = Brightness.light])`
  - `final Color? innerHighlightColor` on `CapsuleToastThemeData`
  - `final double? innerHighlightWidth` on `CapsuleToastThemeData`
  - both fields as named parameters on the default constructor, `copyWith`, and `merge`

- [ ] **Step 1: Write the failing test**

Create `test/theme/capsule_toast_dark_mode_test.dart`:

```dart
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
    // Guards the rule, not just the transcribed hex values.
    final CapsuleToastTints light = CapsuleToastThemeData.fallback(
      Brightness.light,
    ).tints!;
    final CapsuleToastTints dark = CapsuleToastThemeData.fallback(
      Brightness.dark,
    ).tints!;
    for (final CapsuleToastType type in CapsuleToastType.values) {
      expect(
        _alpha(dark.colorFor(type)),
        closeTo(_alpha(light.colorFor(type)) * 1.35, 0.004),
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
      base.copyWith(innerHighlightColor: const Color(0xFF00FF00))
          .innerHighlightColor,
      const Color(0xFF00FF00),
    );
    expect(
      base.merge(CapsuleToastThemeData(innerHighlightWidth: 2)).innerHighlightWidth,
      2,
    );
    expect(base.copyWith().innerHighlightColor, const Color(0x1AFFFFFF));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/theme/capsule_toast_dark_mode_test.dart`
Expected: FAIL — compile error, `fallback` takes no positional argument and `innerHighlightColor` is not defined.

- [ ] **Step 3: Add the palette**

In `lib/src/theme/capsule_toast_theme_data.dart`, insert this immediately **above** `/// Visual styling tokens for capsule toasts.` (the `CapsuleToastThemeData` doc comment), i.e. after `CapsuleToastTints`:

```dart
/// The capsule tokens that vary with the host application's brightness.
///
/// The reference prototype keeps geometry, typography, springs and status
/// accents shared between appearances, and moves only the surface, its rim, its
/// shadow, and the alpha of the status tints. Those are the values collected
/// here, so the two appearances are two short tables rather than two copies of
/// the whole fallback.
@immutable
class _CapsuleToastPalette {
  const _CapsuleToastPalette({
    required this.surface,
    required this.foreground,
    required this.secondaryForeground,
    required this.border,
    required this.actionSurface,
    required this.onForeground,
    required this.tints,
    required this.shadows,
    this.innerHighlight,
    this.innerHighlightWidth,
  });

  /// Tuned for a light application: a near-black system overlay at maximum
  /// contrast against the warm off-white app surface.
  static const _CapsuleToastPalette light = _CapsuleToastPalette(
    surface: Color(0xFF161614),
    foreground: Color(0xFFF9F9F7),
    secondaryForeground: Color(0x9EF9F9F7),
    border: Color(0x12F9F9F7),
    actionSurface: Color(0x1AF9F9F7),
    onForeground: Color(0xFF1A1714),
    tints: CapsuleToastTints(
      success: Color(0x2995A584),
      information: Color(0x298AA4BD),
      warning: Color(0x29D89858),
      error: Color(0x2ED67D65),
      loading: Color(0x14F9F9F7),
      neutral: Color(0x14F9F9F7),
      custom: Color(0x14F9F9F7),
    ),
    // The reference casts `0 2px 6px` and `0 10px 30px`. CSS defines its
    // blur radius as twice the Gaussian sigma, while Flutter's is
    // `0.57735 * radius + 0.5`, so copying the CSS numbers across
    // over-blurs by roughly a third. These are the radii that land on the
    // same sigma.
    shadows: <BoxShadow>[
      BoxShadow(offset: Offset(0, 2), blurRadius: 4.33, color: _shadowColor),
      BoxShadow(offset: Offset(0, 10), blurRadius: 25.1, color: _shadowColor),
    ],
  );

  /// Tuned for a dark application. Near-black would sink into the background,
  /// so this lifts one step *above* the app surface, trades the warm ambient
  /// shadow for a brighter rim plus an inner top highlight, and boosts tint
  /// alpha by 1.35 so status reads at the same strength on the lighter fill.
  static const _CapsuleToastPalette dark = _CapsuleToastPalette(
    surface: Color(0xFF26231E),
    foreground: Color(0xFFF7F4EE),
    secondaryForeground: Color(0xA8F7F4EE),
    border: Color(0x26F9F6F0),
    actionSurface: Color(0x21F9F6F0),
    onForeground: Color(0xFF211E19),
    innerHighlight: Color(0x1AFFFFFF),
    innerHighlightWidth: 0.5,
    tints: CapsuleToastTints(
      success: Color(0x3795A584),
      information: Color(0x378AA4BD),
      warning: Color(0x37D89858),
      error: Color(0x3ED67D65),
      loading: Color(0x1CF9F9F7),
      neutral: Color(0x1CF9F9F7),
      custom: Color(0x1CF9F9F7),
    ),
    // `0 2px 8px rgba(0,0,0,0.46)` and `0 14px 36px rgba(0,0,0,0.42)`, through
    // the same CSS-blur-to-sigma conversion as the light palette.
    shadows: <BoxShadow>[
      BoxShadow(offset: Offset(0, 2), blurRadius: 6.06, color: Color(0x75000000)),
      BoxShadow(
        offset: Offset(0, 14),
        blurRadius: 30.31,
        color: Color(0x6B000000),
      ),
    ],
  );

  static const Color _shadowColor = Color.fromRGBO(20, 14, 6, 0.16);

  /// Returns the palette for a host application of the given [brightness].
  static _CapsuleToastPalette of(Brightness brightness) {
    return switch (brightness) {
      Brightness.light => light,
      Brightness.dark => dark,
    };
  }

  /// Capsule surface fill.
  final Color surface;

  /// Primary content colour.
  final Color foreground;

  /// Secondary content colour.
  final Color secondaryForeground;

  /// Rim stroke colour.
  final Color border;

  /// Action chip surface.
  final Color actionSurface;

  /// Content colour on top of a [foreground] fill.
  final Color onForeground;

  /// Inner top rim highlight, or `null` when the appearance has none.
  final Color? innerHighlight;

  /// Thickness of the inner top rim highlight.
  final double? innerHighlightWidth;

  /// Semantic surface tints, already carrying this appearance's tint boost.
  final CapsuleToastTints tints;

  /// Drop shadows behind the capsule.
  final List<BoxShadow> shadows;
}
```

- [ ] **Step 4: Rewrite the fallback factory over the palette**

In `CapsuleToastThemeData`, delete the now-duplicated `static const Color _shadowColor = Color.fromRGBO(20, 14, 6, 0.16);` (it moved to `_CapsuleToastPalette`) and replace the whole `factory CapsuleToastThemeData.fallback()` with:

```dart
  /// Reference visual values for capsule toasts.
  ///
  /// [brightness] is the *host application's* brightness, matching
  /// `Theme.of(context).brightness`. `Brightness.light` returns the near-black
  /// capsule tuned to sit on a light app; `Brightness.dark` returns the lifted
  /// capsule tuned to sit on a dark one. Geometry, typography, motion and
  /// status accents are identical either way.
  ///
  /// Because the returned theme is fully populated, installing one as a
  /// `ThemeData` extension pins that appearance regardless of the app:
  ///
  /// ```dart
  /// ThemeData.dark().copyWith(
  ///   extensions: <ThemeExtension<dynamic>>[
  ///     CapsuleToastThemeData.fallback(Brightness.light),
  ///   ],
  /// )
  /// ```
  factory CapsuleToastThemeData.fallback([
    Brightness brightness = Brightness.light,
  ]) {
    final _CapsuleToastPalette palette = _CapsuleToastPalette.of(brightness);
    return CapsuleToastThemeData(
      surfaceColor: palette.surface,
      foregroundColor: palette.foreground,
      secondaryForegroundColor: palette.secondaryForeground,
      borderColor: palette.border,
      borderWidth: 0.5,
      actionSurfaceColor: palette.actionSurface,
      innerHighlightColor: palette.innerHighlight,
      innerHighlightWidth: palette.innerHighlightWidth,
      accents: const CapsuleToastAccents(
        success: Color(0xFFB9CCA8),
        information: Color(0xFFAFC4D7),
        warning: Color(0xFFE5BE85),
        error: Color(0xFFE8A695),
        loading: Color(0xC7F9F9F7),
        neutral: Color(0xC7F9F9F7),
        custom: Color(0xC7F9F9F7),
      ),
      tints: palette.tints,
      shadows: palette.shadows,
      titleTextStyle: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
      ),
      expandedTitleTextStyle: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
      ),
      messageTextStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: -0.05,
      ),
      actionTextStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      compactPadding: const EdgeInsetsDirectional.fromSTEB(5, 5, 14, 5),
      expandedPadding: const EdgeInsetsDirectional.fromSTEB(14, 14, 16, 14),
      compactSpacing: 10,
      expandedSpacing: 12,
      messageSpacing: 3,
      actionSpacing: 8,
      actionTopSpacing: 9,
      seedSize: const Size(84, 34),
      compactMinimumHeight: 44,
      maximumWidth: 340,
      horizontalInset: 16,
      radiusCap: 34,
      compactIconSize: 34,
      expandedIconSize: 34,
      compactTitleMaximumWidth: 210,
      compactActionHeight: 24,
      expandedActionHeight: 30,
      compactActionPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
      ),
      primaryActionPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
      ),
      secondaryActionPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
      ),
      // The compact chip reads as a quiet affordance, the expanded primary as
      // a solid pill in the content colour, and the secondary as bare text.
      // The colour has to be stated here, not left to the ambient text style:
      // toast content inherits the host app's `bodyMedium`, which in a light
      // theme is near-black and disappears against the capsule.
      compactActionStyle: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll<Color>(palette.foreground),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: palette.foreground,
          ),
        ),
      ),
      primaryActionStyle: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(palette.foreground),
        foregroundColor: WidgetStatePropertyAll<Color>(palette.onForeground),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            color: palette.onForeground,
          ),
        ),
      ),
      secondaryActionStyle: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll<Color>(Color(0x00000000)),
        foregroundColor: WidgetStatePropertyAll<Color>(
          palette.secondaryForeground,
        ),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            color: palette.secondaryForeground,
          ),
        ),
      ),
      useSafeArea: true,
      verticalOffset: 15,
    );
  }
```

- [ ] **Step 5: Add the two new fields**

Five edits inside `CapsuleToastThemeData`, all in `lib/src/theme/capsule_toast_theme_data.dart`.

a) Default constructor — add after `this.actionSurfaceColor,`:

```dart
    this.innerHighlightColor,
    this.innerHighlightWidth,
```

and add to the assertion list, after the `borderWidth` assert:

```dart
       assert(innerHighlightWidth == null || innerHighlightWidth >= 0),
```

b) Field declarations — add after the `actionSurfaceColor` field:

```dart
  /// Inner rim highlight painted along the capsule's top curve.
  ///
  /// The reference dark appearance lifts the capsule above the app surface with
  /// `inset 0 0.5px 0 rgba(255,255,255,0.10)`. [BoxDecoration] has no inset
  /// shadow, so the surface paints this itself. Leave `null` for no highlight —
  /// which is what the light appearance does.
  final Color? innerHighlightColor;

  /// Thickness of the inner rim highlight.
  ///
  /// Falls back to [borderWidth] when null and [innerHighlightColor] is set.
  final double? innerHighlightWidth;
```

c) `copyWith` — parameter after `Color? actionSurfaceColor,`:

```dart
    Color? innerHighlightColor,
    double? innerHighlightWidth,
```

and body entry after the `actionSurfaceColor` line:

```dart
      innerHighlightColor: innerHighlightColor ?? this.innerHighlightColor,
      innerHighlightWidth: innerHighlightWidth ?? this.innerHighlightWidth,
```

d) `merge` — after the `actionSurfaceColor` line:

```dart
      innerHighlightColor: other.innerHighlightColor ?? innerHighlightColor,
      innerHighlightWidth: other.innerHighlightWidth ?? innerHighlightWidth,
```

e) `lerp` — after the `actionSurfaceColor` entry:

```dart
      innerHighlightColor: Color.lerp(
        innerHighlightColor,
        other.innerHighlightColor,
        t,
      ),
      innerHighlightWidth: lerpDouble(
        innerHighlightWidth,
        other.innerHighlightWidth,
        t,
      ),
```

- [ ] **Step 6: Add the fields to diagnostics, equality and hash**

Same file, three more edits.

`debugFillProperties`, after the `actionSurfaceColor` line:

```dart
    properties.add(ColorProperty('innerHighlightColor', innerHighlightColor));
    properties.add(DoubleProperty('innerHighlightWidth', innerHighlightWidth));
```

`operator ==`, after `other.actionSurfaceColor == actionSurfaceColor &&`:

```dart
        other.innerHighlightColor == innerHighlightColor &&
        other.innerHighlightWidth == innerHighlightWidth &&
```

`hashCode`, after `actionSurfaceColor,`:

```dart
    innerHighlightColor,
    innerHighlightWidth,
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `flutter test test/theme/capsule_toast_dark_mode_test.dart`
Expected: PASS, all cases.

- [ ] **Step 8: Run the full suite and the analyzer**

Run: `dart analyze && flutter test`
Expected: analyzer clean; every existing test still passes. `fallback()` is unchanged for callers, so no existing test should need edits. If a golden fails here, stop — something in the light palette drifted during the refactor.

- [ ] **Step 9: Commit**

```bash
git add lib/src/theme/capsule_toast_theme_data.dart test/theme/capsule_toast_dark_mode_test.dart
git commit -m "feat: add the reference dark capsule palette

Splits the brightness-varying tokens into a private palette so the two
appearances are two tables rather than two copies of the fallback, and adds
innerHighlightColor/innerHighlightWidth for the dark rim's inset top
highlight. fallback() with no argument is unchanged."
```

---

### Task 2: Ambient brightness selects the base

**Files:**
- Modify: `lib/src/theme/capsule_toast_theme.dart:42-55`
- Test: `test/theme/capsule_toast_dark_mode_test.dart` (append)

**Interfaces:**
- Consumes: `CapsuleToastThemeData.fallback([Brightness])` from Task 1.
- Produces: `CapsuleToastTheme.resolve(context)` returning a dark-based theme under a dark `Theme`. Signature unchanged.

- [ ] **Step 1: Write the failing test**

Append inside `main()` in `test/theme/capsule_toast_dark_mode_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/theme/capsule_toast_dark_mode_test.dart --plain-name 'resolution follows'`
Expected: FAIL — "a dark app gets the dark base" reports `Color(0xFF161614)`, because `resolve` still hardcodes the light fallback.

- [ ] **Step 3: Read the brightness in resolve**

In `lib/src/theme/capsule_toast_theme.dart`, replace the body of `resolve` (currently lines 42-55) with:

```dart
  /// Resolves visual theme from defaults, extensions, and inherited scope.
  ///
  /// The base is chosen from the host application's brightness, so a
  /// `MaterialApp` with both `theme:` and `darkTheme:` gets the matching
  /// capsule appearance with no package-specific configuration. Overrides are
  /// then merged over that base in the usual order: `ThemeData` extension
  /// first, nearest [CapsuleToastTheme] last.
  static CapsuleToastThemeData resolve(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    CapsuleToastThemeData resolved = CapsuleToastThemeData.fallback(
      theme.brightness,
    );
    final CapsuleToastThemeData? extension = theme
        .extension<CapsuleToastThemeData>();
    if (extension != null) {
      resolved = resolved.merge(extension);
    }
    final CapsuleToastThemeData? inherited = maybeOf(context);
    if (inherited != null) {
      resolved = resolved.merge(inherited);
    }
    return resolved;
  }
```

Do **not** touch `resolveMotion` — springs are appearance-agnostic.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/theme/capsule_toast_dark_mode_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the full suite and the analyzer**

Run: `dart analyze && flutter test`
Expected: clean and green. Existing tests pump light themes, so nothing should change for them.

- [ ] **Step 6: Commit**

```bash
git add lib/src/theme/capsule_toast_theme.dart test/theme/capsule_toast_dark_mode_test.dart
git commit -m "feat: pick the capsule appearance from the app brightness

CapsuleToastTheme.resolve now bases its result on Theme.of(context).brightness.
The merge order is unchanged, so a fully populated fallback installed as a
ThemeData extension pins an appearance regardless of the app."
```

---

### Task 3: Paint the inner top highlight

**Files:**
- Modify: `lib/src/widgets/capsule_toast_surface.dart`
- Modify: `test/support/test_app.dart`
- Test: `test/widgets/capsule_toast_dark_mode_test.dart` (create)

**Interfaces:**
- Consumes: `innerHighlightColor` / `innerHighlightWidth` from Task 1; brightness-aware `resolve` from Task 2.
- Produces:
  - `const Key capsuleHighlightKey = ValueKey<String>('capsule_toast.highlight')` in `lib/src/widgets/capsule_toast_surface.dart`, re-exported from `test/support/test_app.dart`
  - `Brightness brightness` named parameter (default `Brightness.light`) on `pumpToast` and `pumpToastHarness` in `test/support/test_app.dart`

- [ ] **Step 1: Add the brightness parameter to the test harness**

In `test/support/test_app.dart`:

a) Extend the existing surface re-export:

```dart
export 'package:capsule_toast/src/widgets/capsule_toast_surface.dart'
    show capsuleHighlightKey, capsuleSurfaceKey;
```

b) Add a parameter to `pumpToast` (after `bool settle = true,`):

```dart
  Brightness brightness = Brightness.light,
```

and give the `MaterialApp` a theme — replace `MaterialApp(` with:

```dart
    MaterialApp(
      theme: ThemeData(brightness: brightness),
```

c) Add the same parameter to `pumpToastHarness` and forward it in its `pumpToast` call:

```dart
  Brightness brightness = Brightness.light,
```

```dart
    brightness: brightness,
```

- [ ] **Step 2: Write the failing test**

Create `test/widgets/capsule_toast_dark_mode_test.dart`:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

/// Key of the painted capsule chrome inside `CapsuleToastSurface`.
const Key decorationKey = ValueKey<String>('capsule_toast.decoration');

BoxDecoration _paintedDecoration(WidgetTester tester) {
  final DecoratedBox box = tester.widget(
    find.byKey(decorationKey).first,
  );
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
    expect(
      (decoration.border! as Border).top.color,
      const Color(0x26F9F6F0),
    );
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
    expect(
      (decoration.border! as Border).top.color,
      const Color(0x12F9F9F7),
    );
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
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/widgets/capsule_toast_dark_mode_test.dart`
Expected: FAIL — `capsuleHighlightKey` is undefined.

- [ ] **Step 4: Add the key and the painter**

In `lib/src/widgets/capsule_toast_surface.dart`, add below the existing `capsuleSurfaceKey` declaration:

```dart
/// Key identifying the inner rim highlight painted on the capsule surface.
const Key capsuleHighlightKey = ValueKey<String>('capsule_toast.highlight');
```

and append this painter at the end of the file:

```dart
/// Paints the reference's `inset 0 Npx 0` rim highlight along the top curve.
///
/// [BoxDecoration] has no inset shadow. For an inset shadow with a vertical
/// offset and no blur or spread, the lit region is the padding-box shape minus
/// that same shape shifted down by the offset — a sliver that follows the top
/// curve and tapers to nothing at the sides. Painting that difference gives the
/// CSS geometry itself rather than a gradient standing in for it.
class _CapsuleInnerHighlightPainter extends CustomPainter {
  const _CapsuleInnerHighlightPainter({
    required this.color,
    required this.width,
    required this.borderWidth,
    required this.radius,
  });

  /// Highlight colour, including its alpha.
  final Color color;

  /// Vertical offset of the inset shadow, and so the sliver's thickness.
  final double width;

  /// Border thickness the highlight sits inside of.
  final double borderWidth;

  /// Outer corner radius of the capsule.
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0 || color.a == 0) {
      return;
    }
    // The reference draws the highlight inside the border rather than on top
    // of it, so the shape is the padding box, not the border box.
    final Rect bounds = (Offset.zero & size).deflate(borderWidth);
    if (bounds.isEmpty) {
      return;
    }
    final RRect inner = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(math.max(0, radius - borderWidth)),
    );
    final Path sliver = Path.combine(
      PathOperation.difference,
      Path()..addRRect(inner),
      Path()..addRRect(inner.shift(Offset(0, width))),
    );
    canvas.drawPath(sliver, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CapsuleInnerHighlightPainter oldDelegate) {
    return color != oldDelegate.color ||
        width != oldDelegate.width ||
        borderWidth != oldDelegate.borderWidth ||
        radius != oldDelegate.radius;
  }
}
```

- [ ] **Step 5: Insert the conditional CustomPaint**

In `_CapsuleToastSurfaceBodyState.build`, replace the closing `return DecoratedBox(...)` block with:

```dart
    Widget clipped = ClipRRect(borderRadius: borderRadius, child: content);
    if (widget.theme.innerHighlightColor case final Color highlight) {
      // Built only when the appearance asks for it, so the light capsule pays
      // nothing for a rim it does not have.
      clipped = CustomPaint(
        key: capsuleHighlightKey,
        foregroundPainter: _CapsuleInnerHighlightPainter(
          color: highlight,
          width: widget.theme.innerHighlightWidth ?? widget.theme.borderWidth!,
          borderWidth: widget.theme.borderWidth!,
          radius: radius,
        ),
        child: clipped,
      );
    }

    // Fill, hairline and shadow belong to the capsule, so they are painted on
    // this box and the clip goes inside them. Clipping the decoration instead
    // would pin the visible pill to the content's size — it would snap to the
    // collapsed shape the instant the mode changed while only an invisible
    // window animated, and the shadow would be clipped away entirely.
    return DecoratedBox(
      key: const ValueKey<String>('capsule_toast.decoration'),
      decoration: BoxDecoration(
        color: widget.theme.surfaceColor,
        border: Border.all(
          color: widget.theme.borderColor!,
          width: widget.theme.borderWidth!,
        ),
        borderRadius: borderRadius,
        boxShadow: widget.theme.shadows,
      ),
      child: clipped,
    );
```

`dart:math` is already imported as `math` at the top of this file; no new imports are needed.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/widgets/capsule_toast_dark_mode_test.dart`
Expected: PASS, all four cases.

- [ ] **Step 7: Run the full suite and the analyzer**

Run: `dart analyze && flutter test`
Expected: clean and green. The existing light goldens must still pass — the `CustomPaint` is not built in light mode, so pixels are untouched.

- [ ] **Step 8: Commit**

```bash
git add lib/src/widgets/capsule_toast_surface.dart test/support/test_app.dart test/widgets/capsule_toast_dark_mode_test.dart
git commit -m "feat: paint the dark capsule's inner rim highlight

Reproduces the reference's inset top highlight as the difference between the
padding-box shape and itself shifted down, which is the geometry CSS computes
for a zero-blur inset shadow. Built only when the token is set."
```

---

### Task 4: Dark golden

**Files:**
- Modify: `test/support/test_app.dart`
- Modify: `test/widgets/capsule_toast_golden_test.dart`
- Create: `test/goldens/capsule_toast_dark_states.png` (generated)

**Interfaces:**
- Consumes: everything from Tasks 1–3.
- Produces: `Brightness brightness` named parameter (default `Brightness.light`) on `pumpGoldenGrid`, and `const Color goldenDarkCanvasColor`.

- [ ] **Step 1: Thread brightness through the golden harness**

In `test/support/test_app.dart`:

a) Add next to `goldenCanvasColor`:

```dart
/// Reference dark application background behind dark golden boards.
const Color goldenDarkCanvasColor = Color(0xFF20201E);
```

b) Add a parameter to `pumpGoldenGrid` (after `Size? seedClipSize,`):

```dart
  Brightness brightness = Brightness.light,
```

c) At the top of the `pumpGoldenGrid` body, after `configureGoldenSurface(tester);`:

```dart
  final Color canvas = brightness == Brightness.dark
      ? goldenDarkCanvasColor
      : goldenCanvasColor;
```

d) In the pumped tree, set the theme brightness and use `canvas` for **both** `ColoredBox` colours:

```dart
      theme: ThemeData(
        fontFamily: 'FlutterTest',
        brightness: brightness,
        useMaterial3: true,
      ),
```

```dart
            child: ColoredBox(
              color: canvas,
```

```dart
                  child: ColoredBox(
                    color: canvas,
```

e) `_GoldenToastBoard` builds its own theme rather than calling `resolve`, so pass the brightness down. Add a field to `_GoldenToastBoard`:

```dart
  final Brightness brightness;
```

with the constructor parameter `this.brightness = Brightness.light,`, pass `brightness: brightness` at the `_GoldenToastBoard(` call site in `pumpGoldenGrid`, and in `_GoldenToastBoardState.build` replace:

```dart
    final CapsuleToastThemeData visualTheme = CapsuleToastThemeData.fallback();
```

with:

```dart
    final CapsuleToastThemeData visualTheme = CapsuleToastThemeData.fallback(
      widget.brightness,
    );
```

- [ ] **Step 2: Write the failing golden test**

Append to `main()` in `test/widgets/capsule_toast_golden_test.dart`:

```dart
  testWidgets('dark semantic states match the reference', (
    WidgetTester tester,
  ) async {
    await pumpGoldenGrid(
      tester,
      <CapsuleToastData>[
        CapsuleToastData.success(title: 'Saved'),
        CapsuleToastData.information(title: 'New information'),
        CapsuleToastData.warning(title: 'Connection unstable'),
        CapsuleToastData.error(title: 'Upload failed'),
        CapsuleToastData.loading(title: 'Uploading'),
        CapsuleToastData.neutral(title: 'Draft available'),
      ],
      brightness: Brightness.dark,
    );

    await expectLater(
      find.byKey(goldenBoundaryKey),
      matchesGoldenFile('goldens/capsule_toast_dark_states.png'),
    );
  });
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/widgets/capsule_toast_golden_test.dart --plain-name 'dark semantic states'`
Expected: FAIL — "Could not be compared against non-existent file … capsule_toast_dark_states.png".

- [ ] **Step 4: Generate the golden**

Run: `flutter test test/widgets/capsule_toast_golden_test.dart --update-goldens`

Then **look at** `test/goldens/capsule_toast_dark_states.png` with the Read tool and check it against the spec before accepting it: the capsule fill should be visibly lighter than the `#20201E` canvas (not darker), the rim should be legible, and the status tint discs should read at the same strength as in `capsule_toast_compact_states.png`. If the capsule looks darker than the background, the palette selection is wrong — stop and fix rather than baking in a bad golden.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/widgets/capsule_toast_golden_test.dart`
Expected: PASS. The comparator is zero-tolerance, so the five existing goldens passing also confirms light mode is untouched.

- [ ] **Step 6: Run the full suite and the analyzer**

Run: `dart analyze && flutter test`
Expected: clean and green.

- [ ] **Step 7: Commit**

```bash
git add test/support/test_app.dart test/widgets/capsule_toast_golden_test.dart test/goldens/capsule_toast_dark_states.png
git commit -m "test: pin the dark capsule with a golden

Threads brightness through the golden harness and captures the six compact
semantic states on the reference dark app background."
```

---

### Task 5: Light / dark toggle in the example lab

**Files:**
- Modify: `example/lib/lab/lab_tokens.dart`
- Modify: `example/lib/lab/lab_phone.dart`
- Modify: `example/lib/lab/lab_panel.dart`
- Modify: `example/lib/lab/lab_specimens.dart`
- Modify: `example/lib/capsule_toast_lab.dart`

**Interfaces:**
- Consumes: `CapsuleToastThemeData.fallback([Brightness])`, brightness-aware `resolve`.
- Produces: nothing the package depends on. Example-only.

The reference lab keeps its chrome in the light palette whichever appearance the phone is previewing (`toast-lab.jsx`: "Lab chrome always renders in the light palette so it stays a neutral frame around the phone"). Preserve that: only the phone and the frozen specimens follow the toggle.

- [ ] **Step 1: Add the dark app-surface tokens**

In `example/lib/lab/lab_tokens.dart`, add to `Lab` after the existing `// ── Surfaces ──` block. Values are from `theme-dark.js`.

```dart
  // ── Dark app surfaces ──
  // From the reference dark token sheet. These dress the phone canvas only;
  // the lab chrome around it stays light on purpose.

  /// Neutral charcoal app background.
  static const Color darkBg = Color(0xFF20201E);

  /// Raised card / row fill.
  static const Color darkCard = Color(0xFF2C2C2A);

  /// Hairline stroke, `rgba(249,249,247,0.10)`.
  static const Color darkHairline = Color(0x1AF9F9F7);

  /// Primary text on charcoal.
  static const Color darkInk = Color(0xFFF9F9F7);

  /// Muted body text on charcoal.
  static const Color darkMuted = Color(0xFF9A9A94);
```

- [ ] **Step 2: Give the phone a dark variant**

In `example/lib/lab/lab_phone.dart`:

a) `LabPhoneFrame` — add `final bool dark;` with `this.dark = false,` in the constructor, and swap the shell fill:

```dart
        color: dark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
```

Also make the status bar and home indicator legible on dark — wrap the status-bar `DefaultTextStyle` style with `color: dark ? Lab.darkInk : Lab.ink` via `Lab.font(size: 17, weight: FontWeight.w600, height: 22 / 17, color: dark ? Lab.darkInk : Lab.ink)`, and set the home indicator colour to `dark ? const Color(0x59FFFFFF) : const Color(0x40000000)`.

b) `LabPhoneScreen` — add `final bool dark;` with `this.dark = false,`, then swap the four token reads:

```dart
    return ColoredBox(
      color: dark ? Lab.darkBg : Lab.bg,
```

```dart
              style: Lab.font(
                size: 30,
                weight: FontWeight.w600,
                letterSpacing: -1,
                color: dark ? Lab.darkInk : Lab.ink,
              ),
```

```dart
                  decoration: BoxDecoration(
                    color: dark ? Lab.darkCard : Lab.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: dark ? Lab.darkHairline : Lab.hairline,
                    ),
                  ),
```

```dart
                        style: Lab.font(
                          size: 14,
                          weight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: dark ? Lab.darkInk : Lab.ink,
                        ),
```

```dart
                        style: Lab.font(
                          size: 12,
                          color: dark ? Lab.darkMuted : Lab.muted,
                        ),
                      ),
```

c) `LabDemoDock` — add `final bool dark;` with `this.dark = false,`. From `DemoDock` in `toast-lab.jsx`, the dark dock uses surface `rgba(44,40,34,0.92)`, rim `rgba(249,246,240,0.14)`, chip `rgba(249,246,240,0.13)` and shadow `0 10px 30px rgba(0,0,0,0.5)`. Add these constants beside the existing `_chip` / `_fg`:

```dart
  static const Color _darkChip = Color(0x21F9F6F0);
  static const Color _darkPanel = Color(0xEB2C2822);
  static const Color _darkRim = Color(0x24F9F6F0);
  static const Color _darkShadow = Color(0x80000000);
```

Then in `_buildPanel`, use `dark ? _darkPanel : const Color(0xEB161614)` for the fill, `dark ? _darkRim : const Color(0x14F9F9F7)` for the border, and `dark ? _darkShadow : const Color(0x3D140E06)` for the shadow colour. In `_dockChip`, use `dark ? _darkChip : _chip`. In `_buildCollapsed`, use `dark ? _darkPanel : const Color(0xE6161614)` and `dark ? _darkRim : const Color(0x14F9F9F7)`.

`_buildPanel`, `_buildCollapsed` and `_dockChip` are private instance methods, so they can read `dark` directly — no new parameters.

- [ ] **Step 3: Give the frozen specimens a brightness**

In `example/lib/lab/lab_panel.dart`, `LabSpecimen`: add `final Brightness brightness;` with `this.brightness = Brightness.light,` in the constructor, then replace:

```dart
    final CapsuleToastThemeData theme = CapsuleToastThemeData.fallback();
```

with:

```dart
    final CapsuleToastThemeData theme = CapsuleToastThemeData.fallback(
      brightness,
    );
```

and the specimen backdrop:

```dart
            color: brightness == Brightness.dark ? Lab.darkBg : Lab.bgDeep,
```

In `example/lib/lab/lab_specimens.dart`, replace the private getter on line 14:

```dart
  static CapsuleToastThemeData get _theme => CapsuleToastThemeData.fallback();
```

with a function taking the appearance:

```dart
  static CapsuleToastThemeData _themeFor(Brightness brightness) =>
      CapsuleToastThemeData.fallback(brightness);
```

Then thread it through the four public members — `icon`, `seed`, `compact`, `expanded`. Each gains a `Brightness brightness = Brightness.light` named parameter (`seed` gains a parameter list, since it currently has none: `static Widget seed({Brightness brightness = Brightness.light})`), each replaces its `final CapsuleToastThemeData theme = _theme;` with `final CapsuleToastThemeData theme = _themeFor(brightness);`, and each gains the dartdoc line:

```dart
  /// [brightness] selects the capsule appearance, matching the phone.
```

`expanded` also calls `icon(type)` internally — change that call to `icon(type, brightness: brightness)`. The private `_pill` takes explicit colours and needs no change.

- [ ] **Step 4: Add the picker and wrap the phone in a Theme**

In `example/lib/capsule_toast_lab.dart`:

a) Add state beside the other flags:

```dart
  Brightness _appearance = Brightness.light;
```

b) Add the helper beside the other getters:

```dart
  bool get _isDark => _appearance == Brightness.dark;
```

c) Replace `_buildPhoneContents` in full. `ThemeData.copyWith(brightness:)` changes the brightness the capsule reads without disturbing the lab's Inter text theme:

```dart
  Widget _buildPhoneContents() {
    // The host reads the ambient MediaQuery, so the phone canvas supplies its
    // own safe area and reduced-motion setting rather than the desktop
    // window's. It supplies its own brightness for the same reason: the
    // capsule resolves its appearance from the Theme it is shown under.
    return Theme(
      data: Theme.of(context).copyWith(brightness: _appearance),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: Lab.phoneSize,
          padding: const EdgeInsets.only(top: _phoneTopInset),
          viewPadding: const EdgeInsets.only(top: _phoneTopInset),
          viewInsets: EdgeInsets.zero,
          disableAnimations: _reducedMotion,
        ),
        child: Directionality(
          textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          child: CapsuleToastHost(
            child: Builder(
              builder: (BuildContext hostContext) {
                _manager ??= CapsuleToastHost.of(hostContext);
                return Stack(
                  children: <Widget>[
                    Positioned.fill(child: LabPhoneScreen(dark: _isDark)),
                    LabDemoDock(
                      dark: _isDark,
                      open: _dockOpen,
                      onOpenChanged: (bool value) =>
                          setState(() => _dockOpen = value),
                      onFire: _fire,
                      onFireExpanded: () => _fire(
                        LabVariant.success,
                        mode: CapsuleToastMode.expanded,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
```

d) Pass `dark: _isDark` to `LabPhoneFrame` in `_buildPhoneColumn`, and insert the picker between the frame and the state readout:

```dart
  Widget _buildPhoneColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LabPhoneFrame(dark: _isDark, child: _buildPhoneContents()),
        const SizedBox(height: 14),
        SizedBox(
          width: 260,
          child: LabSegmentedPicker<Brightness>(
            value: _appearance,
            onChanged: (Brightness value) =>
                setState(() => _appearance = value),
            options: const <({Brightness value, String label})>[
              (value: Brightness.light, label: 'Light app'),
              (value: Brightness.dark, label: 'Dark app'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildStateReadout(),
      ],
    );
  }
```

e) Thread the appearance into the component-state gallery. There are exactly five specimens, around lines 559–612 of `example/lib/capsule_toast_lab.dart`: `seed`, `compact`, `expanded`, `loading`, and `compact · RTL mirrored`. Each needs `brightness: _appearance` on **both** the `LabSpecimen` and its `LabSpecimens.*` child. For example, the first two become:

```dart
        LabSpecimen(
          label: 'seed',
          dimensions: '84 × 34 · r 17',
          width: 84,
          brightness: _appearance,
          child: LabSpecimens.seed(brightness: _appearance),
        ),
        const SizedBox(height: 12),
        LabSpecimen(
          label: 'compact',
          dimensions: 'content-driven · h 44 · r 22',
          brightness: _appearance,
          child: LabSpecimens.compact(
            type: CapsuleToastType.success,
            title: labVariantCopy(LabVariant.success, rtl: false).title,
            chipLabel: labVariantCopy(
              LabVariant.success,
              rtl: false,
            ).compactAction,
            direction: ltr,
            brightness: _appearance,
          ),
        ),
```

Apply the same two additions to the remaining three. Note that the `seed` and `expanded` specimens currently sit in a `const`-friendly position — adding `brightness: _appearance` makes them non-const, which is expected.

- [ ] **Step 5: Analyze and run the example**

Run: `cd example && flutter analyze`
Expected: clean.

Run: `cd example && flutter run -d macos` (or any available device)

Verify by hand: toggling to **Dark app** turns the phone canvas charcoal, and firing a toast shows the lighter `#26231E` capsule with a visible rim — lifting above the background rather than sinking into it. The panel around the phone stays light. Toggling back restores the near-black capsule.

- [ ] **Step 6: Commit**

```bash
git add example/lib
git commit -m "example: add a light/dark app toggle to the lab

Mirrors the reference lab's appearance picker. The phone canvas, the dock and
the frozen specimens follow the toggle; the lab chrome around them stays light,
as the reference specifies."
```

---

### Task 6: Documentation and release

**Files:**
- Modify: `README.md:157-172`
- Modify: `CHANGELOG.md:1`
- Modify: `pubspec.yaml:4`

**Interfaces:**
- Consumes: the public API from Tasks 1–3.
- Produces: nothing.

- [ ] **Step 1: Document dark mode in the README**

In `README.md`, replace the closing line of the **Visual theme** section (`Fonts inherit from the application — this package does not bundle typefaces.`) with that line followed by a new section:

````markdown
Fonts inherit from the application — this package does not bundle typefaces.

## Dark mode

The capsule ships two appearances and picks one from the host application's
brightness, so an app with both `theme:` and `darkTheme:` needs no
package-specific configuration:

```dart
MaterialApp(
  theme: ThemeData(brightness: Brightness.light),
  darkTheme: ThemeData(brightness: Brightness.dark),
  builder: (BuildContext context, Widget? child) {
    return CapsuleToastHost(child: child!);
  },
  home: const HomePage(),
);
```

In a light app the capsule is a near-black overlay that sits below the app
surface. In a dark app that would sink into the background, so the dark
appearance lifts one step above it instead, with a brighter rim and stronger
status tints. Geometry, timings and springs are shared.

Customise one appearance by registering an extension on that `ThemeData` —
anything you leave out still comes from the matching built-in appearance:

```dart
ThemeData(
  brightness: Brightness.dark,
  extensions: <ThemeExtension<dynamic>>[
    CapsuleToastThemeData(
      surfaceColor: const Color(0xFF2A2622),
      innerHighlightColor: const Color(0x1FFFFFFF),
    ),
  ],
);
```

Pin one appearance regardless of the app by registering a whole fallback:

```dart
ThemeData(
  brightness: Brightness.dark,
  extensions: <ThemeExtension<dynamic>>[
    CapsuleToastThemeData.fallback(Brightness.light),
  ],
);
```
````

- [ ] **Step 2: Add the changelog entry**

Insert at the top of `CHANGELOG.md`:

```markdown
## 0.4.0

Capsule toasts now follow the host application's brightness.

Other changes:

- `CapsuleToastThemeData.fallback` takes an optional `Brightness` selecting the
  appearance. It defaults to `Brightness.light`, so existing calls are
  unchanged.
- `CapsuleToastTheme.resolve` bases its result on `Theme.of(context).brightness`.
  Overrides from `ThemeData.extensions` and a nearest `CapsuleToastTheme` merge
  over that base in the same order as before.
- Added `CapsuleToastThemeData.innerHighlightColor` and
  `innerHighlightWidth`, the inner rim highlight along the capsule's top curve.
  The dark appearance sets them; the light appearance leaves them null.
- Motion, geometry, layout and typography are identical in both appearances.

```

- [ ] **Step 3: Bump the version**

In `pubspec.yaml`, change `version: 0.3.0` to `version: 0.4.0`.

- [ ] **Step 4: Verify the whole package**

Run: `dart analyze && flutter test && dart pub publish --dry-run`
Expected: analyzer clean, every test green, and the dry run reporting no errors.

- [ ] **Step 5: Commit**

```bash
git add README.md CHANGELOG.md pubspec.yaml
git commit -m "docs: release 0.4.0 with dark mode support"
```

---

## Verification

After Task 6, the following must all hold:

- `dart analyze` is clean for both the package and `example/`.
- `flutter test` is green, including the six existing goldens (proving light mode is untouched) and the new dark golden.
- `CapsuleToastThemeData.fallback()` with no argument is `==` to
  `CapsuleToastThemeData.fallback(Brightness.light)`.
- Running the example and toggling to **Dark app** shows a capsule that is
  lighter than the phone background, with a legible rim.
