# Flutter-Style Toast Presentation Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor capsule toast hosting, placement, motion synchronization, and interaction into Flutter-style focused units without changing public API or observable behavior.

**Architecture:** Keep one lifetime-scoped presentation `OverlayEntry` per host so custom toast content retains an `Overlay` ancestor. Replace the host `Stack` and toast `Positioned` placement with explicit `CustomMultiChildLayout` delegates, then split the current 746-line layer into viewport, presentation, motion-synchronization, and interaction units.

**Tech Stack:** Dart, Flutter widgets/rendering, `ChangeNotifier`, `CustomMultiChildLayout`, `Overlay`, `flutter_test`.

## Global Constraints

- Preserve the current public API and documented `MaterialApp.builder` installation.
- Preserve all visuals, motion values, queue behavior, gestures, focus, semantics, haptics, theme resolution, and completion results.
- Keep exactly one stable presentation `OverlayEntry` for each host state.
- Never insert, remove, or replace the entry for individual toast events.
- Preserve custom content support for `Overlay.of(context)`, `Tooltip`, popup menus, and selection controls.
- Do not add dependencies, placement options, public outlets, registration machinery, or compatibility shims.
- Do not modify golden files; any pixel difference is a regression.
- Retain and build on the existing uncommitted dedicated-overlay changes in `capsule_toast_host.dart` and `capsule_toast_host_test.dart`; do not discard them.
- Follow the existing copyright headers, import order, diagnostics, naming, and formatting conventions.

---

## File Structure

- Modify `lib/src/host/capsule_toast_host.dart`: host ownership, stable overlay entry, inherited manager scope, and private body/presentation layout delegate.
- Create `lib/src/widgets/capsule_toast_viewport.dart`: resolve active placement theme and position one toast slot with a private layout delegate.
- Create `lib/src/widgets/capsule_toast_interaction.dart`: focus, pointer, hover, gesture, keyboard, drag, and hold-pause behavior.
- Create `lib/src/widgets/capsule_toast_motion_synchronizer.dart`: record-to-motion reconciliation, measured-size caches, dismissal synchronization, and haptic state.
- Create `lib/src/widgets/capsule_toast_presentation.dart`: active-record presentation composition and listeners.
- Delete `lib/src/widgets/capsule_toast_layer.dart` after its responsibilities move to the focused files.
- Modify `lib/src/widgets/capsule_toast_animated_slot.dart`: update the internal ancestor diagnostic name.
- Modify `test/host/capsule_toast_host_test.dart`: host composition, body isolation, overlay-dependent content, nesting, and disposal regression coverage.
- Create `test/widgets/capsule_toast_viewport_test.dart`: exact placement and constrained-viewport behavior.
- Create `test/widgets/capsule_toast_motion_synchronizer_test.dart`: focused token, revision, measurement, and dismissal synchronization tests.
- Modify `test/widgets/capsule_toast_interaction_test.dart`: assert the focused interaction boundary while retaining behavior coverage.
- Modify `test/widgets/capsule_toast_motion_test.dart`: preserve presentation identity across replacement and promotion.
- Modify `test/support/test_app.dart`: use `CapsuleToastPresentation` for test-only motion and handle inspection.

---

### Task 1: Replace Host Stack With Explicit Host Layout

**Files:**
- Modify: `lib/src/host/capsule_toast_host.dart:79-171`
- Modify: `test/host/capsule_toast_host_test.dart:64-128`

**Interfaces:**
- Consumes: the existing lifetime-scoped `_toastEntry`, `CapsuleToastCoordinator`, `CapsuleMotionController`, and `_CapsuleToastScope`.
- Produces: private `_CapsuleToastHostSlot` and `_CapsuleToastHostLayout`; the host still exposes only `CapsuleToastHost.of` and `maybeOf` publicly.

- [ ] **Step 1: Add a failing host-layout test**

Add this test before the animation-isolation test:

