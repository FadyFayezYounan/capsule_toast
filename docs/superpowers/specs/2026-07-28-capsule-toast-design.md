# Capsule Toast Flutter Package Design

Date: 2026-07-28  
Status: Approved design  
Package: `capsule_toast`  
Registry: pub.dev  
License: BSD 3-Clause

## Summary

`capsule_toast` is a reusable, brand-neutral Flutter package for displaying a
single morphing capsule notification above an application. It reproduces the
visual design, lifecycle, gestures, and interruptible spring motion of the
provided LifeOps Capsule Toast prototype without retaining LifeOps-specific
copy or branding.

The package supports all Flutter platforms. iOS and Android are the primary
pixel and motion fidelity targets; web and desktop use the same rendering,
queueing, keyboard, mouse, touch, and accessibility behavior.

The primary API is an application-owned `CapsuleToastHost`. The host owns and
disposes its internal queue and motion coordinator. Descendants obtain a narrow
`CapsuleToastManager` through an inherited scope. Applications do not create,
pass, or dispose a toast controller.

## Reference Material

The design and motion reference is composed of:

- `LifeOps Capsule Toast.html`
- `toast-capsule.jsx`
- `toast-lab.jsx`

The reference state sequence is:

```text
hidden → seed → compact ⇄ expanded → collapsing → hidden
```

The Flutter implementation must preserve the defining behavior: one continuous
capsule changes geometry and content while retaining its current spring
position and velocity. State changes must not dismiss and recreate the overlay.

## Goals

- Match the supplied capsule visuals and motion at normal text scale.
- Preserve width and height spring velocity across interrupted transitions.
- Provide brand-neutral semantic variants and caller-owned content.
- Support structured content and fully custom compact and expanded builders.
- Manage a FIFO queue with deterministic completion results.
- Support loading-to-result resolution inside the same capsule.
- Support tap, long-press, drag, swipe-to-dismiss, keyboard, and action input.
- Respect RTL, text scaling, reduced motion, safe areas, and semantics.
- Keep the public API small, documented, immutable where appropriate, and
  consistent with Flutter framework conventions.
- Use only Flutter and Dart SDK runtime dependencies.
- Ship with tests, examples, documentation, and pub.dev-ready metadata.

## Non-goals

- LifeOps-specific text, names, or domain behavior in the package API.
- Bottom, corner, or arbitrary toast placement in version 1.
- Native platform toast APIs.
- Multiple capsules displayed simultaneously by one host.
- A global singleton, global navigator key, or externally owned controller.
- Bundled fonts or runtime font downloads.
- Persistence of queued notifications across application restarts.

## Package Structure

```text
lib/
  capsule_toast.dart
  src/
    manager/
    host/
    model/
    motion/
    theme/
    widgets/
```

`lib/capsule_toast.dart` is the only public barrel. Files under `src` are
organized by responsibility rather than gathered into one large implementation
file.

- `manager/` contains the host-owned manager implementation and queue.
- `host/` contains the stateful host and private inherited scope.
- `model/` contains immutable public data, handles, results, and enums.
- `motion/` contains lifecycle coordination and deterministic spring
  simulation.
- `theme/` contains visual and motion theme data.
- `widgets/` contains the capsule renderer, structured content, glyphs,
  actions, spinner, semantics, measurement, and animated slots.

Rendering widgets do not own queue policy. The queue does not own animation
tickers. The motion engine does not build application content.

## Host and Inherited API

The application installs one host through `MaterialApp.builder`:

```dart
MaterialApp(
  builder: (context, child) {
    return CapsuleToastHost(
      child: child!,
    );
  },
);
```

`CapsuleToastHost` is a `StatefulWidget`. Its state creates, owns, and disposes:

- The private queue coordinator.
- Active and queued toast records.
- Animation tickers and spring state.
- Auto-dismiss timers represented in the lifecycle clock.
- The rendered top-center capsule layer.

The host wraps its descendants in a private `_CapsuleToastScope`. The scope
exposes a public `CapsuleToastManager` interface:

```dart
abstract interface class CapsuleToastManager {
  CapsuleToastHandle show(
    CapsuleToastData toast, {
    CapsuleToastQueuePolicy queuePolicy,
  });

  void clear();

  int get queueLength;
}
```

Consumers access the nearest host:

```dart
final handle = CapsuleToastHost.of(context).show(
  CapsuleToastData.success(title: 'Saved'),
);
```

