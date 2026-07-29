# Capsule Toast Glyph Flutter Code Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle `lib/src/widgets/capsule_toast_glyph.dart` so it reads like
`packages/flutter/lib/src/material/progress_indicator.dart`, without changing a
single painted pixel.

**Architecture:** The file is reshaped into the reference's silhouette —
private `_k` constants, then the `CustomPainter`, then the public widget, then
its `State`, then a hand-coded defaults class. Glyph resolution moves onto the
`CapsuleToastGlyph` enum, the per-glyph size table becomes an internal default
behind a nullable `size`, and the spinner adopts
`_CircularProgressIndicatorState`'s controller lifecycle so `TickerMode`
replaces the bespoke `tickerEnabled` flag.

**Tech Stack:** Flutter `>=3.44.0`, Dart SDK `^3.12.2`, `flutter_lints ^6.0.0`,
`flutter_test`. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-07-29-capsule-toast-glyph-flutter-style-design.md`

## Global Constraints

- **No painted output may change.** `test/widgets/capsule_toast_golden_test.dart`
  runs against a zero-tolerance comparator over six PNGs in `test/goldens/`.
  Any pixel difference is a bug in the implementation, never a golden to
  re-record. Never run `flutter test --update-goldens`.
- Copyright header on every touched Dart file:
  `// Copyright 2026 The Capsule Toast Authors. All rights reserved.`
- Import order: `dart:` group, `package:flutter/` group, local relative group,
  one blank line between groups.
- Line length 80 where practical; trailing commas on multiline argument and
  parameter lists. Run `dart format` on every file you touch before committing.
- Every public class ends its dartdoc with a `See also:` list; every public
  field and member has dartdoc; every public widget overrides
  `debugFillProperties`.
- `CustomPainter.shouldRepaint` and `State.didUpdateWidget` already declare
  their parameters `covariant` in the base class. Do **not** write `covariant`
  on the overrides — the reference does not.
- The widget receives an already-resolved `CapsuleToastThemeData` as a
  constructor parameter. Do **not** convert it to a `BuildContext` lookup;
  every widget in `lib/src/widgets/` follows this convention because toasts
  render in an overlay.
- The test hook `ValueKey<String>('capsule.<glyph>.glyph')` must survive
  byte-identical. `test/widgets/capsule_toast_glyph_test.dart` finds the
  spinner through it.

---

### Task 1: Move glyph resolution onto the enum

Replaces the top-level `resolveCapsuleToastGlyph` function with a
`CapsuleToastGlyph.resolveFor` method declared beside the enum.

**Files:**
- Modify: `lib/src/model/capsule_toast_types.dart:49-73` (enum) — add method
- Modify: `lib/src/widgets/capsule_toast_glyph.dart:149-166` — delete function
- Modify: `lib/src/widgets/capsule_toast_content.dart:325-333` — call site
- Modify: `example/lib/lab/lab_specimens.dart:29` — call site
- Modify: `lib/capsule_toast.dart:19` — barrel export
- Test: `test/model/capsule_toast_types_test.dart` — append a group

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `CapsuleToastGlyph.resolveFor(CapsuleToastType type)` returning
  `CapsuleToastGlyph`. Tasks 2 and 5 rely on this exact name.

- [ ] **Step 1: Write the failing test**

Append to `test/model/capsule_toast_types_test.dart`, inside the existing
`main()` body. The file already imports
`package:capsule_toast/capsule_toast.dart` and
`package:flutter_test/flutter_test.dart`; if either is missing, add it.

```dart
  group('CapsuleToastGlyph.resolveFor', () {
    test('maps every toast type to a paintable glyph', () {
      const CapsuleToastGlyph automatic = CapsuleToastGlyph.automatic;
      expect(
        automatic.resolveFor(CapsuleToastType.success),
        CapsuleToastGlyph.success,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.information),
        CapsuleToastGlyph.information,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.warning),
        CapsuleToastGlyph.warning,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.error),
        CapsuleToastGlyph.error,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.loading),
        CapsuleToastGlyph.loading,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.neutral),
        CapsuleToastGlyph.neutral,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.custom),
        CapsuleToastGlyph.neutral,
      );
    });

    test('never resolves to automatic', () {
      for (final CapsuleToastType type in CapsuleToastType.values) {
        expect(
          CapsuleToastGlyph.automatic.resolveFor(type),
          isNot(CapsuleToastGlyph.automatic),
        );
      }
    });

    test('returns an explicit glyph unchanged', () {
      expect(
        CapsuleToastGlyph.connectivity.resolveFor(CapsuleToastType.success),
        CapsuleToastGlyph.connectivity,
      );
      expect(
        CapsuleToastGlyph.error.resolveFor(CapsuleToastType.success),
        CapsuleToastGlyph.error,
      );
    });
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/model/capsule_toast_types_test.dart`
Expected: FAIL to compile — `The method 'resolveFor' isn't defined for the type 'CapsuleToastGlyph'`.