```dart
testWidgets('host uses explicit full-size body and presentation slots', (
  WidgetTester tester,
) async {
  Size? bodySize;

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 320,
        height: 640,
        child: CapsuleToastHost(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              bodySize = constraints.biggest;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ),
  );

  expect(bodySize, const Size(320, 640));
  expect(tester.getSize(find.byType(Overlay)), const Size(320, 640));
  expect(find.byType(CustomMultiChildLayout), findsOneWidget);
  expect(find.byType(Stack), findsNothing);
});
```

- [ ] **Step 2: Run the focused test and verify the structural assertion fails**

Run:

```bash
flutter test test/host/capsule_toast_host_test.dart --plain-name "host uses explicit full-size body and presentation slots"
```

Expected: FAIL because the current host contains a `Stack` and no host `CustomMultiChildLayout`.

- [ ] **Step 3: Introduce host slots and the minimal layout delegate**

Add below `_CapsuleToastHostState`:

```dart
enum _CapsuleToastHostSlot { body, presentation }

class _CapsuleToastHostLayout extends MultiChildLayoutDelegate {
  const _CapsuleToastHostLayout();

  @override
  void performLayout(Size size) {
    final BoxConstraints constraints = BoxConstraints.tight(size);
    layoutChild(_CapsuleToastHostSlot.body, constraints);
    positionChild(_CapsuleToastHostSlot.body, Offset.zero);
    layoutChild(_CapsuleToastHostSlot.presentation, constraints);
    positionChild(_CapsuleToastHostSlot.presentation, Offset.zero);
  }

  @override
  bool shouldRelayout(_CapsuleToastHostLayout oldDelegate) => false;
}
```

Replace the `Stack` in `build` with:

```dart
child: CustomMultiChildLayout(
  delegate: const _CapsuleToastHostLayout(),
  children: <Widget>[
    LayoutId(id: _CapsuleToastHostSlot.body, child: widget.child),
    LayoutId(
      id: _CapsuleToastHostSlot.presentation,
      child: Overlay(initialEntries: <OverlayEntry>[_toastEntry]),
    ),
  ],
),
```

Keep `_toastEntry` lifetime and disposal unchanged. Child order is the paint order, so presentation remains above the body.

- [ ] **Step 4: Run host tests**

Run:

```bash
flutter test test/host/capsule_toast_host_test.dart
```

Expected: PASS, including the existing animation-isolation and Tooltip-bearing custom-content tests.

- [ ] **Step 5: Commit the host layout slice**

```bash
git add lib/src/host/capsule_toast_host.dart test/host/capsule_toast_host_test.dart
git commit -m "refactor(host): use explicit toast layout slots"
```

---

### Task 2: Add The Toast Viewport Layout Boundary

**Files:**
- Create: `lib/src/widgets/capsule_toast_viewport.dart`
- Create: `test/widgets/capsule_toast_viewport_test.dart`

**Interfaces:**
- Consumes: `CapsuleToastCoordinator`, active `CapsuleToastRecord.data.theme`, `CapsuleToastTheme.resolve`, and one presentation child.
- Produces: `CapsuleToastViewport({required CapsuleToastCoordinator coordinator, required Widget child})`.

- [ ] **Step 1: Write failing placement tests**

Create the test file with a helper that owns and disposes its coordinator:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/manager/capsule_toast_coordinator.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_viewport.dart';

