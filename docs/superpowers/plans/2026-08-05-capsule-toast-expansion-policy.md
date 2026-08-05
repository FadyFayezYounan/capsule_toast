# Capsule Toast Expansion Policy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a caller lock a `CapsuleToastData` toast to `compactOnly` or `expandedOnly`, so a toast with nothing to reveal when expanded (or nothing useful when collapsed) can't be toggled into a meaningless state.

**Architecture:** A new `CapsuleToastExpansionPolicy` enum (`adaptive` / `compactOnly` / `expandedOnly`) is added as a field on the immutable `CapsuleToastData`. Enforcement lives in exactly one place — `CapsuleToastCoordinator.expand`/`collapse` — which every toggle path (tap, long-press, `CapsuleToastHandle.expand()`/`collapse()`) already routes through, so it silently no-ops a forbidden transition without touching gesture or widget code. `resolve()` bypasses this guard entirely because it replaces the record's `data` wholesale, so a resolved toast's own policy always takes over immediately.

**Tech Stack:** Flutter/Dart package (`capsule_toast`), `flutter_test` widget/unit tests, no new dependencies.

Spec: [`docs/superpowers/specs/2026-08-05-capsule-toast-expansion-policy-design.md`](../specs/2026-08-05-capsule-toast-expansion-policy-design.md)

## Global Constraints

- `expansionPolicy` defaults to `CapsuleToastExpansionPolicy.adaptive` everywhere it appears — every existing call site must keep compiling and behaving exactly as it does today.
- Naming is fixed: enum `CapsuleToastExpansionPolicy`, values `adaptive`, `compactOnly`, `expandedOnly`; field name `expansionPolicy` on `CapsuleToastData`.
- A `compactOnly`/`expandedOnly` toast with a contradicting `initialMode` must throw an `AssertionError` at construction (debug mode), matching this class's existing assert-based invariant style (e.g. `persistent` + `displayDuration`).
- A forbidden `expand()`/`collapse()` call (via tap, long-press, or handle) is a **silent no-op** — no exception, no state change — matching the coordinator's existing behavior for a stale token or a completed record.
- `resolve()` must never be gated by the outgoing record's `expansionPolicy`. The incoming `CapsuleToastData`'s own policy governs from the moment `resolve()` runs.
- No changes to `CapsuleToastLayer`, `CapsuleToastRecord`, `CapsuleMotionController`, or gesture wiring — the guard in the coordinator is sufficient by construction (see spec §5).

---

### Task 1: Add `CapsuleToastExpansionPolicy` and wire it through `CapsuleToastData`

**Files:**
- Modify: `lib/src/model/capsule_toast_types.dart`
- Modify: `lib/src/model/capsule_toast_data.dart`
- Test: `test/model/capsule_toast_data_test.dart`

