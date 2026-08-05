## Unreleased

- `CapsuleToastData.expansionPolicy` locks a toast to
  `CapsuleToastExpansionPolicy.compactOnly` or `.expandedOnly`, disabling
  tap, long-press, and handle-driven mode toggling for toasts whose
  expanded or compact layout has no meaningful content. Defaults to
  `.adaptive`, which is the existing toggle-both behavior — fully backward
  compatible.

## 1.0.0

Initial release.

- `CapsuleToastHost` installs a capsule layer over any subtree. Hosts nest
  independently, so the package needs no global singleton or navigator key.
- Top-centre capsules morph between compact and expanded layouts on
  interruptible damped-spring motion, with content pinned to the capsule centre
  as the capsule springs around it.
- `CapsuleToastType` covers success, information, warning, error, loading,
  neutral, and custom content; compact and expanded builders take over layout
  per mode.
- `CapsuleToastQueuePolicy` selects replace, FIFO enqueue, or clear-and-show.
- `CapsuleToastHandle` exposes live expand, collapse, resolve, and dismiss
  commands, and completes with a `CapsuleToastResult` carrying a
  `CapsuleToastDismissReason`.
- Primary, secondary, and compact actions render with themeable button chrome.
- `CapsuleToastThemeData` and `CapsuleToastMotionTheme` configure appearance and
  motion. Values resolve from the app brightness, then `ThemeData.extensions`,
  then the nearest `CapsuleToastTheme`, then per-toast overrides.
- Light and dark appearances share identical motion, geometry, layout, and
  typography; the dark appearance adds an inner rim highlight.
- `CapsuleToastGlyphIcon` paints the status glyphs and the loading spinner for
  custom content builders.
- Touch, mouse, keyboard, and RTL input, plus safe areas, large text, and
  screen-reader semantics.
- Velocity-aware swipe-to-dismiss that exits from wherever the finger released
  the capsule.
- `CapsuleToastReducedMotionPolicy` and `CapsuleToastHapticPolicy` adapt motion
  and feedback to platform settings.
