# Capsule Toast Code-Quality Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [x]`) syntax for tracking.

**Goal:** Close every correctness and code-quality gap found by the plan-based
review without changing the approved capsule appearance or motion design.

**Architecture:** Keep public APIs backward-compatible and enforce invariants
at immutable value-object boundaries. Pass resolved theme configuration across
the widget/controller boundary explicitly, keep builders mode-local, and make
ticker ownership follow the component that actually renders animation.

**Tech Stack:** Dart 3.12, Flutter 3.44, `flutter_test`, Flutter
`ThemeExtension`, focus/actions, and package publishing tools.

## Global Constraints

- Work only on `codex/code-quality-hardening`.
- Preserve the approved UI, animation curves, replacement behavior, and
  replacement re-seeding.
- Write and observe a failing behavioral test before each production fix.
- Preserve constructor names and parameters; remove `const` construction where
  Dart prevents complete nested-value validation.
- Do not add runtime dependencies.

---

### Task 1: Theme Value Contracts

**Files:**

- Modify: `lib/src/theme/capsule_toast_motion_theme.dart`
- Modify: `lib/src/theme/capsule_toast_theme_data.dart`
- Test: `test/theme/capsule_toast_theme_test.dart`

**Interfaces:**

- Consumes: existing public theme constructors, `copyWith`, `merge`, and `lerp`.
- Produces: validated springs, delays, paddings, and seed sizes; null-safe
  partial interpolation; equality-consistent hashes.

- [x] **Step 1: Add failing spring and visual-theme validation tests**

```dart
expect(
  () => const CapsuleToastSpring(
    duration: Duration.zero,
    bounce: 0,
  ),
  throwsAssertionError,
);
expect(
  () => const CapsuleToastThemeData(seedSize: Size(0, 34)),
  throwsAssertionError,
);
```

- [x] **Step 2: Run the targeted theme tests and confirm they fail**

Run: `flutter test test/theme/capsule_toast_theme_test.dart`

Expected: the new invalid-value expectations fail because constructors accept
the values.

- [x] **Step 3: Add constructor assertions**

```dart
CapsuleToastSpring({
  required this.duration,
  required this.bounce,
}) : assert(duration > Duration.zero),
     assert(bounce >= 0 && bounce < 1);
```

Also validate every slot delay, every padding's `isNonNegative` value, and both
seed dimensions.

- [x] **Step 4: Add a failing partial-lerp test**

```dart
const CapsuleToastMotionTheme a = CapsuleToastMotionTheme(
  appearanceDuration: Duration(milliseconds: 100),
);
const CapsuleToastMotionTheme b = CapsuleToastMotionTheme(
  warningDuration: Duration(milliseconds: 300),
);
expect(() => a.lerp(b, 0.5), returnsNormally);
```

- [x] **Step 5: Run the targeted test and confirm the null assertion fails**

Run: `flutter test test/theme/capsule_toast_theme_test.dart`

- [x] **Step 6: Implement nullable duration interpolation**

```dart
Duration? _lerpDuration(Duration? a, Duration? b, double t) {
  if (a == null) return b;
  if (b == null) return a;
  return Duration(
    microseconds: lerpDouble(
      a.inMicroseconds.toDouble(),
      b.inMicroseconds.toDouble(),
      t,
    )!.round(),
  );
}
```

Use the helper for every nullable duration field.

- [x] **Step 7: Add a failing order-independent hash test**

Create equal themes whose `slotDelays` maps use opposite insertion order and
assert both equality and equal hash codes.

- [x] **Step 8: Hash slot delays in `CapsuleToastSlot.values` order**

Keep the public map API, document that supplied maps must not be mutated, and
use enum order rather than map iteration order.

- [x] **Step 9: Run the theme tests**

Run: `flutter test test/theme/capsule_toast_theme_test.dart`

Expected: PASS.

### Task 2: Toast Data and Mode-Specific Content

**Files:**

- Modify: `lib/src/model/capsule_toast_data.dart`
- Modify: `lib/src/widgets/capsule_toast_content.dart`
- Test: `test/model/capsule_toast_data_test.dart`
- Test: `test/widgets/capsule_toast_content_test.dart`