void main() {
  testWidgets('viewport applies active toast placement theme', (tester) async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    addTearDown(coordinator.dispose);
    coordinator.show(
      CapsuleToastData.neutral(
        title: 'Placed',
        persistent: true,
        theme: CapsuleToastThemeData(
          maximumWidth: 200,
          horizontalInset: 20,
          useSafeArea: true,
          verticalOffset: 8,
        ),
      ),
    );

    const Key childKey = ValueKey<String>('viewport-child');
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(300, 400),
          viewPadding: EdgeInsets.only(top: 30),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 300,
            height: 400,
            child: CapsuleToastViewport(
              coordinator: coordinator,
              child: const SizedBox(key: childKey, width: 250, height: 40),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(childKey)), const Size(200, 40));
    expect(tester.getTopLeft(find.byKey(childKey)), const Offset(50, 38));
  });

  testWidgets('viewport clamps exhausted space to non-negative constraints', (
    tester,
  ) async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    addTearDown(coordinator.dispose);
    coordinator.show(
      CapsuleToastData.neutral(
        title: 'Narrow',
        persistent: true,
        theme: CapsuleToastThemeData(
          horizontalInset: 80,
          useSafeArea: true,
          verticalOffset: 20,
        ),
      ),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(100, 40),
          viewPadding: EdgeInsets.only(top: 40),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 100,
            height: 40,
            child: CapsuleToastViewport(
              coordinator: coordinator,
              child: const SizedBox(width: 50, height: 30),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run the new test and verify it fails to compile**

Run:

```bash
flutter test test/widgets/capsule_toast_viewport_test.dart
```

Expected: FAIL because `capsule_toast_viewport.dart` and `CapsuleToastViewport` do not exist.

- [ ] **Step 3: Implement the viewport and private layout delegate**

Create `capsule_toast_viewport.dart` with this structure:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../theme/capsule_toast_theme.dart';
import '../theme/capsule_toast_theme_data.dart';

enum _CapsuleToastViewportSlot { toast }

final class CapsuleToastViewport extends StatelessWidget {
  const CapsuleToastViewport({
    super.key,
    required this.coordinator,
    required this.child,
  });

  final CapsuleToastCoordinator coordinator;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final CapsuleToastThemeData theme = CapsuleToastTheme.resolve(
          context,
        ).merge(coordinator.active?.data.theme);
        final double topInset = theme.useSafeArea!
            ? MediaQuery.viewPaddingOf(context).top + theme.verticalOffset!
            : theme.verticalOffset!;

        return CustomMultiChildLayout(
          delegate: _CapsuleToastViewportLayout(
            topInset: topInset,
            horizontalInset: theme.horizontalInset!,
            maximumWidth: theme.maximumWidth!,
          ),
          children: <Widget>[
            LayoutId(id: _CapsuleToastViewportSlot.toast, child: child!),
          ],
        );
      },
    );
  }
}

class _CapsuleToastViewportLayout extends MultiChildLayoutDelegate {
  const _CapsuleToastViewportLayout({
    required this.topInset,
    required this.horizontalInset,
    required this.maximumWidth,
  });

  final double topInset;
  final double horizontalInset;
  final double maximumWidth;

  @override
  void performLayout(Size size) {
    if (!hasChild(_CapsuleToastViewportSlot.toast)) {
      return;
    }
    final double availableWidth = math.max(
      0,
      size.width - horizontalInset * 2,
    );
    final double availableHeight = math.max(0, size.height - topInset);
    final Size toastSize = layoutChild(
      _CapsuleToastViewportSlot.toast,
      BoxConstraints(
        maxWidth: math.min(maximumWidth, availableWidth),
        maxHeight: availableHeight,
      ),
    );
    positionChild(
      _CapsuleToastViewportSlot.toast,
      Offset((size.width - toastSize.width) / 2, topInset),
    );
  }

