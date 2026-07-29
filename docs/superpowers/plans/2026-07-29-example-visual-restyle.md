# Example Visual Restyle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the interactive example with a cool blue/slate palette and visibly different button borders without changing behavior.

**Architecture:** Keep the palette centralized in the existing `Lab` token class and keep button-specific geometry in `LabButton`. Exercise the public example widgets in the existing widget-test file so the visual contract is verified without changing package code.

**Tech Stack:** Dart 3.12, Flutter Material widgets, `flutter_test`

## Global Constraints

- Modify only the example application under `example/`; do not change the package API or capsule toast implementation.
- Do not change callbacks, state, animation, layout dimensions, labels, semantics, or interaction behavior.
- Preserve light/dark appearance switching and the existing dark phone surfaces.
- Use a cool blue/slate palette with indigo and teal accents.
- Give primary and secondary buttons a 10 px corner radius and a visible 1.5 px blue-gray border.

---

## File Structure

- `example/lib/lab/lab_tokens.dart`: owns the example's shared surface, text, accent, and button-border colors.
- `example/lib/lab/lab_panel.dart`: owns the `LabButton` border geometry and primary/secondary border selection.
- `example/test/capsule_toast_lab_test.dart`: verifies the new palette and both button variants while retaining the existing behavior coverage.

### Task 1: Cool Palette and Button Treatment

**Files:**
- Modify: `example/lib/lab/lab_tokens.dart:6-76`
- Modify: `example/lib/lab/lab_panel.dart:44-101`
- Test: `example/test/capsule_toast_lab_test.dart:3-88`

**Interfaces:**
- Consumes: Existing `Lab` static token API and `LabButton({required String label, required VoidCallback onPressed, bool primary = false})`.
- Produces: `Lab.buttonBorder` and `Lab.primaryButtonBorder` as `static const Color` tokens; the existing `LabButton` API remains unchanged.

- [x] **Step 1: Write failing palette and button-decoration tests**

Add the panel import and use the Material library for widget decoration types:

```dart
import 'package:capsule_toast_example/lab/lab_panel.dart';
import 'package:flutter/material.dart';
```

Replace the existing `package:flutter/widgets.dart` import with the Material
import, then add these tests inside `main()`:

```dart
  test('the lab palette uses the cool blue slate treatment', () {
    expect(Lab.bg, const Color(0xFFEEF3F8));
    expect(Lab.bgDeep, const Color(0xFFE2EAF2));
    expect(Lab.card, const Color(0xFFF8FAFC));
    expect(Lab.cardAlt, const Color(0xFFE6EDF5));
    expect(Lab.ink, const Color(0xFF172033));
    expect(Lab.ink2, const Color(0xFF334155));
    expect(Lab.muted, const Color(0xFF526174));
    expect(Lab.muted2, const Color(0xFF607086));
    expect(Lab.amber, const Color(0xFF526FA8));
    expect(Lab.sage, const Color(0xFF3F8884));
    expect(Lab.buttonBorder, const Color(0xFF7187A6));
    expect(Lab.primaryButtonBorder, const Color(0xFF8FA7D4));
  });

  testWidgets('lab buttons use the new outlined rounded border', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: <Widget>[
            LabButton(label: 'Secondary', onPressed: () {}),
            LabButton(label: 'Primary', onPressed: () {}, primary: true),
          ],
        ),
      ),
    );

    BoxDecoration decorationFor(String label) {
      final Finder button = find.ancestor(
        of: find.text(label),
        matching: find.byType(LabButton),
      );
      final Ink ink = tester.widget(
        find.descendant(of: button, matching: find.byType(Ink)),
      );
      return ink.decoration! as BoxDecoration;
    }

    final BoxDecoration secondary = decorationFor('Secondary');
    final BoxDecoration primary = decorationFor('Primary');

    expect(
      secondary.borderRadius,
      BorderRadius.circular(10),
    );
    expect(
      secondary.border,
      Border.all(color: Lab.buttonBorder, width: 1.5),
    );
    expect(
      primary.border,
      Border.all(color: Lab.primaryButtonBorder, width: 1.5),
    );
  });
```