- [ ] **Step 3: Add the method to the enum**

In `lib/src/model/capsule_toast_types.dart`, change the final enum value from
`neutral,` to `neutral;` and append the method inside the enum body:

```dart
  /// Neutral glyph.
  neutral;

  /// The glyph to paint for [type].
  ///
  /// [automatic] resolves to the glyph matching [type];
  /// [CapsuleToastType.custom] has no glyph of its own and resolves to
  /// [neutral]. Any other value is returned unchanged, so a caller can pass a
  /// user-supplied glyph through without checking it first.
  ///
  /// The result is never [automatic].
  CapsuleToastGlyph resolveFor(CapsuleToastType type) {
    if (this != CapsuleToastGlyph.automatic) {
      return this;
    }
    return switch (type) {
      CapsuleToastType.success => CapsuleToastGlyph.success,
      CapsuleToastType.information => CapsuleToastGlyph.information,
      CapsuleToastType.warning => CapsuleToastGlyph.warning,
      CapsuleToastType.error => CapsuleToastGlyph.error,
      CapsuleToastType.loading => CapsuleToastGlyph.loading,
      CapsuleToastType.neutral => CapsuleToastGlyph.neutral,
      CapsuleToastType.custom => CapsuleToastGlyph.neutral,
    };
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/model/capsule_toast_types_test.dart`
Expected: PASS.

- [ ] **Step 5: Delete the old function and update its three callers**

Delete this entire block from `lib/src/widgets/capsule_toast_glyph.dart`:

```dart
/// Resolves [glyph] from toast [type] when [glyph] is [CapsuleToastGlyph.automatic].
CapsuleToastGlyph resolveCapsuleToastGlyph(
  CapsuleToastGlyph glyph,
  CapsuleToastType type,
) {
  if (glyph != CapsuleToastGlyph.automatic) {
    return glyph;
  }
  return switch (type) {
    CapsuleToastType.success => CapsuleToastGlyph.success,
    CapsuleToastType.information => CapsuleToastGlyph.information,
    CapsuleToastType.warning => CapsuleToastGlyph.warning,
    CapsuleToastType.error => CapsuleToastGlyph.error,
    CapsuleToastType.loading => CapsuleToastGlyph.loading,
    CapsuleToastType.neutral => CapsuleToastGlyph.neutral,
    CapsuleToastType.custom => CapsuleToastGlyph.neutral,
  };
}
```

In `lib/src/widgets/capsule_toast_content.dart`, replace:

```dart
      final CapsuleToastGlyph resolved = resolveCapsuleToastGlyph(
        data.glyph,
        data.type,
      );
```

with:

```dart
      final CapsuleToastGlyph resolved = data.glyph.resolveFor(data.type);
```

In `example/lib/lab/lab_specimens.dart`, replace:

```dart
        glyph: resolveCapsuleToastGlyph(CapsuleToastGlyph.automatic, type),
```

with:

```dart
        glyph: CapsuleToastGlyph.automatic.resolveFor(type),
```

In `lib/capsule_toast.dart`, replace:

```dart
export 'src/widgets/capsule_toast_glyph.dart'
    show CapsuleToastGlyphWidget, resolveCapsuleToastGlyph;
```

with:

```dart
export 'src/widgets/capsule_toast_glyph.dart' show CapsuleToastGlyphWidget;
```

- [ ] **Step 6: Run the full suite and the analyzer**

```bash
dart format lib test example
dart analyze
flutter test
(cd example && flutter test)
```

Expected: analyzer reports no issues; every test passes, including the six
golden comparisons.

- [ ] **Step 7: Commit**

```bash
git add lib/src/model/capsule_toast_types.dart \
        lib/src/widgets/capsule_toast_glyph.dart \
        lib/src/widgets/capsule_toast_content.dart \
        lib/capsule_toast.dart \
        example/lib/lab/lab_specimens.dart \
        test/model/capsule_toast_types_test.dart
git commit -m "refactor: move glyph resolution onto CapsuleToastGlyph"
```

---

### Task 2: Rename the widget and internalise the size table

Renames `CapsuleToastGlyphWidget` to `CapsuleToastGlyphIcon` and
`_CapsuleGlyphPainter` to `_CapsuleToastGlyphPainter`, makes `size` nullable,
and replaces the public `capsuleToastGlyphSize` function with a private
defaults class.

**Files:**
- Modify: `lib/src/widgets/capsule_toast_glyph.dart`
- Modify: `lib/src/widgets/capsule_toast_content.dart:325-334`
- Modify: `lib/capsule_toast.dart:18-19`
- Modify: `example/lib/lab/lab_specimens.dart:28-34`
- Test: `test/widgets/capsule_toast_glyph_test.dart` (new test appended)

