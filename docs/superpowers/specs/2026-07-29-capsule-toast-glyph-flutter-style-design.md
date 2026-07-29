# Capsule Toast Glyph — Flutter Framework Code Style Design

## Context

`lib/src/widgets/capsule_toast_glyph.dart` is functionally complete and its
visual output is approved. Nothing in this design changes a single painted
pixel. The goal is that the file read like framework source: specifically like
`packages/flutter/lib/src/material/progress_indicator.dart`, which is the
reference for file layout, naming, constant handling, animation lifecycle,
defaults placement, and documentation depth.

The reference is a style model, not a template. `CircularProgressIndicator`
resolves its own defaults through a
`widget.x ?? theme.x ?? defaults.x!` cascade rooted in
`ProgressIndicatorTheme.of(context)`. This package deliberately does not do
that: every widget under `lib/src/widgets/` receives an already-resolved
`CapsuleToastThemeData` as a constructor parameter, because toasts render in an
overlay where the inherited theme is not reliably reachable. That convention is
preserved. Adopting the context lookup for this one widget would make the
package less internally consistent, not more.

## Scope

In scope: `lib/src/widgets/capsule_toast_glyph.dart`, the `CapsuleToastGlyph`
enum in `lib/src/model/capsule_toast_types.dart`, the two call sites, the
barrel export, the glyph tests, and the release metadata
(`CHANGELOG.md`, `pubspec.yaml`, `README.md`).

Out of scope: the painted geometry, the theme plumbing convention described
above, the surrounding tinted-circle container in
`capsule_toast_content.dart`, and any other widget in the package.

## Public API changes

The package is at `0.2.0`. These are breaking changes, accepted deliberately;
the blast radius is two call sites and one barrel export.

| Before | After |
| --- | --- |
| `CapsuleToastGlyphWidget` | `CapsuleToastGlyphIcon` |
| `resolveCapsuleToastGlyph(glyph, type)` | `glyph.resolveFor(type)` |
| `capsuleToastGlyphSize(glyph)` | removed; resolved internally |
| `required double size` | `double? size` |
| `bool tickerEnabled = true` | removed; use `TickerMode` |
| — | `CapsuleToastGlyphIcon.defaultAnimationDuration` |

The widget is named `CapsuleToastGlyphIcon` because the enum already owns
`CapsuleToastGlyph`. This mirrors Flutter's own `Icon` / `IconData` pairing and
leaves every `CapsuleToastGlyph.success` reference — including the user-facing
`CapsuleToastData(glyph:)` argument — untouched.

`resolveFor` becomes a method on the enum, declared beside it in
`capsule_toast_types.dart`. It is reachable through the existing enum export,
so the barrel narrows to `show CapsuleToastGlyphIcon`.

`size` becomes nullable. When null the widget resolves the per-glyph default
itself, exactly as `CircularProgressIndicator` resolves `strokeWidth` and
`constraints`. This removes the last cross-file top-level function.

## File layout

Reordered to match the reference's silhouette — private constants, painter,
public widget, state, defaults:

```dart
// Copyright header

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/capsule_toast_types.dart';
import '../theme/capsule_toast_theme_data.dart';

const int _kGlyphSpinnerDuration = 850;
const double _kGlyphCanvasSize = 20;

class _CapsuleToastGlyphPainter extends CustomPainter { ... }

/// Full class dartdoc.
class CapsuleToastGlyphIcon extends StatefulWidget { ... }

class _CapsuleToastGlyphIconState extends State<CapsuleToastGlyphIcon>
    with SingleTickerProviderStateMixin { ... }

// Hand coded defaults transcribed from the reference SVGs.
class _CapsuleToastGlyphIconDefaults { ... }
```

`_canvas` moves off the painter and becomes the top-level
`_kGlyphCanvasSize`, because both the painter and the size defaults reason
about the same 20-unit grid.

