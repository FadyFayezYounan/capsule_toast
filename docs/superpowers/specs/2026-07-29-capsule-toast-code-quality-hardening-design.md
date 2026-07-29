# Capsule Toast Code-Quality Hardening Design

## Context

The package implementation is visually complete and its current motion design
is approved. This hardening pass compares the implementation with the original
plan and the later cloud-parity design, then fixes correctness, accessibility,
validation, test, performance, documentation, and publishing gaps without
redesigning the capsule.

The cloud-parity design is authoritative where it supersedes the initial plan:
`CapsuleToastQueuePolicy.replace` remains the default and replacement starts
from the seed geometry. Documentation and the example must describe that
behavior accurately.

## Compatibility

This pass preserves the public API wherever practical:

- `slotDelays` remains a `Map<CapsuleToastSlot, Duration>?`.
- Existing factory names, queue policies, builders, and handle APIs remain
  unchanged.
- Theme seed dimensions continue to default to `84 × 34`.

Dart const constructors cannot inspect `Map`, `EdgeInsetsGeometry`, or `Size`
contents in assertions. The theme value constructors therefore become
non-const so every supplied nested value can be validated at the public
boundary. Constructor names and arguments are unchanged, but consumers with
explicit `const CapsuleToastThemeData(...)`,
`const CapsuleToastMotionTheme(...)`, or `const CapsuleToastSpring(...)`
expressions must remove `const`.

Caller-owned `slotDelays` and `shadows` collections are copied into
unmodifiable views at construction. Equality remains order-independent, and
slot-delay hashing is made order-independent by hashing entries in enum order.
This provides deep collection ownership without replacing either public
collection type.

## Invariants

Theme and model values must reject invalid states at their construction
boundary:

- Spring duration is positive and bounce is in `[0, 1)`.
- Slot delays are non-negative.
- Visual paddings are non-negative and seed dimensions are positive.
- Structured toast titles and optional message/announcement strings are
  non-empty.
- Custom toasts have at least one builder and either a non-empty title or
  semantic announcement.
- Display duration is positive when present and absent for persistent toasts.
- `copyWith` cannot bypass any factory invariant.

As with Flutter's public value objects, these programmer errors are expressed
as actionable constructor assertions.

## Motion and Rendering Boundaries

`CapsuleToastLayer` resolves the visual theme. It must pass the resolved seed
size into `CapsuleMotionController`, which owns the seed used for show and exit.
The controller updates its configured seed without retargeting an already
visible capsule, so a loading resolution can update the eventual exit seed
without creating a visual discontinuity.

Custom content builders are mode-specific. When the active mode's builder is
absent, that mode uses the structured renderer; it never invokes the other
mode's builder.

The capsule surface participates in keyboard focus traversal before its
descendant action buttons. Enter and Space toggle expansion only while the
surface itself has focus, preserving action-button activation behavior.

## Ticker Lifecycle

The motion ticker may stop whenever all animated values are settled, including
while the lifecycle clock is paused by pointer interaction. Releasing the
interaction restarts it through the existing resume path.

A custom loading spinner owns its own rendering behavior, so the built-in
glyph widget must not allocate or repeat an unused animation controller.

## Example and Packaging

The queue demonstration explicitly enqueues the second and third records.
Example rows wrap under narrow constraints while retaining the same content and
styling. The smoke test uses the current lab copy, a deterministic viewport,
and fails on framework exceptions.

The README states that replacement is the default and uses package version
`^0.2.0`. A `.pubignore` excludes build outputs, generated API docs, coverage,
golden-failure artifacts, IDE metadata, and local worktrees from release
archives.

## Verification

Completion requires:

- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test --coverage`
- `flutter analyze` and `flutter test` in `example/`
- `flutter build web --release` in `example/`
- `dart doc --validate-links`
- `dart pub publish --dry-run`

The publish preview must not contain ignored build, failure, coverage, API-doc,
IDE, or worktree artifacts.