  @override
  bool shouldRelayout(_CapsuleToastViewportLayout oldDelegate) {
    return topInset != oldDelegate.topInset ||
        horizontalInset != oldDelegate.horizontalInset ||
        maximumWidth != oldDelegate.maximumWidth;
  }
}
```

Do not integrate it into the host yet; the current layer still returns a `Positioned`, which requires a `Stack` parent.

- [ ] **Step 4: Run and format the viewport slice**

Run:

```bash
dart format lib/src/widgets/capsule_toast_viewport.dart test/widgets/capsule_toast_viewport_test.dart
flutter test test/widgets/capsule_toast_viewport_test.dart
flutter analyze
```

Expected: formatting succeeds, both viewport tests PASS, and analysis reports no issues.

- [ ] **Step 5: Commit the viewport slice**

```bash
git add lib/src/widgets/capsule_toast_viewport.dart test/widgets/capsule_toast_viewport_test.dart
git commit -m "refactor(layout): add capsule toast viewport"
```

---

### Task 3: Extract Focus And Gesture Interaction

**Files:**
- Create: `lib/src/widgets/capsule_toast_interaction.dart`
- Modify: `lib/src/widgets/capsule_toast_layer.dart:71-83,156-179,336-403,487-613`
- Modify: `test/widgets/capsule_toast_interaction_test.dart:1-259`

**Interfaces:**
- Consumes: active `CapsuleToastRecord`, `CapsuleToastCoordinator`, `CapsuleMotionController`, resolved `CapsuleToastMotionTheme`, and a rendered child.
- Produces: `CapsuleToastInteraction` with constructor parameters `record`, `coordinator`, `motion`, `motionTheme`, and `child`.

- [ ] **Step 1: Add a failing boundary assertion**

Import the future internal widget in `capsule_toast_interaction_test.dart`:

```dart
import 'package:capsule_toast/src/widgets/capsule_toast_interaction.dart';
```

Add at the start of `main`:

```dart
testWidgets('presentation delegates input to CapsuleToastInteraction', (
  tester,
) async {
  await pumpToast(
    tester,
    CapsuleToastData.information(
      title: 'Interactive',
      message: 'Details',
      persistent: true,
    ),
  );

  expect(find.byType(CapsuleToastInteraction), findsOneWidget);
});
```

- [ ] **Step 2: Run the boundary test and verify it fails to compile**

Run:

```bash
flutter test test/widgets/capsule_toast_interaction_test.dart --plain-name "presentation delegates input to CapsuleToastInteraction"
```

Expected: FAIL because the interaction file and widget do not exist.

- [ ] **Step 3: Create the focused interaction widget**

Move the current layer's focus nodes, pointer/hover/drag/long-press fields,
`_syncInteractionPaused`, `_toggleMode`, `_expand`, drag methods, and
`_buildInteractiveCapsule` into this stateful widget:

```dart
final class CapsuleToastInteraction extends StatefulWidget {
  const CapsuleToastInteraction({
    super.key,
    required this.record,
    required this.coordinator,
    required this.motion,
    required this.motionTheme,
    required this.child,
  });

  final CapsuleToastRecord record;
  final CapsuleToastCoordinator coordinator;
  final CapsuleMotionController motion;
  final CapsuleToastMotionTheme motionTheme;
  final Widget child;