`CapsuleToastHost.of` returns the narrow manager interface, not widget state.
`CapsuleToastHost.maybeOf` returns `null` when no host exists. An optional
`BuildContext` extension may delegate to the same inherited lookup:

```dart
context.capsuleToast.show(
  CapsuleToastData.success(title: 'Saved'),
);
```

Nested hosts are supported. `of(context)` resolves the nearest host, so nested
application shells can own independent queues without global state.

The inherited manager identity remains stable for the host's lifetime. Toast
animation and queue changes rebuild only the capsule layer; they do not notify
or rebuild ordinary descendants that merely used `of(context)` to issue a
command.

## Public Data Model

`CapsuleToastData` is immutable. It supports brand-neutral factories:

- `success`
- `information`
- `warning`
- `error`
- `loading`
- `neutral`
- `custom`

Semantic factories choose default glyph, accent, duration category, and
announcement prefix. They do not provide application-specific title or message
copy.

Toast data can define:

- Optional stable identifier.
- A required title when using the structured renderer.
- Optional supporting message.
- Optional explicit semantic announcement.
- Semantic type.
- Initial compact or expanded mode.
- Optional icon or icon builder.
- Optional compact action.
- Optional primary and secondary expanded actions.
- Display duration or persistent behavior.
- Per-toast visual overrides.
- Per-toast motion overrides.
- Optional compact content builder.
- Optional expanded content builder.
- Optional text direction override.

`CapsuleToastData.custom` may omit the visible title only when it provides an
explicit semantic announcement. This ensures every custom toast remains
announceable.

Actions are immutable values containing a label, callback, semantic label, and
whether invoking the action dismisses the toast. Action controls consume their
own gestures and do not trigger capsule expand, collapse, or drag behavior. The
callback may be synchronous or asynchronous. The dismissal decision is applied
when the action is invoked rather than waiting for asynchronous work to finish;
asynchronous failures continue through Flutter's error pipeline.

## Handle and Completion

`show` returns a `CapsuleToastHandle` associated with one toast record. It
supports:

- `expand`
- `collapse`
- `resolve`
- `dismiss`
- A `closed` future

`resolve` accepts new `CapsuleToastData`, retargets the measured geometry, and
reveals the new content inside the same capsule. It is the standard way to turn
a persistent loading toast into success, warning, or error.

The `closed` future completes once with a typed result containing a dismissal
reason:

- Timed out.
- Explicitly dismissed.
- Swiped away.
- Action selected.
- Replaced.
- Cleared.
- Queue overflow.
- Host disposed.

After completion, handle commands are safe no-ops. A resolve request is accepted
only while its toast is active and unresolved.

## Queueing

One host renders at most one capsule. Additional records use a FIFO queue.

`CapsuleToastQueuePolicy` supports:

- `enqueue`: append and show after the active toast.
- `replace`: complete the old active handle with `replaced`, retain the existing
  capsule surface, and morph it into the new active record. Existing queued
  records retain their order.
- `clearAndShow`: complete queued records with `cleared`, complete the old
  active handle with `replaced`, and morph the existing surface into the new
  active record.

`CapsuleToastManager.clear()` completes queued records with `cleared` and starts
the standard animated exit for the active record. The active handle completes
with `cleared` after that exit reaches `hidden`.

The queued-record limit is configurable on `CapsuleToastHost` and defaults to
20; the active record is not counted toward that limit. When the queue is full,
the oldest queued record is completed with `queueOverflow`. The visible record
is never removed merely to make queue space.

`queueLength` reports queued records only and does not count the active record.

When one lifecycle finishes, the next queued toast starts after the exit has
fully completed. The package never overlaps two capsule surfaces.

## Motion Architecture

Normal Flutter widgets handle content, semantics, measurement, gestures,
clipping, and painting. A focused ticker-driven engine handles live geometry
and lifecycle time.

Width and height are independent second-order damped springs. Each spring owns:

- Current position.
- Current velocity.
- Target.
- Angular frequency.
- Damping ratio.

The simulation uses bounded time steps no larger than 1/240 second. Large frame
gaps are clamped before integration. A transition retargets existing springs;
it does not create a new tween from the current rendered value.

Reference defaults:

| Motion | Default |
| --- | --- |
| Appearance | 140 ms ease-out |
| Width spring | 420 ms, bounce 0.16 |
| Height spring | 400 ms, bounce 0.12 |
| Height lead | 28 ms after width |
| Interactive spring | 320 ms, bounce 0.18 |
| Exit spring | 300 ms, no bounce |
| Reduced-motion size transition | 240 ms, no bounce |
| Settle point | Approximately 520 ms |
| Exit sequence | Approximately 340 ms |

