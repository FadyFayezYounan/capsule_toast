# Capsule Toast — cloud design parity

Bring the Flutter package to pixel and motion parity with the LifeOps Capsule
Toast prototype published at
`claude.ai/design/p/1c722c25-a682-455b-9fa8-d06d729fdac7`.

Reference sources: `LifeOps Capsule Toast.html`, `toast-capsule.jsx`, `theme.js`.

## What already matches

Verified identical between `toast-capsule.jsx` and the package, and therefore
out of scope:

- Surface tokens: `#161614` fill, `rgba(249,249,247,0.07)` border at 0.5px,
  `#F9F9F7` foreground, `rgba(249,249,247,0.62)` secondary, `rgba(…,0.10)` chip.
- Accents and tints for all seven types.
- Every spring: width `0.42/0.16`, height `0.40/0.12`, 28ms height lead,
  interactive `0.32/0.18`, exit `0.30/0`, reduced `0.24/0`.
- Appearance envelope: 140ms ease-out, seed scale 0.92, seed offset -8.
- Exit schedule: retarget to seed at 160ms, fade from 200ms over 140ms,
  complete at 340ms.
- Slot reveal stagger: icon 0, title 30ms, message 60ms, action 90ms over 220ms.
- Icon travel from capsule centre, with opacity leading travel by 1.6×.
- Geometry: 84×34 seed, 340 max width, radius `min(h/2, 34)`, all padding,
  spacing, and type scale for both modes.

## Defects and fixes

### 1. Replace is the default, and re-seeds

`CapsuleToastManager.show` and `CapsuleToastCoordinator.show` both default to
`CapsuleToastQueuePolicy.replace`. The interface default alone is insufficient
because `CapsuleToastCoordinator` redeclares the parameter, and callers holding
the concrete type bind to that declaration.

In `_syncMotion`, a token change while the capsule is visible currently calls
`_motion.replace()`, which preserves geometry and velocity. The reference
instead swaps item identity, which re-runs `useEffect([item])` and resets the
springs to the seed at opacity 0. The layer will therefore always call
`_motion.show()` on a token change.

`resolve()` — the loading-to-success path — keeps the continuous morph. The two
transitions read differently in the reference and must read differently here.

### 2. Expand and collapse aim at a guessed target

`capsule_toast_layer.dart` guesses the expanded size as
`Size(current.width, max(current.height + 30, 80))` when `_expandedSize` is
still null, because sizes are only reported by `CapsuleToastMeasure` from a
post-frame callback on the live capsule. The spring therefore travels toward a
wrong target — same width, arbitrary height — for one to two frames before
re-aiming. This is the cause of the expand and collapse transitions feeling
wrong.

The reference keeps a hidden measurer rendering the same content at natural
size, so `dims` is always known before a transition starts.

Fix: add `CapsuleToastProbe`, a `SingleChildRenderObjectWidget` whose render
object lays the child out at the capsule's max width with unbounded height,
reports the natural size, then reports zero size itself and paints nothing.
Being `sizedByParent` with a constant size makes it a relayout boundary, so it
costs one layout per content change rather than one per spring tick.

The layer mounts two probes, compact and expanded, outside
`CapsuleToastAnimationScope` so slot transforms do not apply. Each probe is
wrapped in `ExcludeSemantics`, `ExcludeFocus`, and `TickerMode(enabled: false)`
so it cannot announce, take focus, or start a second spinner ticker.

With both sizes always populated, the guess is deleted and expand and collapse
retarget to the true size on the frame the gesture lands.

### 3. Exit content never retracts

`CapsuleMotionController.dismiss()` sets `_contentEnvelopeActive = true` but
does not reset `_contentElapsed`. The first `_advanceContent(revealing: false)`
therefore sees an elapsed time past the end of the retract interval and drops
every slot to opacity 0 in a single frame.

Fix: reset `_contentElapsed` in `dismiss()`. Separately, the retract total is
hardcoded to 160ms while the slowest slot finishes at 230ms (icon delay 100ms
plus 130ms interval); correct it to 230ms so the icon is not cut off at 46% of
its retract.

The staggered exit delays in `CapsuleToastAnimatedSlot._exitDelays` already
match the reference and start playing once the clock is correct.

### 4. Loading spinner is frozen

`_CapsuleToastGlyphWidgetState` builds an `AnimationController` and calls
`repeat()`, but nothing listens to it, so no rebuild occurs and the painter's
`rotation` is always 0.

Fix: pass the controller to `CustomPaint` as `painter.repaint`, so ticks drive
repaint without rebuilding the widget subtree.

Spinner geometry also diverges. Reference: radius 7.2, stroke width 2, track at
0.22 alpha, head a quarter turn starting at 12 o'clock with a round cap, 850ms
linear. Package: stroke width 1.6, sweep 0.65π, starting at 3 o'clock.

### 5. Glyphs are oversized and imprecise

Glyphs are painted at a flat `size: 20`. The reference draws the same 20-unit
viewBox at a per-kind size inside the identical 34px tinted circle: success 15,
info 16, warning 17, error 16, offline 17, spinner 18. Package glyphs are
therefore 18–33% too large.

Stroke widths are flat 1.6 against the reference's 1.7 to 2.3, varying per path
within a glyph. Additionally:

- `warning` is missing its exclamation stem entirely (`M10 7.9v3.5`).
- `info`'s dot and stem sit roughly 3px low; the reference places the dot at
  y 6.2 above a stem spanning y 9 to 14.
- `connectivity` is missing the dot at (10, 16.4).

### 6. Compact action chip is unreadable

`compactActionStyle` sets a `textStyle` carrying only size and weight. With no
colour, `Text` falls through to the ambient `DefaultTextStyle`, which the layer
seeds from the app's `bodyMedium` — near-black in a light Material theme, on a
`#161614` capsule.

Fix: set the colour explicitly to `#F9F9F7`, matching `CAPSULE.fg`.

### 7. Shadow is slightly too soft

CSS defines `blur-radius = 2σ`; Flutter's `BoxShadow` uses
`σ = 0.57735 · blurRadius + 0.5`. Copying the CSS radii verbatim over-blurs.
`6px` maps to a Flutter blur radius of ~4.33 and `30px` to ~25.1.

## Testing

The suites under `test/motion/`, `test/widgets/`, and
`test/manager/` cover exit motion, content layout, goldens, and queue policy.
Expected updates: exit retract timing, glyph sizes, the replace default, and
regenerated goldens. New coverage for the probes reporting both mode sizes
before a transition, and for the spinner advancing over time.
