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

`CapsuleMotionController.show` also has to survive being called from a visible
state. It previously abandoned the lifecycle only when collapsing, so re-seeding
over a settled toast tripped the `begin` assertion; it now abandons from any
state that is not already hidden.

### 2. Expand and collapse run on the wrong spring

`expand` and `collapse` set `_usingInteractiveSpring = true`, and nothing ever
clears it. Every expand, collapse, and later resolution therefore runs at the
interactive spring's 320ms with 0.18 bounce.

The reference only appears to work that way. `expand` does retune to the
interactive spring — but the effect keyed on `dims` retunes straight back to
the width and height presets, and sets the new targets at the same moment:

```js
React.useEffect(() => {
  retune(S.w, reduced ? SPRINGS.reduced : SPRINGS.width);
  retune(S.h, reduced ? SPRINGS.reduced : SPRINGS.height);
  if (phase !== 'hidden' && phase !== 'collapsing') { S.w.t = dims.w; S.h.t = dims.h; }
}, [dims, reduced]);
```

Measuring always follows a mode change, so that effect always fires, and it
fires before the springs have travelled anywhere. The interactive spring is a
one-frame bridge; the expansion the designer actually tuned runs at 420ms /
0.16 on width and 400ms / 0.12 on height. Ours was quicker and springier than
intended — the felt difference.

Fix: `retarget` — the controller's equivalent of that effect — clears
`_usingInteractiveSpring`, and `_prepareContinuousContentChange` does the same
so a resolution cannot inherit an earlier expand's tuning.

Secondary: the layer estimated the expanded size as
`Size(current.width, max(current.height + 30, 80))` before the real one was
measured. Each mode's size is cached the first time it is laid out, so the
estimate only ever applied to the very first expand of a toast — and it aimed
the spring at a height no capsule was going to. Hold the current size instead
and let the measure land next frame.

An earlier draft measured both modes through offstage `CapsuleToastProbe`
render objects to remove that one-frame lag entirely. It was dropped: probing
means rendering every toast's content twice, which puts a second copy of every
title and action label in the widget tree. That breaks `find.text` for anyone
writing widget tests against this package — too high a price for one frame,
especially once the spring tuning turned out to be the real defect.

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

Updated: queue tests now name `enqueue` explicitly where they mean to queue,
the tap-toggle test reflects the true frame sequence of a first expand, and the
five affected goldens are regenerated.

New, each confirmed to fail against the unfixed code:

- `show replaces the active toast by default`.
- `compact action label is legible against the capsule`, under a light host
  theme — the condition that produced the near-black label.
- `loading spinner keeps turning after the capsule settles`, comparing two
  rasterisations of the settled capsule, paired with a static-glyph test that
  proves the comparison discriminates.
- `exit retracts content action-first, icon last`, sampled at 110ms where all
  four slots have started and none has finished.
- `tap toggles compact and expanded modes` gains a third toggle asserting the
  cached expanded size is reused exactly.

Known unrelated failure: `example/test/capsule_toast_lab_test.dart` overflows
the lab's own control panel at the 800x600 test surface. Present before this
work; not touched by it.