**Interfaces:**

- Consumes: existing data factories and sentinel-based `copyWith`.
- Produces: one invariant boundary shared by factories and copies; structured
  fallback for a missing builder in the active mode.

- [x] **Step 1: Add failing invalid-string and invalid-copy tests**

Cover empty structured titles, messages, semantic announcements, a custom
toast without a builder, and copies that remove the last required custom value.

- [x] **Step 2: Run model tests and confirm the invalid copies are accepted**

Run: `flutter test test/model/capsule_toast_data_test.dart`

- [x] **Step 3: Centralize all invariants in `CapsuleToastData._`**

Use initializer-list assertions so every factory and `copyWith` call reaches
the same validation boundary. Remove redundant factory-only validation.

- [x] **Step 4: Add failing one-sided custom-builder widget tests**

For an expanded record with only `compactBuilder`, assert that the compact
builder marker is absent and the structured title is present. Add the inverse
case for compact mode with only `expandedBuilder`.

- [x] **Step 5: Run content tests and confirm expanded mode calls the compact builder**

Run: `flutter test test/widgets/capsule_toast_content_test.dart`

- [x] **Step 6: Remove cross-mode builder fallback**

Each `_buildCompact`/`_buildExpanded` method invokes only its corresponding
builder and otherwise continues into its structured renderer.

- [x] **Step 7: Run model and content tests**

Run:

```bash
flutter test test/model/capsule_toast_data_test.dart
flutter test test/widgets/capsule_toast_content_test.dart
```

Expected: PASS.

### Task 3: Seed Propagation and Keyboard Reachability

**Files:**

- Modify: `lib/src/motion/capsule_motion_controller.dart`
- Modify: `lib/src/widgets/capsule_toast_layer.dart`
- Test: `test/widgets/capsule_toast_motion_test.dart`
- Test: `test/widgets/capsule_toast_accessibility_test.dart`

**Interfaces:**

- Consumes: resolved `CapsuleToastThemeData.seedSize` and existing focus/action
  handling.
- Produces: controller-owned configurable seed dimensions and a traversable
  capsule surface.

- [x] **Step 1: Add a failing themed-seed motion test**

Pump a toast with a non-default per-toast seed, sample the initial surface
size, and assert the configured width and height rather than `84 × 34`.

- [x] **Step 2: Run the motion test and confirm the controller remains at the default**

Run: `flutter test test/widgets/capsule_toast_motion_test.dart`

- [x] **Step 3: Add controller seed configuration**

Replace hard-coded width/height constants with a current `Size`. Update that
size from the resolved theme before `show` and `resolve`, and use it for show
and exit seed targets without retargeting a currently visible capsule.

- [x] **Step 4: Add failing keyboard traversal tests**

With no action, send Tab and Enter/Space and assert expanded/collapsed mode.
With an action, traverse from the surface to the action and assert Enter invokes
the action rather than toggling the surface.

- [x] **Step 5: Run accessibility tests and confirm the surface is skipped**

Run: `flutter test test/widgets/capsule_toast_accessibility_test.dart`

- [x] **Step 6: Include the capsule focus node in traversal**

Remove `skipTraversal`, retain the `hasFocus` guard around surface intents, and
keep descendants focusable within the existing focus scope.

- [x] **Step 7: Run motion and accessibility tests**

Run:

```bash
flutter test test/widgets/capsule_toast_motion_test.dart
flutter test test/widgets/capsule_toast_accessibility_test.dart
```

Expected: PASS.

### Task 4: Ticker Ownership and Idle Behavior

**Files:**

- Modify: `lib/src/motion/capsule_motion_controller.dart`
- Modify: `lib/src/widgets/capsule_toast_glyph.dart`
- Test: `test/widgets/capsule_toast_interaction_test.dart`
- Test: `test/widgets/capsule_toast_glyph_test.dart`

**Interfaces:**

- Consumes: interaction pause/resume and optional custom spinner builder.
- Produces: no settled paused motion ticker and no unused built-in spinner
  ticker.

- [x] **Step 1: Add a failing paused-idle test**

Pause an active persistent toast through pointer interaction, pump until all
motion settles, and assert `tester.binding.transientCallbackCount` becomes
zero while the lifecycle remains paused.