**Interfaces:**
- Consumes: `CapsuleToastGlyph.resolveFor` from Task 1.
- Produces: `CapsuleToastGlyphIcon({Key? key, required CapsuleToastGlyph glyph,
  required Color color, required CapsuleToastThemeData theme, double? size,
  bool tickerEnabled = true})` and the private
  `_CapsuleToastGlyphIconDefaults(CapsuleToastGlyph glyph).size` returning
  `double`. `tickerEnabled` survives this task and is removed in Task 3.

- [ ] **Step 1: Write the failing test**

Append inside `main()` in `test/widgets/capsule_toast_glyph_test.dart`. The
file already imports `package:capsule_toast/capsule_toast.dart`,
`package:flutter/widgets.dart`, and `package:flutter_test/flutter_test.dart`.

```dart
  testWidgets('a null size falls back to the glyph optical default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Center(
        child: CapsuleToastGlyphIcon(
          glyph: CapsuleToastGlyph.warning,
          color: const Color(0xFF101010),
          theme: CapsuleToastThemeData.fallback(),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey<String>('capsule.warning.glyph'))),
      const Size(17, 17),
    );
  });

  testWidgets('an explicit size overrides the optical default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Center(
        child: CapsuleToastGlyphIcon(
          glyph: CapsuleToastGlyph.warning,
          color: const Color(0xFF101010),
          size: 24,
          theme: CapsuleToastThemeData.fallback(),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey<String>('capsule.warning.glyph'))),
      const Size(24, 24),
    );
  });
```

`Center` is required: `pumpWidget` hands the root a tight screen-sized
constraint, and a bare `SizedBox` would be stretched to fill it.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widgets/capsule_toast_glyph_test.dart`
Expected: FAIL to compile — `Undefined name 'CapsuleToastGlyphIcon'`.

- [ ] **Step 3: Rename the classes and make `size` optional**

In `lib/src/widgets/capsule_toast_glyph.dart`:

Rename `CapsuleToastGlyphWidget` to `CapsuleToastGlyphIcon`,
`_CapsuleToastGlyphWidgetState` to `_CapsuleToastGlyphIconState`, and
`_CapsuleGlyphPainter` to `_CapsuleToastGlyphPainter` throughout the file
(class declarations, `createState` return type and body, `State<...>` type
argument, `didUpdateWidget` parameter type, `shouldRepaint` parameter type,
and the painter construction in `build`).

Change the constructor so `size` is optional and validated:

```dart
  /// Creates a capsule toast status glyph.
  const CapsuleToastGlyphIcon({
    super.key,
    required this.glyph,
    required this.color,
    required this.theme,
    this.size,
    this.tickerEnabled = true,
  }) : assert(size == null || size > 0);
```

Change the field:

```dart
  /// The logical width and height of the glyph canvas.
  ///
  /// If null, each glyph is painted at its own optical default.
  final double? size;
```

Delete the top-level `capsuleToastGlyphSize` function together with its
doc comment, and add this defaults class as the last declaration in the file:

```dart
// Hand coded defaults transcribed from the reference SVGs.
//
// The reference sizes each glyph individually rather than normalising them:
// the check is the lightest shape so it can afford to be smallest, while the
// triangle and the signal arcs need the extra room to read at a glance. Every
// glyph shares the same 20-unit canvas, so this is purely optical balance.
class _CapsuleToastGlyphIconDefaults {
  const _CapsuleToastGlyphIconDefaults(this.glyph);

  final CapsuleToastGlyph glyph;

  double get size => switch (glyph) {
    CapsuleToastGlyph.success => 15,
    CapsuleToastGlyph.information => 16,
    CapsuleToastGlyph.warning => 17,
    CapsuleToastGlyph.error => 16,
    CapsuleToastGlyph.connectivity => 17,
    CapsuleToastGlyph.loading => 18,
    CapsuleToastGlyph.neutral => 16,
    CapsuleToastGlyph.automatic => 16,
  };
}
```

Rewrite `build` so the size is resolved once and every branch uses it:

```dart
  @override
  Widget build(BuildContext context) {
    final double size =
        widget.size ?? _CapsuleToastGlyphIconDefaults(widget.glyph).size;

    final CapsuleToastGlyphBuilder? glyphBuilder = widget.theme.glyphBuilder;
    if (glyphBuilder != null &&
        widget.glyph != CapsuleToastGlyph.loading &&
        widget.glyph != CapsuleToastGlyph.connectivity) {
      return glyphBuilder(context, widget.glyph, widget.color, size);
    }

    final CapsuleToastSpinnerBuilder? spinnerBuilder =
        widget.theme.spinnerBuilder;
    if (widget.glyph == CapsuleToastGlyph.loading && spinnerBuilder != null) {
      return spinnerBuilder(context, widget.color, size);
    }

    return SizedBox(
      key: ValueKey<String>('capsule.${widget.glyph.name}.glyph'),
      width: size,
      height: size,
      child: CustomPaint(
        // The spinner repaints straight off the controller. Reading
        // `_controller.value` without subscribing to it is what left the
        // spinner frozen: the ticker ran, but nothing ever asked for a frame.
        painter: _CapsuleToastGlyphPainter(
          glyph: widget.glyph,
          color: widget.color,
          rotation: _controller,
        ),
      ),
    );
  }
