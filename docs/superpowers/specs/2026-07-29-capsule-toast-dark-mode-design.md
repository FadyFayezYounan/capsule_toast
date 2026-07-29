# Capsule Toast — dark mode support

**Date:** 2026-07-29
**Status:** Approved

## Goal

`capsule_toast` currently ships one appearance: a near-black capsule tuned to sit
on a warm off-white app. In a dark app that capsule sinks into the background.

Add a second appearance so that when the host app is in dark mode the capsule
lifts one step *above* the app surface instead, exactly as specified by the
reference prototype. Nothing else changes — geometry, timings, springs, queue
behaviour and layout are shared between the two appearances.

## Non-goals

- No changes to motion, geometry, layout, the queue, or the public widget API
  beyond the theme tokens described below.
- No new appearance beyond the two the reference defines.
- No redesign of any colour. Every value is transcribed from the reference.

## Source of truth

The cloud design project `1c722c25-a682-455b-9fa8-d06d729fdac7`
("LifeOps Capsule Toast copy.html"). Two files carry the specification:

- `toast-capsule.jsx` — `CAPSULE_LIGHT` / `CAPSULE_DARK` surface tokens, the
  `TONES` status palette, and `toneTint(tone, boost)`.
- `toast-lab.jsx` — `ModeSpecTable`, the prose summary of the delta.

`ModeSpecTable` states the delta as:

| | Light app | Dark app |
|---|---|---|
| Surface | `#161614` · below app | `#26231E` · one step above app |
| Rim | 0.5px @ 7% | 0.5px @ 15% + inset top highlight 10% |
| Shadow | warm, 30px spread @ 16% | neutral, 36px spread @ 42% |
| Status tint | alpha 0.16 | alpha ×1.35 — holds on lighter surface |
| Text | `#F9F9F7` / 62% | `#F7F4EE` / 66% |
| Motion | identical | identical — springs are appearance-agnostic |

The existing `CapsuleToastThemeData.fallback()` is already an exact transcription
of the light column, so this work adds the dark column and a way to choose
between them.

### Conversion conventions

Both conventions are already established in `capsule_toast_theme_data.dart` and
are reused unchanged:

- **Alpha:** CSS fractional alpha × 255, rounded to nearest. (Existing evidence:
  `0.62 → 0x9E`, `0.07 → 0x12`, `0.10 → 0x1A`, `0.16 → 0x29`, `0.18 → 0x2E`,
  `0.08 → 0x14`.)
- **Blur:** CSS defines blur radius as twice the Gaussian sigma; Flutter's sigma
  is `0.57735 * radius + 0.5`. So a CSS blur `B` becomes a Flutter blur radius
  `R = (B / 2 - 0.5) / 0.57735`. (Existing evidence: CSS `6px → 4.33`,
  CSS `30px → 25.1`.)

## Token table

Derived from `CAPSULE_DARK` in `toast-capsule.jsx`. The light column is what
`fallback()` returns today and does not change.

| `CapsuleToastThemeData` field | Light | Dark | Reference |
|---|---|---|---|
| `surfaceColor` | `0xFF161614` | `0xFF26231E` | `CAPSULE_*.surface` |
| `foregroundColor` | `0xFFF9F9F7` | `0xFFF7F4EE` | `CAPSULE_*.fg` |
| `secondaryForegroundColor` | `0x9EF9F9F7` | `0xA8F7F4EE` | `CAPSULE_*.fg2` (0.62 → 0.66) |
| `borderColor` | `0x12F9F9F7` | `0x26F9F6F0` | `CAPSULE_*.border` (0.07 → 0.15) |
| `borderWidth` | `0.5` | `0.5` | unchanged |
| `actionSurfaceColor` | `0x1AF9F9F7` | `0x21F9F6F0` | `CAPSULE_*.chip` (0.10 → 0.13) |
| `innerHighlightColor` *(new)* | `null` | `0x1AFFFFFF` | `inset 0 0.5px 0 rgba(255,255,255,0.10)` |
| `innerHighlightWidth` *(new)* | `null` | `0.5` | same |
| primary action foreground | `0xFF1A1714` | `0xFF211E19` | `CAPSULE_*.onFg` |
| `accents` | — | **identical to light** | `TONES` is appearance-agnostic |

### Shadows

Light (unchanged): `BoxShadow(offset (0,2), blur 4.33, 0x29140E06)` and
`BoxShadow(offset (0,10), blur 25.1, 0x29140E06)`.

Dark, from
`0 2px 8px rgba(0,0,0,0.46), 0 14px 36px rgba(0,0,0,0.42)`:

- `BoxShadow(offset (0, 2), blurRadius 6.06, color 0x75000000)`
- `BoxShadow(offset (0, 14), blurRadius 30.31, color 0x6B000000)`