`_CapsuleToastGlyphIconDefaults` is a class rather than a bare function so the
file ends in the same clearly marked defaults section the reference does. It
holds one member:

```dart
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

The values are transcribed unchanged from today's `capsuleToastGlyphSize`. The
existing prose explaining why each glyph is sized individually rather than
normalised moves onto this class.

## Animation lifecycle

The State adopts `_CircularProgressIndicatorState`'s exact shape:

```dart
class _CapsuleToastGlyphIconState extends State<CapsuleToastGlyphIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = AnimationController(
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
    _internalController.dispose();
    super.dispose();
  }

  void _updateControllerAnimatingStatus() { ... }
}
```

The controller is constructed once and lives for the State's lifetime.
`_updateControllerAnimatingStatus` starts and stops it against the same
condition that governs whether this widget paints a spinner at all:

```dart
void _updateControllerAnimatingStatus() {
  final bool animating =
      widget.glyph == CapsuleToastGlyph.loading &&
      widget.theme.spinnerBuilder == null;
  if (animating && !_internalController.isAnimating) {
    _internalController.repeat();
  } else if (!animating && _internalController.isAnimating) {
    _internalController.stop();
  }
}
```

The `spinnerBuilder == null` term is load-bearing. When the theme supplies a
custom spinner the widget returns that builder's output and never paints the
arc, so leaving the controller repeating would burn a frame callback for
nothing — which is exactly what the existing "custom loading spinner does not
start the built-in ticker" test asserts against.

Because the controller is never disposed and
recreated, the State returns to `SingleTickerProviderStateMixin`, and the
six-line comment explaining why `TickerProviderStateMixin` was required is
deleted rather than rewritten.

`covariant` is dropped from the `didUpdateWidget` parameter; the reference does
not use it and the type is already exact.

`tickerEnabled` is removed in favour of `TickerMode`, Flutter's own mechanism
for the same job. Both `SingleTickerProviderStateMixin` and the
`TickerProviderStateMixin` in use today mute the tickers they hand out
according to the ambient `TickerMode`, and a muted ticker never schedules a
frame callback, so a `TickerMode(enabled: false)` ancestor already produces the
frozen spinner the example needs. `tickerEnabled` is therefore not carrying
behavior the framework lacks — it only avoids constructing the controller at
all — and removing it is behavior-preserving rather than a swap of one
mechanism for another.

`_kGlyphSpinnerDuration` is surfaced publicly:

```dart
/// The default duration for one full rotation of the loading spinner.
static const Duration defaultAnimationDuration =
    Duration(milliseconds: _kGlyphSpinnerDuration);
```

No `controller` property is added. `CircularProgressIndicator` exposes one so
that several indicators can share an animation source; nothing in this package
displays more than one spinner at a time, so it would be an untested public
property serving a hypothetical.

## Painter

One painter, decomposed into per-glyph private methods. `paint()` establishes
the canvas scale and switches to `_paintSuccess(canvas)`,
`_paintInformation(canvas)`, `_paintWarning(canvas)`, `_paintError(canvas)`,
`_paintConnectivity(canvas)`, `_paintNeutral(canvas)`, and
`_paintLoading(canvas)`. `CapsuleToastGlyph.automatic` remains a no-op case.

Each method keeps the SVG-provenance comment currently sitting above its
switch case — for example `// M4.2 10.6l3.6 3.6L15.8 6 — stroke 2.3` — since
those comments are the record of where the numbers came from. Per-path stroke
widths stay inline beside the paths they belong to for the same reason; the
reference also varies stroke per path rather than hoisting a shared value.

The painter continues to pass `super(repaint: rotation)`. That wiring is what
makes the spinner repaint and must survive unchanged.