Motion durations are perceptual targets; the spring state determines the exact
tail. The implementation exposes visual and motion themes without exposing the
private numerical integrator.

## Content Reveal

Structured content uses named slots:

- Icon.
- Title.
- Supporting message.
- Action.

Reference entrance delays are 0, 30, 60, and 90 ms. Each slot uses a 220 ms
ease-out reveal. The icon begins near the capsule center and travels toward its
layout position. Other slots enter with small horizontal and vertical offsets.
The capsule clips all travel.

Exit retracts content in reverse perceptual order before the capsule returns to
the seed and fades upward.

Custom builders receive the toast, mode, resolved themes, manager operations,
and layout constraints. Their entire result receives the standard content
envelope. Custom builders can opt into exact internal staggering with
`CapsuleToastAnimatedSlot` and `CapsuleToastSlot`.

## Layout and Visual Defaults

The toast is top-centered. The host respects the system safe area and applies a
configurable vertical offset.

Reference geometry:

- Seed width: 84 logical pixels.
- Seed height: 34 logical pixels.
- Compact minimum height: 44 logical pixels.
- Maximum width: 340 logical pixels.
- Width is additionally constrained by the available window width and
  horizontal insets.
- Radius equals half the live height, capped at 34 logical pixels.

Reference surface tokens:

- Surface: `#161614`.
- Foreground: `#F9F9F7`.
- Secondary foreground: `rgba(249, 249, 247, 0.62)`.
- Border: `rgba(249, 249, 247, 0.07)`.
- Action chip: `rgba(249, 249, 247, 0.10)`.
- Shadow: a small near shadow plus a broader 30-pixel shadow matching the
  prototype.

Semantic accents use distinct glyph shapes as well as color:

- Success: check.
- Information: circled information mark.
- Warning: warning triangle.
- Error: circled cross.
- Connectivity: connectivity glyph.
- Loading: indeterminate spinner.

At normal text scale, structured spacing and typography metrics match the
prototype. The package inherits the application's font by default. It does not
bundle Inter. Every text style is overridable through theme data.

## Measurement and Responsiveness

Content uses ordinary Flutter layout to report a natural target size. The
spring engine consumes the reported target after layout. It does not perform
intrinsic measurement or repeated text layout from the paint loop.

When content, mode, text direction, text scale, theme, or window constraints
change, the capsule reports a new target while retaining live spring position
and velocity.

Accessibility behavior takes priority over fixed reference dimensions:

- Compact height is a minimum when text scaling requires more room.
- Compact title remains one line and ellipsizes.
- Expanded content grows vertically.
- Actions remain readable and reachable.
- Width always remains inside the active window.

Live window resizing retargets the spring. It does not recreate the toast.

## Gestures and Input

- Tapping a compact capsule expands it.
- Tapping an expanded capsule collapses it.
- Holding for 320 ms expands it.
- Upward dragging tracks the pointer directly.
- Downward dragging uses resistance.
- A displacement above 26 logical pixels or an upward velocity above the
  configured threshold dismisses the toast.
- Swipe dismissal carries gesture velocity into the exit.
- Auto-dismiss pauses while the capsule is pressed or dragged.
- Action controls isolate their gestures from the capsule.
- Desktop and web support mouse input, keyboard focus, and action activation.

## Auto-dismiss and Resolution

The hold clock starts after entrance settlement, not when `show` is called.

Default semantic durations follow the reference categories:

- Success and information: short holds around 2.2–2.4 seconds.
- Warning: 3.6 seconds.
- Error: 3.8 seconds.
- Loading: persistent.

Exact defaults are configurable in `CapsuleToastMotionTheme`. Pressing or
dragging pauses the hold clock. Expanding, collapsing, and resolving reset the
content reveal and settle point before a new hold begins.

## Theme Model

Theme resolution order is:

1. Per-toast overrides.
2. The nearest `CapsuleToastTheme`.
3. `CapsuleToastThemeData` installed in `ThemeData.extensions`.
4. Package reference defaults.

`CapsuleToastThemeData` configures:

- Surface, border, foreground, secondary foreground, accents, and tints.
- Shadows.
- Typography.
- Glyph and spinner builders.
- Content spacing and padding.
- Seed and compact dimensions.
- Width constraints and insets.
- Radius cap.
- Action styles.
- Safe-area and vertical offset behavior.

`CapsuleToastMotionTheme` configures:

- Spring presets.
- Appearance and exit envelopes.
- Content reveal order and delays.
- Semantic hold durations.
- Gesture thresholds and resistance.
- Haptic policy.
- Reduced-motion policy.

Both data classes support `copyWith`, interpolation where meaningful, equality,
and diagnostics consistent with Flutter theme types.

## Accessibility and Internationalization

- Each active toast is a polite live region.
- The semantic label uses the explicit announcement when present; otherwise it
  composes status, title, and supporting message.
- Action widgets expose button semantics and labels.
- Status is never communicated by color alone.
- Ambient `Directionality` controls layout by default.
- RTL mirrors layout and reveal travel while keeping the capsule origin
  centered.
- Ambient `MediaQuery.disableAnimations` enables reduced motion unless
  explicitly overridden by the motion theme.
- Reduced motion removes overshoot, stretch, directional travel, and haptics,
  while preserving clear opacity and size transitions.
- Haptics are optional and occur only on supported platforms.

## Error Handling

- `CapsuleToastHost.of(context)` throws a diagnostic `FlutterError` explaining
  how to install the host when no scope is present.
- `CapsuleToastHost.maybeOf(context)` provides a non-throwing lookup.
- Public configuration rejects negative durations, invalid dimensions, and
  invalid spring values at construction boundaries.
- Action callback failures are reported through Flutter's error pipeline.
- Completed handles remain safe to call.
- Host disposal cancels tickers, releases the queue, and completes all active
  handles.

## Performance Rules

- The application child is stored and is not rebuilt for animation frames.
- Only the capsule layer listens to motion frames.
- No ticker runs while the host is idle.
- Geometry animation does not trigger intrinsic layout on every frame.
- Custom content is measured only when its layout inputs change.
- The capsule uses clipping and repaint boundaries where profiling demonstrates
  a benefit.

## Testing Strategy

### Unit tests

- Spring position, velocity, settlement, retargeting, and bounded integration.
- Preservation of velocity across expand, collapse, resolve, resize, and exit.
- Lifecycle transitions and invalid transitions.
- FIFO ordering and every queue policy.
- Queue overflow and host disposal.
- Handle completion and post-completion behavior.

### Widget tests

- Host lookup, missing-host diagnostics, and nested host resolution.
- Structured compact and expanded content.
- Loading resolution inside one capsule.
- Actions and gesture isolation.
- Tap, long-press, drag, velocity dismissal, and timer pausing.
- Safe-area positioning and narrow layouts.
- Text scaling, RTL, reduced motion, and live resizing.
- Keyboard focus and activation.

### Motion and golden tests

- Deterministic frame assertions at the reference phase timestamps.
- Seed, compact, expanded, loading, and resolving states.
- Every semantic glyph and accent.
- RTL and large-text layouts.
- Reduced-motion states.
- Golden tolerances are fixed and documented; updates require deliberate review.

### Semantics tests

- Live-region announcements.
- Composed and explicit semantic labels.
- Action roles, labels, and focus order.
- Status differentiation without relying on color.

### Quality gates

- `dart format`
- `flutter analyze`
- Complete test and golden suites.
- No active tickers after host disposal or idle settlement.
- `dart pub publish --dry-run` without warnings.

## Example and Documentation

The example app recreates the reference lab with brand-neutral copy. It
demonstrates:

- Every semantic status.
- Loading-to-result resolution.
- Compact and expanded modes.
- A three-item queue.
- Replay and slow-motion inspection controls.
- RTL and reduced motion.
- Theme customization.
- Structured and custom-builder content.
- Touch, mouse, and keyboard interaction.

The package README includes installation, host setup, showing and resolving a
toast, actions, theming, custom builders, nested hosts, accessibility, and
platform support. Public members include API documentation. The repository
includes the BSD 3-Clause license, changelog, screenshots or an animation
preview, and valid pub.dev metadata.

## Acceptance Criteria

- A consumer installs one `CapsuleToastHost` and needs no external controller.
- `CapsuleToastHost.of(context)` resolves the nearest host-owned manager.
- The default structured renderer visually matches the reference at normal text
  scale.
- Interrupting a spring transition preserves position and velocity.
- Loading resolves inside the same capsule.
- Queueing, gestures, RTL, reduced motion, text scaling, semantics, and
  cross-platform input pass their defined tests.
- The package contains no LifeOps branding, runtime font download, global
  singleton, or non-SDK runtime dependency.
- The repository passes all quality gates and pub.dev dry-run validation.