  @override
  State<CapsuleToastInteraction> createState() =>
      _CapsuleToastInteractionState();
}
```

Use the existing recognizer configuration and thresholds verbatim. Replace
references as follows:

```dart
_motion                         → widget.motion
record                          → widget.record
widget.coordinator              → widget.coordinator
motionTheme                     → widget.motionTheme
interactive method child        → widget.child
```

Schedule `_toastFocusScope.requestFocus()` in `initState`, and again from
`didUpdateWidget` only when `oldWidget.record.token != widget.record.token`.
On that token change, match the current replacement branch exactly: set
accumulated drag distance to zero and set drag and long-press state to false;
do not clear pointer-down or hover state and do not force interaction pause off.
In `dispose`, call `widget.motion.setInteractionPaused(false)` before disposing
both focus nodes so removing the active record cannot leave the hold clock
paused. Keep gesture recognizers outside the presentation's `AnimatedBuilder`.

- [ ] **Step 4: Replace layer-owned interaction with the new widget**

Delete the moved fields and methods from `CapsuleToastLayer`. Replace the
`_buildInteractiveCapsule` call with:

```dart
final Widget interactiveChild = CapsuleToastInteraction(
  record: record,
  coordinator: widget.coordinator,
  motion: _motion,
  motionTheme: motionTheme,
  child: DefaultTextStyle.merge(
    style: appTheme.textTheme.bodyMedium,
    child: CapsuleToastContent(
      record: record,
      coordinator: widget.coordinator,
      visualTheme: visualTheme,
      motionTheme: motionTheme,
      vsync: widget.vsync,
    ),
  ),
);
```

Remove interaction resets from `_resetTracking`; the stable interaction state
now resets those values from `didUpdateWidget` when the active token changes.
Do not key `CapsuleToastInteraction`: preserving its element also preserves the
existing `CapsuleToastSurface` element across replacement.

- [ ] **Step 5: Run all interaction and motion regression tests**

Run:

```bash
dart format lib/src/widgets/capsule_toast_interaction.dart lib/src/widgets/capsule_toast_layer.dart test/widgets/capsule_toast_interaction_test.dart
flutter test test/widgets/capsule_toast_interaction_test.dart
flutter test test/widgets/capsule_toast_motion_test.dart
flutter test test/widgets/capsule_toast_accessibility_test.dart
```

Expected: all tests PASS with unchanged timing, focus order, and gesture outcomes.

- [ ] **Step 6: Commit the interaction extraction**

```bash
git add lib/src/widgets/capsule_toast_interaction.dart lib/src/widgets/capsule_toast_layer.dart test/widgets/capsule_toast_interaction_test.dart
git commit -m "refactor(widgets): isolate capsule toast interaction"
```

---

### Task 4: Extract Record-To-Motion Synchronization

**Files:**
- Create: `lib/src/widgets/capsule_toast_motion_synchronizer.dart`
- Create: `test/widgets/capsule_toast_motion_synchronizer_test.dart`
- Modify: `lib/src/widgets/capsule_toast_layer.dart:62-334,432-485`

**Interfaces:**
- Consumes: coordinator, motion controller, current active record, resolved visual and motion themes, reduced-motion state, and measured content sizes.
- Produces: `CapsuleToastMotionSynchronizer`, with `synchronize`, `handleSizeChanged`, `handleMotionChanged`, `needsSynchronization`, and `reset` methods.

- [ ] **Step 1: Write a failing focused synchronizer test**

Create the test file:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/manager/capsule_toast_coordinator.dart';
import 'package:capsule_toast/src/motion/capsule_motion_controller.dart';
import 'package:capsule_toast/src/theme/capsule_toast_theme_data.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_motion_synchronizer.dart';

void main() {
  test('synchronize starts a new record from its themed seed', () {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastMotionTheme motionTheme =
        CapsuleToastMotionTheme.fallback();
    final CapsuleMotionController motion = CapsuleMotionController(
      vsync: const TestVSync(),
      motionTheme: motionTheme,
      onHoldElapsed: coordinator.timeoutActive,
      onExitCompleted: coordinator.finishActiveExit,
    );
    final CapsuleToastMotionSynchronizer synchronizer =
        CapsuleToastMotionSynchronizer(
          coordinator: coordinator,
          motion: motion,
          scheduleSync: () {},
        );
    addTearDown(() {
      motion.dispose();
      coordinator.dispose();
    });

    coordinator.show(
      CapsuleToastData.success(
        title: 'Seeded',
        persistent: true,
        theme: CapsuleToastThemeData(seedSize: const Size(102, 38)),
      ),
    );
    final CapsuleToastThemeData visualTheme =
        CapsuleToastThemeData.fallback().merge(
          coordinator.active!.data.theme,
        );

    synchronizer.synchronize(
      record: coordinator.active,
      visualTheme: visualTheme,
      motionTheme: motionTheme,
      reducedMotion: false,
    );

    expect(motion.value.size, const Size(102, 38));
  });
}
```

- [ ] **Step 2: Run the test and verify it fails to compile**

Run:

```bash
flutter test test/widgets/capsule_toast_motion_synchronizer_test.dart
```

Expected: FAIL because `CapsuleToastMotionSynchronizer` does not exist.

- [ ] **Step 3: Create the synchronizer and move state without changing algorithms**

Create the class with this constructor and state:

```dart
final class CapsuleToastMotionSynchronizer {
  CapsuleToastMotionSynchronizer({
    required this.coordinator,
    required this.motion,
    required this.scheduleSync,
  });

  final CapsuleToastCoordinator coordinator;
  final CapsuleMotionController motion;
  final VoidCallback scheduleSync;

  Size? _measuredSize;
  Size? _compactSize;
  Size? _expandedSize;
  int? _activeToken;
  int _activeRevision = -1;
  CapsuleToastMode? _activeMode;
  CapsuleToastDismissReason? _pendingDismissal;
  bool _motionStarted = false;
  bool _entranceHapticFired = false;
  bool _resolveHapticPending = false;
}
```

Move and rename the existing layer logic using this exact map:

| Current layer member | Synchronizer member | Required adaptation |
| --- | --- | --- |
| `_resolveHoldDuration` | `_resolveHoldDuration` | No body changes. |
| `_resetTracking` | `reset` | Remove interaction fields and `_syncInteractionPaused`; retain every motion, token, revision, size, dismissal, and haptic reset. |
| `_syncMotion` | `synchronize` | Accept `record`, `visualTheme`, `motionTheme`, and `reducedMotion`; remove theme/context resolution; replace `_motion` with `motion`. |
| `_handleSizeChanged` | `handleSizeChanged` | Replace `widget.coordinator.active` with `coordinator.active`, `_motion` with `motion`, and `_scheduleMotionSync()` with `scheduleSync()`. |
| `_shouldTriggerHaptic` | `_shouldTriggerHaptic` | Accept `reducedMotion`; retain web and platform guards. |
| `_maybeTriggerHaptic` | `handleMotionChanged` | Accept `record`, `motionTheme`, and `reducedMotion`; remove context resolution and replace `_motion` with `motion`. |

Add these exact public methods around the moved bodies:

```dart
void synchronize({
  required CapsuleToastRecord? record,
  required CapsuleToastThemeData visualTheme,
  required CapsuleToastMotionTheme motionTheme,
  required bool reducedMotion,
})

void handleSizeChanged(Size size)

void handleMotionChanged({
  required CapsuleToastRecord? record,
  required CapsuleToastMotionTheme motionTheme,
  required bool reducedMotion,
})

bool needsSynchronization(CapsuleToastRecord? record) {
  return !_motionStarted ||
      _activeToken != record?.token ||
      _activeRevision != record?.revision ||
      _activeMode != record?.desiredMode ||
      record?.pendingDismissal != _pendingDismissal;
}

void reset()
```

These declarations document the target signatures; use the moved current
bodies for the four body-bearing methods. Preserve the current branch order for
new token, revision, mode, measured retarget, and pending dismissal. This is a
mechanical move, not an algorithm rewrite.

- [ ] **Step 4: Make the layer delegate synchronization**

Create the synchronizer in `initState` after listeners are attached:

```dart
late CapsuleToastMotionSynchronizer _synchronizer;

@override
void initState() {
  super.initState();
  _synchronizer = CapsuleToastMotionSynchronizer(
    coordinator: widget.coordinator,
    motion: widget.motion,
    scheduleSync: _scheduleMotionSync,
  );
  widget.coordinator.addListener(_handleCoordinatorChanged);
  widget.motion.addListener(_handleMotionChanged);
}
```

When coordinator or motion instances change in `didUpdateWidget`, recreate the
synchronizer after swapping listeners. Replace layer methods with delegations:

```dart
void _syncMotion() {
  final CapsuleToastRecord? record = widget.coordinator.active;
  final CapsuleToastThemeData visualTheme = CapsuleToastTheme.resolve(
    context,
  ).merge(record?.data.theme);
  final CapsuleToastMotionTheme motionTheme =
      CapsuleToastTheme.resolveMotion(context).merge(record?.data.motionTheme);
  final bool reducedMotion = _isReducedMotion(motionTheme);
  _synchronizer.synchronize(
    record: record,
    visualTheme: visualTheme,
    motionTheme: motionTheme,
    reducedMotion: reducedMotion,
  );
}
```

Forward measurement to `_synchronizer.handleSizeChanged`. Forward motion
listener events to `handleMotionChanged` with currently resolved inputs. Use
`needsSynchronization(record)` in `build`. Keep post-frame scheduling and
`mounted` checks in the layer state because they depend on `State` lifecycle.

- [ ] **Step 5: Run focused and lifecycle regression tests**

Run:

```bash
dart format lib/src/widgets/capsule_toast_motion_synchronizer.dart lib/src/widgets/capsule_toast_layer.dart test/widgets/capsule_toast_motion_synchronizer_test.dart
flutter test test/widgets/capsule_toast_motion_synchronizer_test.dart
flutter test test/widgets/capsule_toast_motion_test.dart
flutter test test/widgets/capsule_toast_exit_motion_test.dart
flutter test test/widgets/capsule_toast_rapid_replacement_test.dart
```

Expected: all tests PASS; seed, replacement, resolution, mode retargeting,
dismissal velocity, queue promotion, and haptics remain unchanged.