- [x] **Step 2: Run the focused tests and verify they fail**

Run:

```bash
flutter test test/capsule_toast_lab_test.dart
```

from `example/`.

Expected: compilation fails because `Lab.buttonBorder` and
`Lab.primaryButtonBorder` do not exist yet, confirming the new visual contract
is not implemented.

- [x] **Step 3: Implement the cool palette tokens**

Update the light surfaces, strokes, type, and accent section in
`lab_tokens.dart` to the following values and descriptions. Keep all dark-app
tokens, dimensions, typography helpers, and existing token names intact:

```dart
  /// Pale blue-gray page background.
  static const Color bg = Color(0xFFEEF3F8);

  /// Recessed blue-gray surface behind frozen specimens.
  static const Color bgDeep = Color(0xFFE2EAF2);

  /// Crisp near-white card fill.
  static const Color card = Color(0xFFF8FAFC);

  /// Cool slate fill for nested chips and tracks.
  static const Color cardAlt = Color(0xFFE6EDF5);

  /// Low-emphasis blue-gray hairline stroke.
  static const Color hairline = Color(0x33566B85);

  /// Faint blue-gray divider stroke.
  static const Color divider = Color(0x1F566B85);

  /// Inactive blue-gray toggle track.
  static const Color toggleTrack = Color(0x38566B85);

  /// Solid outline for secondary control buttons.
  static const Color buttonBorder = Color(0xFF7187A6);

  /// Contrasting outline for primary control buttons.
  static const Color primaryButtonBorder = Color(0xFF8FA7D4);
```

```dart
  /// Deep navy primary text.
  static const Color ink = Color(0xFF172033);

  /// Slate secondary heading text.
  static const Color ink2 = Color(0xFF334155);

  /// Muted slate body text.
  static const Color muted = Color(0xFF526174);

  /// Faint blue-gray supporting text.
  static const Color muted2 = Color(0xFF607086);
```

```dart
  /// Indigo accent used for the eyebrow and timeline bands.
  static const Color amber = Color(0xFF526FA8);

  /// Teal accent used for active toggles and the live state dot.
  static const Color sage = Color(0xFF3F8884);

  /// Indigo timeline band at 16 percent opacity.
  static const Color bandAmber = Color(0x29526FA8);

  /// Teal timeline band at 16 percent opacity.
  static const Color bandSage = Color(0x293F8884);
```

Also rewrite the class-level documentation so it describes example-owned design
tokens rather than tokens copied verbatim from another design system:

```dart
/// Design tokens for the interactive capsule toast lab.
///
/// The cool blue/slate treatment gives the example a distinct visual identity
/// while keeping its motion, layout, and interactions focused on the package.
```

- [x] **Step 4: Implement the new border treatment**

In `LabButton`, update the class and constructor summaries from “pill button” to
“control button”. Change all three button border radii from `999` to `10`, and
replace the conditional border with:

```dart
              border: Border.all(
                color: primary
                    ? Lab.primaryButtonBorder
                    : Lab.buttonBorder,
                width: 1.5,
              ),
```

Keep height, fill colors, elevation, shadow, padding, label styling, ripple,
callback, and public constructor API unchanged.

- [x] **Step 5: Format and run focused verification**

Run from the repository root:

```bash
dart format example/lib/lab/lab_tokens.dart example/lib/lab/lab_panel.dart example/test/capsule_toast_lab_test.dart
```

Then run:

```bash
flutter test test/capsule_toast_lab_test.dart
flutter analyze
```

from `example/`.

Expected: formatting makes no semantic changes; all widget tests pass; analysis
reports no issues.

- [x] **Step 6: Review the diff for scope and commit**

Run:

```bash
git diff --check
git diff -- example/lib/lab/lab_tokens.dart example/lib/lab/lab_panel.dart example/test/capsule_toast_lab_test.dart
```

Confirm the diff contains only palette values/documentation, button border
decoration, and focused assertions. Then commit:

```bash
git add example/lib/lab/lab_tokens.dart example/lib/lab/lab_panel.dart example/test/capsule_toast_lab_test.dart
git commit -m "style: refresh example visual identity"
```