**Interfaces:**
- Produces: `enum CapsuleToastExpansionPolicy { adaptive, compactOnly, expandedOnly }` (public, exported already via `lib/capsule_toast.dart`'s wholesale `export 'src/model/capsule_toast_types.dart';`).
- Produces: `CapsuleToastData.expansionPolicy` (`CapsuleToastExpansionPolicy`, defaults to `adaptive`) — a new constructor parameter, new field, and new parameter on all six semantic factories (`success`, `information`, `warning`, `error`, `loading`, `neutral`) plus `custom`, threaded through `copyWith`, `debugFillProperties`, `operator ==`, and `hashCode`.
- Later tasks (2, 3) consume `record.data.expansionPolicy` for comparison against `CapsuleToastExpansionPolicy.compactOnly` / `.expandedOnly`.

- [ ] **Step 1: Write the failing tests**

Add to `test/model/capsule_toast_data_test.dart`, inside `void main() { ... }`, after the existing `test('copyWith cannot remove the last custom builder or announcement', ...)` block:

```dart
  test('expansionPolicy defaults to adaptive', () {
    final CapsuleToastData toast = CapsuleToastData.success(title: 'Saved');

    expect(toast.expansionPolicy, CapsuleToastExpansionPolicy.adaptive);
  });

  test('compactOnly rejects an expanded initialMode', () {
    expect(
      () => CapsuleToastData.success(
        title: 'Saved',
        expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
        initialMode: CapsuleToastMode.expanded,
      ),
      throwsAssertionError,
    );
  });

  test('expandedOnly rejects a compact initialMode', () {
    expect(
      () => CapsuleToastData.success(
        title: 'Saved',
        expansionPolicy: CapsuleToastExpansionPolicy.expandedOnly,
      ),
      throwsAssertionError,
    );
  });

  test('expandedOnly accepts a matching expanded initialMode', () {
    final CapsuleToastData toast = CapsuleToastData.success(
      title: 'Saved',
      expansionPolicy: CapsuleToastExpansionPolicy.expandedOnly,
      initialMode: CapsuleToastMode.expanded,
    );

    expect(toast.expansionPolicy, CapsuleToastExpansionPolicy.expandedOnly);
    expect(toast.initialMode, CapsuleToastMode.expanded);
  });

  test('copyWith can change expansionPolicy independently', () {
    final CapsuleToastData toast = CapsuleToastData.success(title: 'Saved');
    final CapsuleToastData copy = toast.copyWith(
      expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
    );

    expect(copy.expansionPolicy, CapsuleToastExpansionPolicy.compactOnly);
    expect(copy.title, 'Saved');
  });

  test('operator == and hashCode account for expansionPolicy', () {
    final CapsuleToastData a = CapsuleToastData.success(title: 'Saved');
    final CapsuleToastData b = CapsuleToastData.success(
      title: 'Saved',
      expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
    );

    expect(a == b, isFalse);
    expect(a.hashCode == b.hashCode, isFalse);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/model/capsule_toast_data_test.dart`
Expected: FAIL to compile — `expansionPolicy` and `CapsuleToastExpansionPolicy` are undefined.

- [ ] **Step 3: Add the enum**

In `lib/src/model/capsule_toast_types.dart`, insert a new enum immediately after the closing brace of `CapsuleToastMode` (after `expanded,` and its closing `}`, before `/// Queue behavior when a new toast is shown while others are active.`):

```dart
/// Whether a toast may toggle between compact and expanded layout.
enum CapsuleToastExpansionPolicy {
  /// Toggles between compact and expanded via tap, long-press, or the
  /// handle (today's behavior).
  adaptive,

  /// Locked to compact — cannot expand via any interaction or handle call.
  compactOnly,

  /// Locked to expanded — cannot collapse via any interaction or handle
  /// call.
  expandedOnly,
}
```

- [ ] **Step 4: Add the field and constructor parameter**

In `lib/src/model/capsule_toast_data.dart`, in the private constructor
`CapsuleToastData._({ ... })`:

Find:
```dart
    this.initialMode = CapsuleToastMode.compact,
    this.glyph = CapsuleToastGlyph.automatic,
```
Replace with:
```dart
    this.initialMode = CapsuleToastMode.compact,
    this.expansionPolicy = CapsuleToastExpansionPolicy.adaptive,
    this.glyph = CapsuleToastGlyph.automatic,
```

Find the last assert in the same constructor's initializer list:
```dart
       assert(
         !persistent || displayDuration == null,
         'Persistent capsule toasts cannot have a displayDuration.',
       );
```
Replace with:
```dart
       assert(
         !persistent || displayDuration == null,
         'Persistent capsule toasts cannot have a displayDuration.',
       ),
       assert(
         expansionPolicy != CapsuleToastExpansionPolicy.compactOnly ||
             initialMode == CapsuleToastMode.compact,
         'A compactOnly toast cannot have initialMode: expanded.',
       ),
       assert(
         expansionPolicy != CapsuleToastExpansionPolicy.expandedOnly ||
             initialMode == CapsuleToastMode.expanded,
         'An expandedOnly toast cannot have initialMode: compact.',
       );
```

Find the field declaration:
```dart
  /// Layout mode when the toast first appears.
  final CapsuleToastMode initialMode;
```
Replace with:
```dart
  /// Layout mode when the toast first appears.
  final CapsuleToastMode initialMode;

  /// Whether this toast may toggle between compact and expanded layout.
  final CapsuleToastExpansionPolicy expansionPolicy;
```

- [ ] **Step 5: Thread the parameter through all seven factories**

Each of `success`, `information`, `warning`, `error`, `loading`, `neutral`,
and `custom` needs the same two edits. Locate each factory by its unique
`factory CapsuleToastData.<name>({` line, then:

1. In its parameter list, add a line immediately after
   `CapsuleToastMode initialMode = CapsuleToastMode.compact,`:
   ```dart
   CapsuleToastExpansionPolicy expansionPolicy = CapsuleToastExpansionPolicy.adaptive,
   ```
2. In its `return CapsuleToastData._( ... )` call, add a line immediately
   after `initialMode: initialMode,`:
   ```dart
   expansionPolicy: expansionPolicy,
   ```

Apply this to all seven factories: `success`, `information`, `warning`,
`error`, `loading`, `neutral`, `custom`. (`custom`'s parameter list has no
`glyph`/`icon`/action parameters, but it does have `initialMode` — the same
two-line edit applies at that parameter and at its forwarding call.)

- [ ] **Step 6: Update `copyWith`, `debugFillProperties`, `operator ==`, and `hashCode`**

In `copyWith`'s parameter list, find:
```dart
    CapsuleToastMode? initialMode,
    CapsuleToastGlyph? glyph,
```
Replace with:
```dart
    CapsuleToastMode? initialMode,
    CapsuleToastExpansionPolicy? expansionPolicy,
    CapsuleToastGlyph? glyph,
```

In `copyWith`'s body, find:
```dart
      initialMode: initialMode ?? this.initialMode,
      glyph: glyph ?? this.glyph,
```
Replace with:
```dart
      initialMode: initialMode ?? this.initialMode,
      expansionPolicy: expansionPolicy ?? this.expansionPolicy,
      glyph: glyph ?? this.glyph,
```

In `debugFillProperties`, find:
```dart
    properties.add(EnumProperty<CapsuleToastMode>('initialMode', initialMode));
    properties.add(EnumProperty<CapsuleToastGlyph>('glyph', glyph));
```
Replace with:
```dart
    properties.add(EnumProperty<CapsuleToastMode>('initialMode', initialMode));
    properties.add(
      EnumProperty<CapsuleToastExpansionPolicy>(
        'expansionPolicy',
        expansionPolicy,
      ),
    );
    properties.add(EnumProperty<CapsuleToastGlyph>('glyph', glyph));
```

In `operator ==`, find:
```dart
        other.initialMode == initialMode &&
        other.glyph == glyph &&
```
Replace with:
```dart
        other.initialMode == initialMode &&
        other.expansionPolicy == expansionPolicy &&
        other.glyph == glyph &&
```

In `hashCode`, find:
```dart
    initialMode,
    glyph,
```
Replace with:
```dart
    initialMode,
    expansionPolicy,
    glyph,
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `flutter test test/model/capsule_toast_data_test.dart`
Expected: PASS — all tests, including the six added in Step 1.

- [ ] **Step 8: Run static analysis**

Run: `dart analyze lib`
Expected: No issues found.

- [ ] **Step 9: Commit**

```bash
git add lib/src/model/capsule_toast_types.dart lib/src/model/capsule_toast_data.dart test/model/capsule_toast_data_test.dart
git commit -m "feat: add CapsuleToastExpansionPolicy to CapsuleToastData"
```

---

### Task 2: Enforce the policy in `CapsuleToastCoordinator`

**Files:**
- Modify: `lib/src/manager/capsule_toast_coordinator.dart:172-192`
- Modify: `lib/src/model/capsule_toast_handle.dart:10-14,34-38`
- Test: `test/manager/capsule_toast_coordinator_test.dart`

**Interfaces:**
- Consumes: `CapsuleToastData.expansionPolicy` (Task 1) via `current.data.expansionPolicy`.
- Consumes: `CapsuleToastExpansionPolicy.compactOnly` / `.expandedOnly` (Task 1).
- No new public interfaces — `CapsuleToastCoordinator.expand(int token)` and `.collapse(int token)` keep their existing signatures; their behavior gains a guard.

- [ ] **Step 1: Write the failing tests**

Add to `test/manager/capsule_toast_coordinator_test.dart`, inside `void main() { ... }`, after the existing `test('resolve updates active loading record in place', ...)` block:

```dart
  test('expand is a no-op on a compactOnly record', () {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle handle = coordinator.show(
      CapsuleToastData.success(
        title: 'Saved',
        expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
      ),
    );

    handle.expand();

    expect(coordinator.active!.desiredMode, CapsuleToastMode.compact);
  });

  test('collapse is a no-op on an expandedOnly record', () {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle handle = coordinator.show(
      CapsuleToastData.success(
        title: 'Saved',
        expansionPolicy: CapsuleToastExpansionPolicy.expandedOnly,
        initialMode: CapsuleToastMode.expanded,
      ),
    );

    handle.collapse();

    expect(coordinator.active!.desiredMode, CapsuleToastMode.expanded);
  });

  test('adaptive expand and collapse behave as before', () {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle handle = coordinator.show(
      CapsuleToastData.success(title: 'Saved'),
    );

    handle.expand();
    expect(coordinator.active!.desiredMode, CapsuleToastMode.expanded);

    handle.collapse();
    expect(coordinator.active!.desiredMode, CapsuleToastMode.compact);
  });

  test('resolving into a different expansionPolicy applies it immediately', () {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle handle = coordinator.show(
      CapsuleToastData.loading(
        title: 'Uploading',
        expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
      ),
    );

    handle.resolve(
      CapsuleToastData.success(
        title: 'Uploaded',
        expansionPolicy: CapsuleToastExpansionPolicy.expandedOnly,
        initialMode: CapsuleToastMode.expanded,
      ),
    );

    expect(coordinator.active!.desiredMode, CapsuleToastMode.expanded);

    // The old compactOnly restriction is gone; the new expandedOnly
    // restriction now applies.
    handle.expand();
    handle.collapse();
    expect(coordinator.active!.desiredMode, CapsuleToastMode.expanded);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/manager/capsule_toast_coordinator_test.dart`
Expected: FAIL — `expand is a no-op on a compactOnly record`,
`collapse is a no-op on an expandedOnly record`, and
`resolving into a different expansionPolicy applies it immediately` all
fail because `desiredMode` changes anyway (no guard yet): the last test's
final `handle.collapse()` call would unconditionally succeed and leave the
toast compact instead of expanded. `adaptive expand and collapse behave as
before` already passes, since it describes today's behavior — that's fine,
it locks in the regression coverage the spec asks for.

- [ ] **Step 3: Add the guard**

In `lib/src/manager/capsule_toast_coordinator.dart`, find:

```dart
  @override
  void expand(int token) {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null || current.token != token || current.isCompleted) {
      return;
    }
    current.desiredMode = CapsuleToastMode.expanded;
    _notify();
  }

  @override
  void collapse(int token) {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null || current.token != token || current.isCompleted) {
      return;
    }
    current.desiredMode = CapsuleToastMode.compact;
    _notify();
  }
```

Replace with:

```dart
  @override
  void expand(int token) {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null || current.token != token || current.isCompleted) {
      return;
    }
    if (current.data.expansionPolicy == CapsuleToastExpansionPolicy.compactOnly) {
      return;
    }
    current.desiredMode = CapsuleToastMode.expanded;
    _notify();
  }

  @override
  void collapse(int token) {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null || current.token != token || current.isCompleted) {
      return;
    }
    if (current.data.expansionPolicy == CapsuleToastExpansionPolicy.expandedOnly) {
      return;
    }
    current.desiredMode = CapsuleToastMode.compact;
    _notify();
  }