- [ ] **Step 6: Commit the synchronization extraction**

```bash
git add lib/src/widgets/capsule_toast_motion_synchronizer.dart lib/src/widgets/capsule_toast_layer.dart test/widgets/capsule_toast_motion_synchronizer_test.dart
git commit -m "refactor(motion): isolate toast presentation synchronization"
```

---

### Task 5: Integrate Viewport And Focused Presentation

**Files:**
- Create: `lib/src/widgets/capsule_toast_presentation.dart`
- Delete: `lib/src/widgets/capsule_toast_layer.dart`
- Modify: `lib/src/host/capsule_toast_host.dart:11,92-98`
- Modify: `lib/src/widgets/capsule_toast_animated_slot.dart:58`
- Modify: `test/support/test_app.dart:15,160-165,243-246`
- Modify: `test/widgets/capsule_toast_content_test.dart:92-127`
- Modify: `test/widgets/capsule_toast_motion_test.dart:139-187`

**Interfaces:**
- Consumes: `CapsuleToastViewport`, `CapsuleToastInteraction`, `CapsuleToastMotionSynchronizer`, existing content/surface/measurement widgets, coordinator, motion controller, and ticker provider.
- Produces: `CapsuleToastPresentation({required coordinator, required motion, required vsync})`; the host entry mounts that presentation as the viewport child.

- [ ] **Step 1: Strengthen placement and identity regression tests**

In `capsule_toast_content_test.dart`, make the safe-area assertion exact for the
settled transform:

```dart
expect(
  tester.getTopLeft(find.byKey(capsuleSurfaceKey)).dy,
  closeTo(59, 0.01),
);
```

The expected `59` is `44` view padding plus the default `15` vertical offset.

In `capsule_toast_motion_test.dart`, extend the replacement test:

```dart
final Element presentationBefore = tester.element(
  find.byType(CapsuleToastPresentation),
);
// Existing replacement action and pump.
expect(
  tester.element(find.byType(CapsuleToastPresentation)),
  same(presentationBefore),
);
```

Add the internal presentation import required by the finder.

- [ ] **Step 2: Run the tests and verify the presentation test fails to compile**

Run:

```bash
flutter test test/widgets/capsule_toast_content_test.dart test/widgets/capsule_toast_motion_test.dart
```

Expected: FAIL because `CapsuleToastPresentation` does not exist yet.

- [ ] **Step 3: Move the remaining layer into `CapsuleToastPresentation`**

Copy the reduced `CapsuleToastLayer` implementation to
`capsule_toast_presentation.dart` and rename its widget and state:

```dart
final class CapsuleToastPresentation extends StatefulWidget {
  const CapsuleToastPresentation({
    super.key,
    required this.coordinator,
    required this.motion,
    required this.vsync,
  });

  final CapsuleToastCoordinator coordinator;

  @visibleForTesting
  final CapsuleMotionController motion;

  final TickerProvider vsync;

  @override
  State<CapsuleToastPresentation> createState() =>
      _CapsuleToastPresentationState();
}
```

Preserve coordinator and motion listener lifecycle and diagnostics. In `build`,
remove the outer `Positioned`, horizontal `Padding`, top `Padding`, and `Align`.
Return a `LayoutBuilder` whose constraints provide `measureMaxWidth`:

```dart
return LayoutBuilder(
  builder: (BuildContext context, BoxConstraints constraints) {
    return AnimatedBuilder(
      animation: widget.motion,
      child: interactiveChild,
      builder: (BuildContext context, Widget? child) {
        final CapsuleMotionSnapshot snapshot = widget.motion.value;
        return Transform.translate(
          offset: Offset(0, snapshot.verticalOffset),
          child: Opacity(
            opacity: snapshot.opacity,
            child: Transform.scale(
              scale: snapshot.scale,
              alignment: Alignment.center,
              child: SizedBox.fromSize(
                size: snapshot.size,
                child: CapsuleToastAnimationScope(
                  contentElapsed: widget.motion.contentElapsed,
                  revealing: widget.motion.contentRevealing,
                  reducedMotion: reducedMotion,
                  motionTheme: motionTheme,
                  textDirection: textDirection,
                  capsuleSize: snapshot.size,
                  iconTravel: iconTravel,
                  child: CapsuleToastSurface(
                    theme: visualTheme,
                    measureMaxWidth: constraints.maxWidth,
                    liveSize: snapshot.size,
                    semanticsLabel: announcement,
                    child: CapsuleToastMeasure(
                      generation: record.token,
                      onSizeChanged: _synchronizer.handleSizeChanged,
                      child: child!,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  },
);
```