The third CSS entry, `inset 0 0.5px 0 rgba(255,255,255,0.10)`, is not a
`BoxShadow` — see "Inset top highlight" below.

### Tints

`toneTint` multiplies each tone's alpha by the surface's `tintBoost`, which is
`1` for light and `1.35` for dark. The RGB triples are unchanged.

| Tone | RGB | Light alpha → hex | Dark alpha (×1.35) → hex |
|---|---|---|---|
| success | `95A584` | 0.16 → `0x29` | 0.216 → `0x37` |
| information | `8AA4BD` | 0.16 → `0x29` | 0.216 → `0x37` |
| warning | `D89858` | 0.16 → `0x29` | 0.216 → `0x37` |
| error | `D67D65` | 0.18 → `0x2E` | 0.243 → `0x3E` |
| loading / neutral / custom | `F9F9F7` | 0.08 → `0x14` | 0.108 → `0x1C` |

Dark tints in full: `0x3795A584`, `0x378AA4BD`, `0x37D89858`, `0x3ED67D65`,
`0x1CF9F9F7`.

### Accents are shared

`TONES[*].fg` does not vary with appearance in the reference — only tint alpha
does. So `CapsuleToastAccents` is byte-identical between the two fallbacks:
`0xFFB9CCA8`, `0xFFAFC4D7`, `0xFFE5BE85`, `0xFFE8A695`, and `0xC7F9F9F7` for
loading / neutral / custom. This is deliberate, not an oversight.

## Architecture

### 1. `CapsuleToastThemeData` — one factory, two palettes

`fallback()` becomes:

```dart
factory CapsuleToastThemeData.fallback([
  Brightness brightness = Brightness.light,
])
```

`brightness` means *the host app's brightness*, matching
`Theme.of(context).brightness` — so `Brightness.light` selects the dark capsule
tuned for a light app, which is exactly what `fallback()` returns today. The
default argument keeps every existing call site (README, tests, example)
compiling and behaving identically.

The factory body must not be duplicated. A private, immutable
`_CapsuleToastPalette` holds only the brightness-varying tokens, with `light`
and `dark` constants:

- `surface`, `foreground`, `secondaryForeground`, `border`, `actionSurface`,
  `onForeground`
- `innerHighlight` (nullable), `innerHighlightWidth` (nullable)
- `tints`
- `shadows`

Everything else — accents, typography, padding, spacing, sizes, safe-area
behaviour — stays as shared constants in the single factory body.

Critically, the three `ButtonStyle`s (`compactActionStyle`,
`primaryActionStyle`, `secondaryActionStyle`) currently hardcode
`0xFFF9F9F7`, `0xFF1A1714` and `0x9EF9F9F7`. They must be derived from the
palette's `foreground` / `onForeground` / `secondaryForeground`, or dark-mode
action buttons will silently stay light.

### 2. Two new public fields

`innerHighlightColor` (`Color?`) and `innerHighlightWidth` (`double?`), named to
mirror the existing `borderColor` / `borderWidth` pair. Both are threaded
through `copyWith`, `merge`, `lerp`, `debugFillProperties`, `operator ==` and
`hashCode` like every other token. `innerHighlightWidth` carries the same
non-negative assertion style as `borderWidth`.

### 3. `CapsuleToastTheme.resolve` — ambient brightness picks the base

```dart
static CapsuleToastThemeData resolve(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  CapsuleToastThemeData resolved =
      CapsuleToastThemeData.fallback(theme.brightness);
  // …merge ThemeData extension, then the inherited CapsuleToastTheme,
  //   exactly as today.
}
```

The merge order is untouched. `resolveMotion` is not touched at all — springs
are appearance-agnostic per the reference.

This is the only mechanism. `CapsuleToastHost` is installed via
`MaterialApp.builder`, so `Theme.of(context)` inside `CapsuleToastLayer`
resolves the active `ThemeData` and reports the correct brightness for both
`MaterialApp(theme:, darkTheme:)` and a manually swapped `ThemeData`.

### 4. Customisation, three routes, all unchanged

```dart
// 1. Automatic — nothing to do.
MaterialApp(theme: lightTheme, darkTheme: darkTheme)

// 2. Customise one mode: put an extension on that ThemeData.
ThemeData.dark().copyWith(
  extensions: <ThemeExtension<dynamic>>[
    CapsuleToastThemeData(surfaceColor: myDarkSurface),
  ],
)

// 3. Pin an appearance regardless of the app.
ThemeData.dark().copyWith(
  extensions: <ThemeExtension<dynamic>>[
    CapsuleToastThemeData.fallback(Brightness.light),
  ],
)
```

Route 3 works without any new API precisely because `fallback` returns a fully
populated object and `merge` takes every non-null field — this is why the
`brightness` argument is made public rather than kept internal.

### 5. Inset top highlight

