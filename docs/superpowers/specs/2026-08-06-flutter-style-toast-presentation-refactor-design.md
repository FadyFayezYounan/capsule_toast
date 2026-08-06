# Flutter-Style Toast Presentation Refactor Design

Date: 2026-08-06
Status: Approved design

## Summary

Refactor the package's private host and presentation implementation toward
Flutter framework conventions without changing its public API, observable
behavior, visuals, motion, or custom-content capabilities.

`CapsuleToastHost` will retain one lifetime-scoped `OverlayEntry`. The entry is
presentation infrastructure, not a per-toast lifecycle mechanism, and remains
necessary because caller-provided toast widgets may require an `Overlay`
ancestor for tooltips, popup menus, and selection controls.

The host's general-purpose `Stack` and the layer's `Positioned`-based placement
will be replaced by explicit `CustomMultiChildLayout` delegates. The oversized
`CapsuleToastLayer` will be separated into focused layout, presentation,
motion-synchronization, and interaction responsibilities.

## Goals

- Preserve the current public API and all observable behavior.
- Make ownership and data flow resemble Flutter framework code in principle.
- Give host composition and toast placement explicit layout delegates.
- Keep one stable rendered capsule across lifecycle and queue transitions.
- Split the current presentation layer into independently understandable units.
- Preserve support for arbitrary custom toast content that uses
  `Overlay.of(context)`.
- Keep application content isolated from toast animation rebuilds.

## Non-goals

- Removing all use of `OverlayEntry`.
- Copying `ScaffoldMessenger` registration machinery literally.
- Adding a public outlet, scaffold, controller, or installation requirement.
- Changing queue policy, lifecycle, animation tuning, placement, visuals,
  semantics, gestures, focus behavior, or theme resolution.
- Adding bottom, corner, or arbitrary toast placement.
- Performing unrelated cleanup or public API redesign.

## Architectural Decision

The package will use a stable, presentation-only overlay combined with focused
multi-child layout delegates.

A direct `CustomMultiChildLayout` with no overlay cannot preserve the current
custom-content contract under the documented `MaterialApp.builder`
installation. The host is an ancestor and sibling of the application's
`Navigator`, so the toast would not inherit the Navigator's overlay. Widgets
such as `Tooltip` could then fail with "No Overlay widget found."

Flutter's `ScaffoldMessenger` avoids that issue because registered `Scaffold`
widgets are mounted inside Navigator overlay entries. Reproducing that shape
would require a new descendant outlet on every route, registration and root
selection rules, and a changed installation contract. The package has exactly
one presentation outlet per host, so that machinery would add complexity
without serving a current requirement.

The retained entry will therefore be treated as a stable presentation root. It
will never be inserted, removed, or replaced in response to showing,
dismissing, replacing, resolving, or promoting a toast.

## Widget Tree

The target structure is:

```text
CapsuleToastHost
└── _CapsuleToastScope
    └── CustomMultiChildLayout
        ├── body: application child
        └── presentation: dedicated Overlay
            └── stable OverlayEntry
                └── CapsuleToastViewport
                    └── CustomMultiChildLayout
                        └── toast: presentation widget
```

The host layout replaces the current `Stack`. Its body and presentation slots
both receive tight host constraints, and the presentation slot paints after the
body.

The viewport layout replaces the current `Positioned`, `Padding`, and `Align`
placement chain. It constrains one toast child using the available width,
horizontal inset, maximum width, safe-area inset, and vertical offset, then
positions that child at top-center.

Animation translation, opacity, and scale remain inside the toast presentation
because they are paint effects rather than structural host placement.

## Component Boundaries

### `CapsuleToastHost`

The host remains responsible for creating, updating, and disposing:

- `CapsuleToastCoordinator`.
- `CapsuleMotionController`.
- The ticker provider.
- One lifetime-scoped presentation overlay entry.

It continues to expose only the narrow `CapsuleToastManager` through the
private inherited scope.

### Host Layout Delegate

A private host delegate owns only body and presentation slot measurement,
positioning, and paint order. It has no queue, animation, gesture, or theme
policy.

### `CapsuleToastViewport`

The viewport resolves placement inputs from `MediaQuery` and the visual theme,
then configures the toast layout delegate. It does not own active-record or
interaction state.

### Toast Layout Delegate

A private toast delegate:

- Handles the toast slot being absent.
- Computes non-negative available dimensions.
- Applies horizontal inset and maximum-width constraints.
- Positions the laid-out toast at top-center below the resolved top inset.
- Relayouts only when placement inputs change.

It contains no queue, gesture, or animation policy.

### Toast Presentation

The presentation widget listens to coordinator changes, selects the active
record, and retains the stable rendered capsule identity. It composes motion,
interaction, content, measurement, surface, and semantics units.

