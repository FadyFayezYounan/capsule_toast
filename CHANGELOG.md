## 0.2.0

Motion and chrome now track the reference design frame for frame.

- Replaced `Curves.easeOut` with the reference's exact cubic ease-out
  (`1 - (1 - t)³`) across the appearance, content reveal, retract, and exit
  fade envelopes. The Bézier approximation Flutter ships decelerates on a
  visibly slacker schedule.
- Fixed the leading icon so it emanates from the capsule centre and rides
  outward as the capsule widens. Travel is now derived from the measured
  target width instead of a fraction of the live width that was recomputed —
  and discarded — on every spring frame.
- Reworked swipe-to-dismiss: the exit now begins from wherever the finger
  released the capsule and carries a velocity-proportional kick, instead of
  springing back to rest and then rising 6 pt. The lifecycle envelope and the
  interactive drag are tracked separately and composed.
- Content stays pinned to the capsule centre while the capsule springs around
  it, so an event is revealed from the inside out rather than unrolling
  downward from the top edge.
- The capsule scales about its own centre during entrance.
- Content retract is now `1 - easeOut(t)`, mirroring the reveal, rather than
  `easeOut(1 - t)`.

Chrome fixes:

- Expanded action buttons hug their labels instead of stretching to the full
  capsule width.
- Added default action chrome: the expanded primary action is a solid light
  pill with dark text, the secondary is bare text, and the compact chip drops
  to 11.5 pt.
- Added `CapsuleToastThemeData.expandedTitleTextStyle` (14.5 pt) so expanded
  titles are no longer rendered at the compact size.
- Fixed `ButtonStyle` merge order so theme-supplied `primaryActionStyle`,
  `secondaryActionStyle`, and `compactActionStyle` are actually applied; they
  were previously overwritten by the built-in defaults.
- Exported `CapsuleToastGlyphWidget` and `resolveCapsuleToastGlyph` for custom
  content builders that want the same glyph shapes.

Also:

- Rebuilt the example into the full motion lab: live capsule in a phone
  canvas, status variants, transformations, replay with a 1× / 0.35× / 0.15×
  clock, reduced-motion and RTL adaptations, the annotated phase timeline, and
  a frozen component-state gallery.

## 0.1.0

- Initial release with structured and custom capsule content.
- Added interruptible spring motion, FIFO queueing, replacement, and loading
  resolution.
- Added touch, mouse, keyboard, RTL, reduced-motion, and accessibility support.
- Added themes, example lab, deterministic motion tests, and golden coverage.