```

Update `debugFillProperties` to carry the nullable size:

```dart
    properties.add(DoubleProperty('size', size, defaultValue: null));
```

- [ ] **Step 4: Update the callers**

In `lib/src/widgets/capsule_toast_content.dart`, replace the whole `else`
branch:

```dart
    } else {
      icon = CapsuleToastGlyphIcon(
        glyph: data.glyph.resolveFor(data.type),
        color: accent,
        theme: theme,
      );
    }
```

The local `final CapsuleToastGlyph resolved = ...` introduced in Task 1 is now
unused; delete it.

In `lib/capsule_toast.dart`:

```dart
export 'src/widgets/capsule_toast_glyph.dart' show CapsuleToastGlyphIcon;
```

In `example/lib/lab/lab_specimens.dart`, rename the constructor call to
`CapsuleToastGlyphIcon`. Keep `size: 20` and `tickerEnabled: spinning` — the
specimen gallery deliberately draws every glyph at one size.

- [ ] **Step 5: Run the test to verify it passes**

```bash
dart format lib test example
dart analyze
flutter test
(cd example && flutter test)
```

Expected: analyzer clean; all tests pass, goldens included. If a golden fails,
the resolved default size no longer matches what `capsuleToastGlyphSize`
returned — compare against the table in Step 3 rather than re-recording.

- [ ] **Step 6: Commit**

```bash
git add lib/src/widgets/capsule_toast_glyph.dart \
        lib/src/widgets/capsule_toast_content.dart \
        lib/capsule_toast.dart \
        example/lib/lab/lab_specimens.dart \
        test/widgets/capsule_toast_glyph_test.dart
git commit -m "refactor: rename glyph widget and internalise its size defaults"
```

---

### Task 3: Adopt the framework animation lifecycle

Replaces the on-demand controller with `_CircularProgressIndicatorState`'s
shape, returns the `State` to `SingleTickerProviderStateMixin`, and swaps
`tickerEnabled` for `TickerMode`.

**Files:**
- Modify: `lib/src/widgets/capsule_toast_glyph.dart`
- Modify: `example/lib/lab/lab_specimens.dart:17-35`
- Test: `test/widgets/capsule_toast_glyph_test.dart` (four new tests)

**Interfaces:**
- Consumes: `CapsuleToastGlyphIcon` from Task 2.
- Produces: `CapsuleToastGlyphIcon.defaultAnimationDuration`, a
  `static const Duration`. The `tickerEnabled` parameter is removed.

> **This task has no red step, and that is correct.** `TickerProviderStateMixin`
> — the mixin in use today — already honours `TickerMode`: it mutes the tickers
> it hands out at creation time from `TickerMode.getNotifier(context)`. So the
> `TickerMode` tests below pass *before* the refactor as well as after. That is
> exactly what makes removing `tickerEnabled` safe, and it is what these tests
> are for: they are characterization tests, written and committed first, that
> pin the behavior `tickerEnabled` is being handed off to. Do not contrive a
> failing test to satisfy a red-green habit here.

- [ ] **Step 1: Write the characterization tests and commit them first**

Append inside `main()` in `test/widgets/capsule_toast_glyph_test.dart`:

```dart
  testWidgets('a disabled TickerMode leaves the spinner unscheduled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Center(
        child: TickerMode(
          enabled: false,
          child: CapsuleToastGlyphIcon(
            glyph: CapsuleToastGlyph.loading,
            color: const Color(0xFF101010),
            theme: CapsuleToastThemeData.fallback(),
          ),
        ),
      ),
    );

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('an enabled TickerMode schedules the spinner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Center(
        child: TickerMode(
          enabled: true,
          child: CapsuleToastGlyphIcon(
            glyph: CapsuleToastGlyph.loading,
            color: const Color(0xFF101010),
            theme: CapsuleToastThemeData.fallback(),
          ),
        ),
      ),
    );

    expect(tester.binding.transientCallbackCount, 1);

    // Tear the tree down inside the test so the controller is disposed while
    // the binding is still live.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a non-loading glyph schedules nothing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Center(
        child: CapsuleToastGlyphIcon(
          glyph: CapsuleToastGlyph.success,
          color: const Color(0xFF101010),
          theme: CapsuleToastThemeData.fallback(),
        ),
      ),
    );

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a glyph element reused across loading cycles keeps spinning', (
    WidgetTester tester,
  ) async {
    Future<void> pumpGlyph(CapsuleToastGlyph glyph) {
      return tester.pumpWidget(
        Center(
          child: CapsuleToastGlyphIcon(
            glyph: glyph,
            color: const Color(0xFF101010),
            theme: CapsuleToastThemeData.fallback(),
          ),
        ),
      );
    }

    await pumpGlyph(CapsuleToastGlyph.loading);
    await pumpGlyph(CapsuleToastGlyph.success);
    await pumpGlyph(CapsuleToastGlyph.loading);

    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 1);

    await tester.pumpWidget(const SizedBox());
  });