Delete `capsule_toast_layer.dart` after all imports are updated.

- [ ] **Step 4: Mount viewport and presentation from the stable entry**

Update the host imports and entry builder:

```dart
late final OverlayEntry _toastEntry = OverlayEntry(
  builder: (BuildContext context) => CapsuleToastViewport(
    coordinator: _coordinator,
    child: CapsuleToastPresentation(
      coordinator: _coordinator,
      motion: _motion!,
      vsync: this,
    ),
  ),
);
```

This preserves one entry and one presentation element for the host lifetime.
Empty active state remains `SizedBox.shrink()` inside the presentation; it does
not remove the entry.

- [ ] **Step 5: Update internal diagnostics and test helpers**

Change the animated-slot error text from `CapsuleToastLayer` to
`CapsuleToastPresentation`. In `test/support/test_app.dart`, import the new file
and replace both `CapsuleToastLayer` lookups:

```dart
final CapsuleToastPresentation presentation = tester.widget(
  find.byType(CapsuleToastPresentation),
);
```

Read `presentation.coordinator.active!.handle` and `presentation.motion` exactly
as the old helper read the layer.

- [ ] **Step 6: Run focused integration tests**

Run:

```bash
dart format lib/src/host/capsule_toast_host.dart lib/src/widgets test/support/test_app.dart test/widgets/capsule_toast_content_test.dart test/widgets/capsule_toast_motion_test.dart
flutter test test/host/capsule_toast_host_test.dart
flutter test test/widgets/capsule_toast_viewport_test.dart
flutter test test/widgets/capsule_toast_content_test.dart
flutter test test/widgets/capsule_toast_motion_test.dart
flutter test test/widgets/capsule_toast_interaction_test.dart
flutter test test/widgets/capsule_toast_accessibility_test.dart
```

Expected: all tests PASS, the exact safe-area position remains 59, and
presentation identity survives replacement.

- [ ] **Step 7: Commit the presentation integration**

```bash
git add lib/src/host/capsule_toast_host.dart lib/src/widgets test/support/test_app.dart test/widgets/capsule_toast_content_test.dart test/widgets/capsule_toast_motion_test.dart
git commit -m "refactor(widgets): compose focused toast presentation"
```

---

### Task 6: Verify Full Behavioral And Pixel Parity

**Files:**
- Modify only files required to correct a discovered regression; do not update golden images.

**Interfaces:**
- Consumes: all preceding refactor slices.
- Produces: a formatted, analyzed, fully tested package and example with unchanged goldens.

- [ ] **Step 1: Verify formatting without changing files**

Run:

```bash
dart format --output=none --set-exit-if-changed .
```

Expected: exit code 0 and no files requiring formatting.

- [ ] **Step 2: Run package static analysis**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run the complete package test suite, including goldens**

Run:

```bash
flutter test
```

Expected: all tests PASS and no files under `test/goldens/` change.

- [ ] **Step 4: Run example quality gates**

Run from `example/`:

```bash
flutter analyze
flutter test
```

Expected: analysis reports no issues and all example tests PASS.

- [ ] **Step 5: Confirm the public barrel and diff scope**

Run:

```bash
git diff --check
git diff --stat HEAD~5..HEAD
git status --short
```

Expected: no whitespace errors; no changes to `lib/capsule_toast.dart`, public
models, queue policy, motion constants, or golden files; working tree clean.

- [ ] **Step 6: Commit only if verification required a correction**

If and only if Steps 1-5 required code corrections under `lib/src`, `test`, or
`example`, stage tracked corrections in those scopes and commit:

```bash
git add -u -- lib/src test example
git commit -m "fix: preserve toast presentation parity"
```

If no correction was needed, do not create an empty commit.