```

- [ ] **Step 4: Update handle doc comments**

In `lib/src/model/capsule_toast_handle.dart`, find:

```dart
  /// Requests expanded layout for the toast identified by [token].
  void expand(int token);

  /// Requests compact layout for the toast identified by [token].
  void collapse(int token);
```

Replace with:

```dart
  /// Requests expanded layout for the toast identified by [token].
  ///
  /// A no-op if that toast's [CapsuleToastData.expansionPolicy] is
  /// [CapsuleToastExpansionPolicy.compactOnly].
  void expand(int token);

  /// Requests compact layout for the toast identified by [token].
  ///
  /// A no-op if that toast's [CapsuleToastData.expansionPolicy] is
  /// [CapsuleToastExpansionPolicy.expandedOnly].
  void collapse(int token);
```

Find:

```dart
  /// Requests expanded layout for this toast when it is active.
  void expand();

  /// Requests compact layout for this toast when it is active.
  void collapse();
```

Replace with:

```dart
  /// Requests expanded layout for this toast when it is active.
  ///
  /// A no-op if this toast's [CapsuleToastData.expansionPolicy] is
  /// [CapsuleToastExpansionPolicy.compactOnly].
  void expand();

  /// Requests compact layout for this toast when it is active.
  ///
  /// A no-op if this toast's [CapsuleToastData.expansionPolicy] is
  /// [CapsuleToastExpansionPolicy.expandedOnly].
  void collapse();
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/manager/capsule_toast_coordinator_test.dart`
Expected: PASS — all tests, including the four added in Step 1.

- [ ] **Step 6: Run the full test suite and static analysis**

Run: `flutter test && dart analyze lib`
Expected: All tests pass; no analyzer issues. (This also guards that
nothing else in the suite implicitly depended on unrestricted
expand/collapse.)

- [ ] **Step 7: Commit**

```bash
git add lib/src/manager/capsule_toast_coordinator.dart lib/src/model/capsule_toast_handle.dart test/manager/capsule_toast_coordinator_test.dart
git commit -m "feat: enforce expansionPolicy in CapsuleToastCoordinator expand/collapse"
```

---

### Task 3: Widget-level regression coverage for gesture gating

**Files:**
- Test: `test/widgets/capsule_toast_interaction_test.dart`

**Interfaces:**
- Consumes: `CapsuleToastData.expansionPolicy` (Task 1), the coordinator guard (Task 2), and existing test helpers `pumpToast`, `capsuleSize`, `capsuleSurfaceKey` from `test/support/test_app.dart`.
- No production code changes in this task — it proves the "what does not change" claim from the spec: tap-to-toggle and long-press-to-expand become inert for restricted toasts purely because they call into the now-guarded coordinator methods.

- [ ] **Step 1: Write the tests**

Add to `test/widgets/capsule_toast_interaction_test.dart`, inside
`void main() { ... }`, after the existing
`testWidgets('tap toggles compact and expanded modes', ...)` block:

```dart
  testWidgets('tapping a compactOnly toast does not expand it', (
    tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(
        title: 'Saved',
        expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
      ),
    );
    final double compactHeight = capsuleSize(tester).height;

    await tester.tap(find.byKey(capsuleSurfaceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(capsuleSize(tester).height, closeTo(compactHeight, 1));
  });

  testWidgets('tapping an expandedOnly toast does not collapse it', (
    tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.warning(
        title: 'Attention',
        message: 'Review the information before continuing.',
        initialMode: CapsuleToastMode.expanded,
        expansionPolicy: CapsuleToastExpansionPolicy.expandedOnly,
      ),
    );
    final double expandedHeight = capsuleSize(tester).height;

    await tester.tap(find.byKey(capsuleSurfaceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(capsuleSize(tester).height, closeTo(expandedHeight, 1));
  });

  testWidgets('long-pressing a compactOnly toast does not expand it', (
    tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.success(
        title: 'Saved',
        expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
      ),
    );
    final double compactHeight = capsuleSize(tester).height;

    await tester.longPress(find.byKey(capsuleSurfaceKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(capsuleSize(tester).height, closeTo(compactHeight, 1));
  });
```

- [ ] **Step 2: Run the tests to verify they fail without Tasks 1–2**

This step is informational if Tasks 1–2 are already merged (they should
pass immediately). If run against a tree without the coordinator guard,
`tapping a compactOnly toast does not expand it` and the long-press
equivalent fail because the capsule visibly grows.

Run: `flutter test test/widgets/capsule_toast_interaction_test.dart`
Expected (with Tasks 1–2 in place): PASS.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: PASS, no regressions in the rest of the suite.

- [ ] **Step 4: Commit**

```bash
git add test/widgets/capsule_toast_interaction_test.dart
git commit -m "test: cover gesture gating for compactOnly/expandedOnly toasts"
```

---

### Task 4: Documentation

**Files:**
- Modify: `README.md:100-105,445`
- Modify: `CHANGELOG.md:1`

**Interfaces:**
- Consumes: the finished public API from Tasks 1–2 (`CapsuleToastData.expansionPolicy`, `CapsuleToastExpansionPolicy`).
- No code or test changes — this task is documentation-only and has no independent automated test; verification is a manual read-through plus `dart analyze` staying clean (doc comments are code).

- [ ] **Step 1: Add the README subsection**

In `README.md`, find:

```markdown
Users can tap the capsule or activate it from the keyboard to toggle its mode;
a long press expands it. Code can control the same state through the returned
handle.

## Duration and persistence
```

Replace with:

```markdown
Users can tap the capsule or activate it from the keyboard to toggle its mode;
a long press expands it. Code can control the same state through the returned
handle.

Some toasts have nothing meaningful to show in one of the two layouts — a
brief success toast with no message has nothing to reveal when expanded. Set
`expansionPolicy` to lock the toast to one layout for its lifetime:

```dart
CapsuleToastData.success(
  title: 'Saved',
  expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
);
```

`CapsuleToastExpansionPolicy.compactOnly` and `.expandedOnly` disable tap,
long-press, and `CapsuleToastHandle.expand()`/`collapse()` for as long as
that toast's content is showing. The default, `.adaptive`, is today's
toggle-between-both behavior. A restricted toast's `initialMode` must match
its policy (`compactOnly` requires `CapsuleToastMode.compact`,
`expandedOnly` requires `CapsuleToastMode.expanded`) — a mismatch throws in
debug mode. Resolving a `loading` toast into a different outcome is
unaffected: the resolved toast's own `expansionPolicy` takes over
immediately, regardless of what the loading toast's policy was.

## Duration and persistence
```

- [ ] **Step 2: Update the public API table**

In `README.md`, find:

```markdown
| `CapsuleToastType`, `CapsuleToastMode`, `CapsuleToastQueuePolicy` | Define semantics, layout, and queue behavior |
```

Replace with:

```markdown
| `CapsuleToastType`, `CapsuleToastMode`, `CapsuleToastQueuePolicy` | Define semantics, layout, and queue behavior |
| `CapsuleToastExpansionPolicy` | Locks a toast to compact-only or expanded-only layout |
```

- [ ] **Step 3: Add a CHANGELOG entry**

In `CHANGELOG.md`, find:

```markdown
## 1.0.0
```

Replace with:

```markdown
## Unreleased

- `CapsuleToastData.expansionPolicy` locks a toast to
  `CapsuleToastExpansionPolicy.compactOnly` or `.expandedOnly`, disabling
  tap, long-press, and handle-driven mode toggling for toasts whose
  expanded or compact layout has no meaningful content. Defaults to
  `.adaptive`, which is the existing toggle-both behavior — fully backward
  compatible.

## 1.0.0
```

- [ ] **Step 4: Run static analysis**

Run: `dart analyze`
Expected: No issues found (confirms the README code sample's identifiers
are all real symbols — a stale doc reference would not be caught by
`dart analyze`, so also visually confirm `CapsuleToastExpansionPolicy` and
`compactOnly` are spelled exactly as defined in Task 1).

- [ ] **Step 5: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: document CapsuleToastExpansionPolicy"
```