```

The last test is the one that matters most. It is the scenario the deleted
comment described — a loading glyph that resolves and then loads again, reusing
the same element — and it is why the widget needed `TickerProviderStateMixin`
before. Under the new lifecycle one controller serves all three pumps, so
`SingleTickerProviderStateMixin` is correct again; if the implementation
regresses to creating a second ticker per `State`, this test throws.

- [ ] **Step 2: Run the tests and verify they pass, then commit them**

```bash
flutter test test/widgets/capsule_toast_glyph_test.dart
```

Expected: PASS, all of them, against the *unmodified* widget. If the disabled
`TickerMode` test fails here, stop and investigate before refactoring — the
premise that `TickerMode` can replace `tickerEnabled` would be wrong, and the
rest of this task is unsafe.

```bash
git add test/widgets/capsule_toast_glyph_test.dart
git commit -m "test: pin TickerMode and controller reuse for the glyph spinner"
```

Committing the net before the refactor means a later `git bisect` can tell a
broken refactor from a broken test.

- [ ] **Step 3: Rewrite the State and remove `tickerEnabled`**

In `lib/src/widgets/capsule_toast_glyph.dart`, delete the `tickerEnabled`
field, its constructor parameter, and its `debugFillProperties` line. Delete
the six-line comment above the `State` class explaining why
`TickerProviderStateMixin` was needed — it no longer is.

Add the static duration to `CapsuleToastGlyphIcon`, after the fields:

```dart
  /// The default duration of one full rotation of the loading spinner.
  ///
  /// Used for the [AnimationController] this widget creates and owns.
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: _kGlyphSpinnerDuration,
  );