### Motion Synchronization

A focused private state owner reconciles:

- Active record token and revision.
- Desired compact or expanded mode.
- Compact, expanded, and current measured sizes.
- Pending dismissal reason and velocity.
- Motion start, replacement, resolution, retargeting, and reset behavior.
- Entrance and resolution haptic state.

`CapsuleMotionController` remains the sole owner of springs, lifecycle time,
hold timing, and reduced-motion behavior. The synchronizer translates record
changes and measurements into controller commands; it does not duplicate the
motion engine.

### Interaction

A focused private interaction widget owns:

- Surface focus and toast focus-scope nodes.
- Pointer-down, hover, drag, and long-press state.
- Hold-clock pausing derived from interaction state.
- Tap, long-press, and vertical-drag recognizers.
- Keyboard activation and focus traversal.
- Expansion, collapse, and swipe-dismiss commands sent to the coordinator.

Gesture detectors remain outside animation-tick builders so recognizers are not
recreated on each spring update.

### Existing Rendering Primitives

`CapsuleToastSurface`, `CapsuleToastContent`, `CapsuleToastMeasure`, and
`CapsuleToastAnimatedSlot` remain focused rendering primitives. They should not
gain queue or lifecycle policy during this refactor.

New units remain private unless an existing public export requires otherwise.
Thin wrappers that only rename one method call will not be introduced.

## Data Flow

The one-way flow remains:

```text
show or handle command
→ coordinator updates the active record
→ presentation observes the record
→ synchronizer issues motion commands
→ content reports its natural size
→ synchronizer retargets motion
→ presentation rebuilds or repaints
→ layout delegate positions the resulting toast box
```

Queue and command policy remain in `CapsuleToastCoordinator`. Rendering does not
promote records. Motion completion continues to call the coordinator's existing
exit-completion boundary.

## Preserved Behavior

The refactor must preserve all of the following:

- `CapsuleToastHost.of` and `maybeOf` lookup and diagnostics.
- Independent coordinators and presentation layers for nested hosts.
- Stable manager identity for each host lifetime.
- No application-child rebuilds from toast animation ticks.
- Current replacement, resolution, queue promotion, and completion semantics.
- Current seed, compact, expanded, collapsing, and hidden lifecycle behavior.
- Continuous capsule identity and existing motion reseeding rules.
- Safe-area placement, horizontal inset, maximum width, and top-center alignment.
- RTL, text scaling, live resizing, reduced motion, and haptic behavior.
- Tap, long-press, drag, swipe, hover, keyboard, and focus behavior.
- Semantics labels, live-region behavior, and action traversal order.
- Overlay-dependent custom content, including tooltips and popup controls.
- Host-layer theme and ambient-value resolution.
- Handle completion with `hostDisposed` and complete resource disposal.

## Error Handling

Existing public assertions and missing-host diagnostics remain unchanged.

Private layout delegates must tolerate an absent toast slot and must never
construct negative constraints when the viewport is narrower or shorter than
the configured insets. Empty presentation state renders no toast without
removing the stable entry.

The refactor adds no fallback installation path or compatibility shim because
the public installation model is unchanged.

## Testing Strategy

Existing coordinator, motion, widget, accessibility, and golden tests remain
authoritative. Add focused tests for the new structural boundaries:

- The host layout gives body and presentation slots full host constraints.
- Presentation paints above the body.
- Toast animation does not rebuild the application child.
- The viewport centers the toast and applies safe-area, horizontal-inset, and
  maximum-width constraints.
- Narrow and zero-remaining-space layouts do not produce invalid constraints.
- The presentation layer retains identity through replacement, queue promotion,
  live resizing, and theme updates.
- Overlay-dependent custom content continues to build and display correctly.
- Nested hosts and host disposal retain existing behavior.
- Focus traversal, semantics, pointer interaction, and animation timing do not
  regress.

No golden output should change. Any pixel difference is a regression unless it
is separately explained and approved.

## Acceptance Criteria

- Public API and documented installation remain unchanged.
- The host no longer uses a `Stack` for body and presentation composition.
- Toast placement no longer depends on `Positioned`.
- Private `MultiChildLayoutDelegate` implementations own host and toast
  structural placement.
- Exactly one stable presentation overlay entry exists for each host state.
- The overlay entry is not used as a per-toast insertion or removal mechanism.
- `CapsuleToastLayer` responsibilities are separated into focused units without
  moving policy into rendering widgets.
- Overlay-dependent custom content continues to work.
- Existing visual, motion, interaction, accessibility, queue, and completion
  behavior remains unchanged.
- Formatting, package analysis, full package tests, example analysis, and
  example tests pass.
- Golden files are unchanged.