- [x] **Step 2: Run interaction tests and confirm the ticker remains active**

Run: `flutter test test/widgets/capsule_toast_interaction_test.dart`

- [x] **Step 3: Let settled paused motion become idle**

Remove interaction pause/drag as unconditional non-idle states. A running hold
keeps the ticker alive only when the lifecycle is not paused; the existing
resume path restarts the ticker.

- [x] **Step 4: Add a failing custom-spinner ticker test**

Pump a persistent loading toast whose theme supplies `spinnerBuilder`, settle
motion, and assert there are no transient callbacks from the unused built-in
glyph animation.

- [x] **Step 5: Run glyph tests and confirm the unused ticker repeats**

Run: `flutter test test/widgets/capsule_toast_glyph_test.dart`

- [x] **Step 6: Gate built-in controller creation on `spinnerBuilder == null`**

Update `_syncController` so only the built-in loading painter owns a repeating
controller.

- [x] **Step 7: Run interaction and glyph tests**

Expected: PASS.

### Task 5: Queue Example, Responsive Example Tests, and Documentation

**Files:**

- Modify: `example/lib/capsule_toast_lab.dart`
- Modify: `example/lib/lab/lab_specimens.dart`
- Modify: `example/lib/lab/lab_panel.dart`
- Modify: `example/test/capsule_toast_lab_test.dart`
- Modify: `README.md`

**Interfaces:**

- Consumes: the authoritative default-replace queue contract and current lab
  copy/layout.
- Produces: a real three-item queue demonstration, overflow-safe rows, current
  smoke assertions, and accurate public documentation.

- [x] **Step 1: Strengthen and run the example smoke test**

Set a deterministic wide viewport, assert current lab controls such as
`Queue 3 events`, call `tester.takeException()`, and keep at least one narrow
viewport pump that proves the wrapping rows do not overflow.

Run: `flutter test`

Expected: FAIL on the stale heading and/or RenderFlex exceptions.

- [x] **Step 2: Fix queue calls and wrapping roots**

Pass `CapsuleToastQueuePolicy.enqueue` for the second and third demo records.
Replace only the overflowing action and caption rows with `Wrap`, retaining
their children, spacing, text, colors, and sizing.

- [x] **Step 3: Correct README contract and package version**

State that `replace` is the default, explain that `enqueue` is explicit, and
change the installation constraint to `^0.2.0`.

- [x] **Step 4: Run example analysis and tests**

Run:

```bash
flutter analyze
flutter test
```

from `example/`.

Expected: PASS with no framework exceptions.

### Task 6: Publish Hygiene and Full Verification

**Files:**

- Create: `.pubignore`
- Modify: files formatted by Dart formatter only when required.

**Interfaces:**

- Consumes: Dart package archive inclusion rules.
- Produces: a clean publish archive and a fully verified branch.

- [x] **Step 1: Add `.pubignore`**

```text
.dart_tool/
.idea/
.worktrees/
**/*.iml
**/build/
coverage/
doc/api/
test/failures/
```

- [x] **Step 2: Preview the archive**

Run: `dart pub publish --dry-run`

Expected: exit zero with none of the excluded paths listed.

- [x] **Step 3: Format and analyze**

Run:

```bash
dart format .
dart format --output=none --set-exit-if-changed .
flutter analyze
```

- [x] **Step 4: Run the package suite with coverage**

Run: `flutter test --coverage`

Expected: all tests pass and coverage does not regress materially from the
review baseline of 65.90%.

- [x] **Step 5: Verify the example build**

Run from `example/`:

```bash
flutter analyze
flutter test
flutter build web --release
```

- [x] **Step 6: Validate public documentation and publishing**

Run:

```bash
dart doc --validate-links
dart pub publish --dry-run
```

Expected: both exit zero; the publish preview contains no generated or local
artifacts.

- [x] **Step 7: Review the complete diff**

Confirm the diff contains only planned code-quality work, tests,
documentation, and archive hygiene; then prepare a detailed handoff including
critical fixes, non-critical improvements, compatibility choices, commands,
results, and any residual tradeoffs.