```

Add the private constant near the top of the file, directly after the imports:

```dart
// One full rotation of the loading spinner, in milliseconds. Transcribed from
// the reference prototype, where the spinner turns a little slower than
// Material's own indeterminate indicator so it reads as calm rather than busy.
const int _kGlyphSpinnerDuration = 850;
```

Replace the whole `State` preamble — mixin, field, `initState`,
`didUpdateWidget`, `_syncController`, `dispose` — with:

```dart
class _CapsuleToastGlyphIconState extends State<CapsuleToastGlyphIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: CapsuleToastGlyphIcon.defaultAnimationDuration,
      vsync: this,
    );
    _updateControllerAnimatingStatus();
  }

  @override
  void didUpdateWidget(CapsuleToastGlyphIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateControllerAnimatingStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The spinner turns only when this widget is the thing drawing it: a
  // theme-supplied spinnerBuilder replaces the arc entirely, so leaving the
  // controller repeating behind one would schedule frames nothing paints.
  void _updateControllerAnimatingStatus() {
    final bool animating =
        widget.glyph == CapsuleToastGlyph.loading &&
        widget.theme.spinnerBuilder == null;
    if (animating && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animating && _controller.isAnimating) {
      _controller.stop();
    }
  }
```

`build` is unchanged from Task 2 — it already passes `_controller` to the
painter.

- [ ] **Step 4: Update the example**

In `example/lib/lab/lab_specimens.dart`, wrap the icon in a `TickerMode`:

```dart
      child: TickerMode(
        enabled: spinning,
        child: CapsuleToastGlyphIcon(
          glyph: CapsuleToastGlyph.automatic.resolveFor(type),
          color: theme.accents!.colorFor(type),
          size: 20,
          theme: theme,
        ),
      ),
```

- [ ] **Step 5: Run everything to verify it passes**

```bash
dart format lib test example
dart analyze
flutter test
(cd example && flutter test)
```

Expected: analyzer clean; all tests pass — the four just committed in Step 2,
plus the three that predate this plan and must still pass unchanged: "loading
spinner keeps turning after the capsule settles", "non-loading glyphs are
static", and "custom loading spinner does not start the built-in ticker". That
last one is what the `spinnerBuilder == null` term in
`_updateControllerAnimatingStatus` exists for; if it fails, the term was
dropped.

- [ ] **Step 6: Commit**

```bash
git add lib/src/widgets/capsule_toast_glyph.dart \
        example/lib/lab/lab_specimens.dart
git commit -m "refactor: adopt the framework spinner lifecycle and TickerMode"
```

The test file was already committed in Step 2 and must not have changed since.

---

### Task 4: Reorder the file and decompose the painter

Pure refactor: no behavior change, no new test. The six golden PNGs and the
pixel-diff spinner tests are the regression net.

**Files:**
- Modify: `lib/src/widgets/capsule_toast_glyph.dart`

**Interfaces:**
- Consumes: everything from Tasks 2 and 3.
- Produces: `_kGlyphCanvasSize`, a private top-level `const double`. The
  painter's `rotation` field becomes non-nullable `Animation<double>`.

- [ ] **Step 1: Confirm the suite is green before touching anything**

```bash
flutter test
```

Expected: PASS. A refactor that starts from a red suite cannot be verified.

- [ ] **Step 2: Hoist the canvas constant**

Delete `static const double _canvas = 20;` from the painter and add, beside
`_kGlyphSpinnerDuration`:

```dart
// Every reference SVG is authored on a 20x20 viewBox. All path coordinates in
// this file are in those units and are scaled to the widget's size at paint
// time, so a glyph can be drawn at any size without retuning its numbers.
const double _kGlyphCanvasSize = 20;
```

Replace all three `_canvas` references in the painter with
`_kGlyphCanvasSize`.

- [ ] **Step 3: Make `rotation` non-nullable**

The controller now always exists, so the nullable field and its `?? 0` fallback
are dead weight. Change the painter's field and its dartdoc to:

```dart
  /// Drives the loading spinner, and repaints this painter as it ticks.
  ///
  /// Ignored by every glyph other than [CapsuleToastGlyph.loading]. Passing
  /// this animation to `super.repaint` is what makes the spinner turn: reading
  /// its value without subscribing to it once left the arc frozen, because the
  /// ticker ran but nothing ever asked for a frame.
  final Animation<double> rotation;
```

Change the constructor parameter to `required this.rotation` (it already is)
and, in the loading case, replace `(rotation?.value ?? 0)` with
`rotation.value`.

Delete the now-duplicated `// The spinner repaints straight off the
controller...` comment from `build` — the field's dartdoc carries it.

- [ ] **Step 4: Decompose `paint` into per-glyph methods**

Replace the painter's `paint` method and add seven private methods above it.
Each keeps the SVG-provenance comment that was on its `switch` case.

```dart
  // M4.2 10.6l3.6 3.6L15.8 6 — stroke 2.3
  void _paintSuccess(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(4.2, 10.6)
        ..lineTo(7.8, 14.2)
        ..lineTo(15.8, 6),
      _stroke(2.3),
    );
  }

  // circle r7.6 stroke 1.7 · dot at (10, 6.2) r1.05 · stem M10 9v5
  void _paintInformation(Canvas canvas) {
    canvas.drawCircle(const Offset(10, 10), 7.6, _stroke(1.7));
    canvas.drawCircle(const Offset(10, 6.2), 1.05, _fill);
    canvas.drawLine(const Offset(10, 9), const Offset(10, 14), _stroke(1.9));
  }

  // triangle stroke 1.7 · stem M10 7.9v3.5 · dot at (10, 13.4) r0.95
  void _paintWarning(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(10, 3.1)
        ..lineTo(17, 15.5)
        ..lineTo(3, 15.5)
        ..close(),
      _stroke(1.7),
    );
    canvas.drawLine(
      const Offset(10, 7.9),
      const Offset(10, 11.4),
      _stroke(1.8),
    );
    canvas.drawCircle(const Offset(10, 13.4), 0.95, _fill);
  }

  // circle r7.6 stroke 1.7 · cross 7.4→12.6 stroke 1.8
  void _paintError(Canvas canvas) {
    canvas.drawCircle(const Offset(10, 10), 7.6, _stroke(1.7));
    final Paint cross = _stroke(1.8);
    canvas.drawLine(const Offset(7.4, 7.4), const Offset(12.6, 12.6), cross);
    canvas.drawLine(const Offset(12.6, 7.4), const Offset(7.4, 12.6), cross);
  }

  // Three arcs over a dot, stroke 1.6 — the reference's offline glyph.
  void _paintConnectivity(Canvas canvas) {
    final Paint arcs = _stroke(1.6);
    for (final double y in <double>[7.6, 10.6, 13.6]) {
      final double span = (13.6 - y) * 1.4 + 4;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(10, y + span / 2),
          width: span * 2,
          height: span * 2,
        ),
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        arcs,
      );
    }
    canvas.drawCircle(const Offset(10, 16.4), 1.05, _fill);
  }

  void _paintNeutral(Canvas canvas) {
    canvas.drawCircle(const Offset(10, 10), 2.4, _fill);
  }

  // Track at 0.22 alpha with a quarter-turn head, both stroke 2. The head
  // starts at twelve o'clock: `M10 2.8 a7.2 7.2 0 0 1 7.2 7.2`.
  void _paintLoading(Canvas canvas) {
    canvas.translate(_kGlyphCanvasSize / 2, _kGlyphCanvasSize / 2);
    canvas.rotate(rotation.value * 2 * math.pi);
    canvas.translate(-_kGlyphCanvasSize / 2, -_kGlyphCanvasSize / 2);
    canvas.drawCircle(
      const Offset(10, 10),
      7.2,
      _stroke(2)..color = color.withValues(alpha: 0.22),
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(10, 10), radius: 7.2),
      -math.pi / 2,
      math.pi / 2,
      false,
      _stroke(2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / _kGlyphCanvasSize;
    canvas.save();
    canvas.scale(scale, scale);

    switch (glyph) {
      case CapsuleToastGlyph.success:
        _paintSuccess(canvas);
      case CapsuleToastGlyph.information:
        _paintInformation(canvas);
      case CapsuleToastGlyph.warning:
        _paintWarning(canvas);
      case CapsuleToastGlyph.error:
        _paintError(canvas);
      case CapsuleToastGlyph.connectivity:
        _paintConnectivity(canvas);
      case CapsuleToastGlyph.neutral:
        _paintNeutral(canvas);
      case CapsuleToastGlyph.loading:
        _paintLoading(canvas);
      case CapsuleToastGlyph.automatic:
        break;
    }

    canvas.restore();
  }
```

Drop `covariant` from `shouldRepaint` and rename its parameter to match the
reference:

```dart
  @override
  bool shouldRepaint(_CapsuleToastGlyphPainter oldPainter) {
    return oldPainter.glyph != glyph ||
        oldPainter.color != color ||
        oldPainter.rotation != rotation;
  }
```

- [ ] **Step 5: Reorder the file**

Move whole declarations without editing their bodies. Final order, top to
bottom:

1. Copyright header.
2. Imports (`dart:math`, blank, `package:flutter/foundation.dart` and
   `package:flutter/material.dart`, blank, the two local imports).
3. `_kGlyphSpinnerDuration`, then `_kGlyphCanvasSize`.
4. `_CapsuleToastGlyphPainter`.
5. `CapsuleToastGlyphIcon`.
6. `_CapsuleToastGlyphIconState`.
7. `_CapsuleToastGlyphIconDefaults`.

- [ ] **Step 6: Verify nothing moved on screen**

```bash
dart format lib
dart analyze
flutter test
(cd example && flutter test)
```

Expected: analyzer clean; every test passes, including all six golden
comparisons. A golden failure here means a coordinate was mistyped while
moving a case into its method — diff against `git show HEAD:lib/src/widgets/capsule_toast_glyph.dart`
rather than re-recording.

- [ ] **Step 7: Commit**

```bash
git add lib/src/widgets/capsule_toast_glyph.dart
git commit -m "refactor: reorder glyph file and decompose its painter"
```

---

### Task 5: Framework-depth documentation and diagnostics

**Files:**
- Modify: `lib/src/widgets/capsule_toast_glyph.dart`

**Interfaces:**
- Consumes: the final class and member names from Tasks 2-4.
- Produces: no new symbols.

- [ ] **Step 1: Replace the widget's class dartdoc**

```dart
/// A status glyph for a capsule toast, painted from the package's reference
/// vector artwork.
///
/// There are two kinds of glyph:
///
///  * _Static_. [CapsuleToastGlyph.success], [CapsuleToastGlyph.information],
///    [CapsuleToastGlyph.warning], [CapsuleToastGlyph.error],
///    [CapsuleToastGlyph.connectivity], and [CapsuleToastGlyph.neutral] each
///    paint a fixed shape and never animate.
///  * _Animated_. [CapsuleToastGlyph.loading] paints an arc over a dimmed
///    track, turning once every [defaultAnimationDuration].
///
/// [CapsuleToastGlyph.automatic] paints nothing. Resolve it against a
/// [CapsuleToastType] with [CapsuleToastGlyph.resolveFor] before constructing
/// this widget.
///
/// The glyph is drawn in [color] at [size], or at a per-glyph optical default
/// when [size] is null. It has no background of its own; the tinted circle
/// behind it in a capsule toast is painted by the caller.
///
/// ## Theming
///
/// [theme] is an already-resolved [CapsuleToastThemeData] rather than a value
/// read from the [BuildContext], because toasts render in an overlay where the
/// inherited theme is not reliably reachable.
///
/// A [CapsuleToastThemeData.glyphBuilder] replaces every glyph except
/// [CapsuleToastGlyph.loading] and [CapsuleToastGlyph.connectivity], which have
/// no equivalent in a caller's icon set. A
/// [CapsuleToastThemeData.spinnerBuilder] replaces
/// [CapsuleToastGlyph.loading]; when one is supplied this widget leaves its own
/// animation stopped rather than scheduling frames nothing paints.
///
/// ## Animation
///
/// The spinner is driven by an [AnimationController] this widget creates and
/// owns. To freeze it — in a golden test, or a specimen gallery — wrap this
/// widget in a `TickerMode` with `enabled` set to false, which mutes the
/// ticker without changing what is painted.
///
/// See also:
///
///  * [CapsuleToastGlyph], the set of shapes this widget can paint.
///  * [CapsuleToastThemeData.glyphBuilder], for replacing those shapes.
///  * [CapsuleToastThemeData.spinnerBuilder], for replacing the spinner.
///  * [CircularProgressIndicator], the Material indeterminate spinner this
///    widget's loading glyph is modelled on.
```

- [ ] **Step 2: Document the constructor and every field**

```dart
  /// Creates a capsule toast status glyph.
  ///
  /// The [glyph] is painted in [color] at [size], or at a per-glyph optical
  /// default when [size] is null. The [size] must be greater than zero.
  const CapsuleToastGlyphIcon({
    super.key,
    required this.glyph,
    required this.color,
    required this.theme,
    this.size,
  }) : assert(size == null || size > 0);

  /// Which shape to paint.
  ///
  /// [CapsuleToastGlyph.automatic] paints nothing; resolve it with
  /// [CapsuleToastGlyph.resolveFor] first.
  final CapsuleToastGlyph glyph;

  /// The stroke and fill color of the glyph.
  ///
  /// The loading glyph's track is painted in this color at 22% alpha.
  final Color color;

  /// The resolved theme supplying the optional glyph and spinner builders.
  final CapsuleToastThemeData theme;

  /// The logical width and height of the glyph canvas.
  ///
  /// If null, each glyph is painted at its own optical default. The reference
  /// sizes the shapes individually rather than normalising them: the check is
  /// the lightest shape so it can afford to be smallest, while the triangle
  /// and the signal arcs need the extra room to read at a glance.
  final double? size;
```

- [ ] **Step 3: Confirm diagnostics**

`debugFillProperties` should read exactly:

```dart
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<CapsuleToastGlyph>('glyph', glyph));
    properties.add(ColorProperty('color', color));
    properties.add(DoubleProperty('size', size, defaultValue: null));
  }