`BoxDecoration` has no inset shadow, so this is painted.
`_CapsuleToastSurfaceBody` inserts a `CustomPaint` between its `DecoratedBox`
and its `ClipRRect`, **only when `innerHighlightColor != null`** — light mode
allocates and paints nothing.

The painter reproduces CSS's actual inset-shadow geometry rather than
approximating it with a gradient. For an inset shadow with offset `(0, w)`, zero
blur and zero spread, the lit region is the padding-box shape minus that same
shape shifted down by `w`: a `w`-tall sliver following the top curve and
tapering to nothing at the sides.

```dart
final RRect inner = /* box RRect deflated by borderWidth */;
final Path sliver = Path.combine(
  PathOperation.difference,
  Path()..addRRect(inner),
  Path()..addRRect(inner.shift(Offset(0, width))),
);
canvas.drawPath(sliver, Paint()..color = color..isAntiAlias = true);
```

Deflating by `borderWidth` keeps the highlight inside the border rather than
painting on top of it and doubling the rim. `shouldRepaint` compares colour,
width, border width and radius.

The `CustomPaint` carries a stable key,
`const ValueKey<String>('capsule_toast.highlight')`, exported alongside
`capsuleSurfaceKey` so tests can assert its presence without matching on
`CustomPaint` by type — the glyph painters would make that ambiguous.

### 6. Theme-animation caveat (accepted)

When an app animates between two `ThemeData`s, `ThemeData.lerp` flips
`brightness` at `t = 0.5`, so fallback-supplied colours cross over at the
midpoint instead of interpolating. Tokens the user supplies through the
extension still lerp smoothly, because `ThemeExtension.lerp` is unaffected.

This is accepted, not fixed: it matches how Material's own brightness-derived
defaults behave, and the alternative (lerping two full fallback objects on every
build) costs more than the artefact is worth.

## Testing

### `test/theme/`

1. `fallback(Brightness.dark)` returns every token in the table above —
   surface, foreground, secondary foreground, border, action surface, inner
   highlight, the five tints, and both shadows.
2. `fallback(Brightness.dark).accents == fallback(Brightness.light).accents`,
   pinning the "accents are shared" decision so a future edit has to be
   deliberate.
3. Dark tint alpha ≈ light tint alpha × 1.35 for every tone. This guards the
   *rule*, not just the transcribed numbers.
4. `resolve` returns the dark base under a dark `Theme` and the light base under
   a light one.
5. A `ThemeData` extension override still beats the dark base.
6. `CapsuleToastThemeData.fallback(Brightness.light)` installed as an extension
   on a dark `ThemeData` pins the light appearance.
7. `fallback()` with no argument is identical to `fallback(Brightness.light)` —
   back-compatibility.

### `test/widgets/`

8. Under a dark theme the painted decoration (`capsule_toast.decoration`)
   carries `0xFF26231E` and a `0x26F9F6F0` border; under a light theme it
   carries today's values.
9. The highlight painter, found by `capsule_toast.highlight`, is in the tree in
   dark mode and absent in light mode.

### Goldens

10. One new golden, `capsule_toast_dark_states.png`, mirroring the existing
    compact-states golden but under a dark theme.

## Example lab

The reference lab exposes a **Light app / Dark app** segmented control beneath
the phone; the Flutter lab gains the same control.

`toast-lab.jsx` is explicit that the lab chrome always renders in the light
palette so it stays a neutral frame around the phone, whichever appearance is
being previewed. That is preserved: only the phone screen and the `Theme` around
the hosted capsule switch.

Dark app-surface tokens come from `theme-dark.js` and are added to `Lab`:

| Token | Value |
|---|---|
| app background | `#20201E` |
| card / row | `#2C2C2A` |
| hairline | `rgba(249,249,247,0.10)` |
| primary text | `#F9F9F7` |
| muted text | `#9A9A94` |

The in-phone demo dock also picks up its dark variant from `DemoDock` in
`toast-lab.jsx` (surface `rgba(44,40,34,0.92)`, rim `rgba(249,246,240,0.14)`,
chip `rgba(249,246,240,0.13)`, shadow `0 10px 30px rgba(0,0,0,0.5)`), so the
whole phone canvas reads as one appearance.

## Documentation

- **README** — a "Dark mode" subsection under **Visual theme**, covering the
  three customisation routes above.
- **CHANGELOG** — a `0.4.0` entry: dark mode support, the two new theme fields,
  and the `fallback` signature gaining an optional `Brightness`.

## Acceptance

- A `MaterialApp` with `theme:` and `darkTheme:` shows the light-app capsule and
  the dark-app capsule respectively, with no package-specific configuration.
- Every dark token matches the table above exactly.
- Motion, geometry and layout are byte-identical between appearances.
- Existing call sites of `CapsuleToastThemeData.fallback()` are unchanged in
  both signature and behaviour.
- `dart analyze` is clean and the full test suite passes.