`rotation` becomes non-nullable `Animation<double>`. It was nullable only
because the old lifecycle disposed the controller whenever the glyph left
`loading`; with the controller alive for the State's whole lifetime there is
never a null to model, and the `?? 0` fallback in the loading case goes away.
A painter carrying a field that some modes ignore is in-idiom:
`_CircularProgressIndicatorPainter` holds non-nullable `headValue`,
`tailValue`, `offsetValue`, and `rotationValue` and documents at its call site
that they are ignored when `value` is non-null.

Splitting into separate static and animated painters was considered and
rejected: it duplicates the canvas-scale setup for no behavioral gain.

The `build` method's comment about the spinner repainting off the controller
moves onto the `rotation` field's dartdoc, where the reference places that kind
of remark.

`shouldRepaint` continues to compare `glyph`, `color`, and `rotation`.

## Documentation

Framework-depth dartdoc:

- A class-level block on `CapsuleToastGlyphIcon` written in the reference's
  register, covering the automatic-versus-explicit glyph distinction and the
  animated-versus-static distinction.
- Every public member documented, including `size`'s null-means-default
  behavior and `defaultAnimationDuration`.
- A `See also:` list pointing at `CapsuleToastGlyph`,
  `CapsuleToastThemeData.glyphBuilder`, `CapsuleToastThemeData.spinnerBuilder`,
  and `CircularProgressIndicator`.
- `resolveFor` documented on the enum.

No `{@tool dartpad}` blocks: they reference an `examples/api/` layout this
package does not have. No `{@template}` or `{@macro}`: there is one widget and
no documentation to share.

`debugFillProperties` is retained and gains a `DoubleProperty` for `size`.
`tickerEnabled`'s property is removed with the field.

## Call sites

`lib/src/widgets/capsule_toast_content.dart` collapses its resolve-then-size
two-step:

```dart
icon = CapsuleToastGlyphIcon(
  glyph: data.glyph.resolveFor(data.type),
  color: accent,
  theme: theme,
);
```

`example/lib/lab/lab_specimens.dart` replaces `tickerEnabled: spinning` with a
`TickerMode(enabled: spinning)` wrapper around the `CapsuleToastGlyphIcon`. Its
explicit `size: 20` is retained — the specimen gallery deliberately draws every
glyph at one size rather than at each glyph's optical default.

## Testing

The `ValueKey<String>('capsule.<glyph>.glyph')` on the sized box is unchanged.
`test/widgets/capsule_toast_glyph_test.dart` locates the spinner through it, so
its three existing tests need only the renamed symbol, and their pixel-diff
assertions continue to prove the spinner turns and the static glyphs do not.

Tests are added in two places. `test/model/capsule_toast_types_test.dart` gains
coverage of `resolveFor` across every `CapsuleToastType`, including that it
never returns `automatic` and that it passes an explicit glyph through
unchanged.

`test/widgets/capsule_toast_glyph_test.dart` gains four characterization tests
covering the size default and the animation mechanism: that a null `size`
paints at the per-glyph optical default and an explicit `size` overrides it;
that a `TickerMode(enabled: false)` ancestor leaves
`tester.binding.transientCallbackCount` at zero while an enabled one leaves it
at one; and that a glyph element reused across a loading → success → loading
sequence keeps animating without throwing.

The last of these is the important one. It is the scenario the deleted
`TickerProviderStateMixin` comment described, and it is what proves the return
to `SingleTickerProviderStateMixin` is safe. Because the current mixin already
honours `TickerMode`, these tests pass both before and after the refactor;
they are written and committed ahead of it as a regression net, not as failing
tests.

`test/public_api_test.dart` does not reference any glyph symbol and needs no
change.

## Verification

- `dart analyze` reports no issues.
- `flutter test` passes, including the golden-diff spinner tests.

## Release metadata

The renames and removals are breaking, so the package moves to `0.3.0`:
`pubspec.yaml`'s `version`, the `capsule_toast: ^0.2.0` install snippet on
line 24 of `README.md`, and a new `## 0.3.0` heading in `CHANGELOG.md`
listing each row of the public API table above with its migration.