```

`glyph` and `color` are required and have no stable default, so they take no
`defaultValue`. There must be no `tickerEnabled` line left.

- [ ] **Step 4: Verify**

```bash
dart format lib
dart analyze
dart doc --dry-run
flutter test
```

Expected: analyzer clean, no dartdoc warnings about unresolved `[...]`
references, all tests pass. If `dart doc --dry-run` is unavailable in this
toolchain, skip it and rely on the analyzer.

- [ ] **Step 5: Commit**

```bash
git add lib/src/widgets/capsule_toast_glyph.dart
git commit -m "docs: give the glyph widget framework-depth dartdoc"
```

---

### Task 6: Release metadata

**Files:**
- Modify: `pubspec.yaml:7` (`version`)
- Modify: `README.md:24` (install snippet)
- Modify: `CHANGELOG.md` (new top section)

**Interfaces:**
- Consumes: the final public API from Tasks 1-3.
- Produces: nothing consumed by other tasks.

- [ ] **Step 1: Bump the version**

In `pubspec.yaml`, change `version: 0.2.0` to `version: 0.3.0`.

In `README.md` line 24, change `capsule_toast: ^0.2.0` to
`capsule_toast: ^0.3.0`.

- [ ] **Step 2: Add the changelog section**

Insert above the existing `## 0.2.0` heading:

```markdown
## 0.3.0

The capsule toast glyph widget now follows Flutter framework conventions.
Painted output is unchanged.

Breaking changes:

- `CapsuleToastGlyphWidget` is renamed to `CapsuleToastGlyphIcon`.
- `resolveCapsuleToastGlyph(glyph, type)` is replaced by the enum method
  `glyph.resolveFor(type)`.
- `capsuleToastGlyphSize(glyph)` is removed. `CapsuleToastGlyphIcon.size` is
  now optional; leave it null to paint a glyph at the same optical default
  that function returned.
- `CapsuleToastGlyphIcon.tickerEnabled` is removed. Wrap the widget in a
  `TickerMode` with `enabled` set to false to freeze the loading spinner.

Other changes:

- Added `CapsuleToastGlyphIcon.defaultAnimationDuration`, the duration of one
  full rotation of the loading spinner.
- The loading spinner's `AnimationController` is now created once for the
  widget's lifetime and started and stopped as the glyph changes, instead of
  being disposed and recreated.
```

- [ ] **Step 3: Verify the package is publishable**

```bash
dart analyze
flutter test
(cd example && flutter test)
flutter pub publish --dry-run
```

Expected: analyzer clean, all tests pass, and the dry run reports no errors.
Warnings about the git working tree being dirty are expected until the commit
below lands.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml README.md CHANGELOG.md
git commit -m "chore: release 0.3.0 with the restyled glyph widget"
```

---

## Final Verification

Run once after Task 6, from the repository root:

```bash
dart format --output=none --set-exit-if-changed lib test example
dart analyze
flutter test
(cd example && flutter test)
```

All four must succeed. In particular every golden in `test/goldens/` must match
without being re-recorded — that is the proof that a pure style change stayed
a pure style change.
