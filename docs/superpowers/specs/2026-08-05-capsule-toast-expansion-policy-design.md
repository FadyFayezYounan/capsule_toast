# Capsule Toast — expansion policy

**Date:** 2026-08-05
**Status:** Approved

## Goal

Every capsule toast today can freely toggle between `CapsuleToastMode.compact`
and `CapsuleToastMode.expanded` — via tap, long-press, or
`CapsuleToastHandle.expand()`/`collapse()`. That toggle is meaningless for some
content: a `success` toast with no `message` has nothing to reveal when
expanded, and some custom toasts only make sense in one layout.

Add a per-toast `expansionPolicy` so a caller can lock a toast to
`compactOnly` or `expandedOnly`, in addition to today's implicit behavior
(now named `adaptive`).

## Non-goals

- No changes to motion, geometry, gesture wiring, or how compact/expanded
  content is built. The policy only gates whether a mode transition is
  *allowed*, never how it looks or animates.
- No persistent restriction across `CapsuleToastHandle.resolve()`. A resolved
  toast is a brand-new `CapsuleToastData` with its own policy; the outgoing
  toast's restriction has no bearing on it. (See "`resolve()` is exempt by
  construction" below — this was explicitly confirmed during design.)

## Architecture

### 1. New enum: `CapsuleToastExpansionPolicy`

Added to `lib/src/model/capsule_toast_types.dart`, alongside the other
three-way `*Policy` enums (`CapsuleToastQueuePolicy`,
`CapsuleToastReducedMotionPolicy`, `CapsuleToastHapticPolicy`):

```dart
/// Whether a toast may toggle between compact and expanded layout.
enum CapsuleToastExpansionPolicy {
  /// Toggles between compact and expanded via tap, long-press, or the
  /// handle (today's behavior).
  adaptive,

  /// Locked to compact — cannot expand via any interaction or handle call.
  compactOnly,

  /// Locked to expanded — cannot collapse via any interaction or handle call.
  expandedOnly,
}
```

### 2. `CapsuleToastData` — new `expansionPolicy` field

Added to `lib/src/model/capsule_toast_data.dart` with the same treatment as
every other field:

- New constructor parameter, default `CapsuleToastExpansionPolicy.adaptive`,
  so every existing call site is unaffected.
- Threaded through all six named factories (`success`, `information`,
  `warning`, `error`, `loading`, `neutral`) and `custom`.
- Threaded through `copyWith`, `debugFillProperties`, `operator ==`, and
  `hashCode`, matching the existing field list.

Two new asserts sit alongside the existing combination checks (e.g. the
`persistent`/`displayDuration` pair) and catch a caller-supplied `initialMode`
that contradicts the policy at construction time:

```dart
assert(
  expansionPolicy != CapsuleToastExpansionPolicy.compactOnly ||
      initialMode == CapsuleToastMode.compact,
  'A compactOnly toast cannot have initialMode: expanded.',
),
assert(
  expansionPolicy != CapsuleToastExpansionPolicy.expandedOnly ||
      initialMode == CapsuleToastMode.expanded,
  'An expandedOnly toast cannot have initialMode: compact.',
),
```

Usage:

```dart
CapsuleToastData.success(
  title: 'Saved',
  expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
)

CapsuleToastData.custom(
  expandedBuilder: (context, details) => const BigCustomPanel(),
  initialMode: CapsuleToastMode.expanded,
  expansionPolicy: CapsuleToastExpansionPolicy.expandedOnly,
)
```

### 3. Enforcement: `CapsuleToastCoordinator.expand` / `collapse`

`expand(token)` and `collapse(token)` in
`lib/src/manager/capsule_toast_coordinator.dart` are the single chokepoint
every toggle path already goes through — tap-to-toggle, long-press-to-expand,
and `CapsuleToastHandle.expand()`/`collapse()` all call these. Guarding here
covers all of them at once, with the same silent-no-op contract the methods
already use for a stale token or a completed record:

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

This is an ongoing restriction: it blocks every toggle attempt for as long as
the current `data` is the active toast's content — not just its first frame.

### 4. `resolve()` is exempt by construction

`CapsuleToastCoordinator.resolve` does not call `expand`/`collapse`; it
replaces the record's content directly:

```dart
void resolve(int token, CapsuleToastData toast) {
  ...
  current.data = toast;              // full replace, not a merge
  current.clearUnresolved();
  current.revision += 1;
  current.desiredMode = toast.initialMode;   // set directly, no guard
  _notify();
}
```

`current.data` is replaced wholesale with the new `toast`, including its own
`expansionPolicy`, and `desiredMode` is set from the *new* toast's
`initialMode`. So a `loading` toast created with
`expansionPolicy: compactOnly` can `resolve()` into a `success` toast with
`expansionPolicy: expandedOnly` (or any other policy), and the new policy
takes effect immediately. The construction-time assert on the new
`CapsuleToastData` already guarantees its `initialMode` is consistent with its
own `expansionPolicy` — no additional check is needed at the resolve call
site.

### 5. What does *not* change

`CapsuleToastLayer` (gesture handling), `CapsuleToastRecord`,
`CapsuleToastHandle`, and `CapsuleMotionController` require no changes.
Tap-to-toggle and long-press-to-expand already only ever call
`coordinator.expand`/`collapse` — for a restricted toast those calls now
silently no-op, so the gesture becomes inert automatically. `desiredMode`
never drifts from its (assert-validated) initial value for a restricted
toast, so every downstream consumer of it — motion sync, size caching,
content building — behaves correctly with no modification.

## Testing

### `test/model/capsule_toast_data_test.dart`

1. `expansionPolicy` defaults to `adaptive` when omitted.
2. Constructing `compactOnly` with `initialMode: expanded` throws an
   assertion (and the equivalent for `expandedOnly` with `initialMode:
   compact`).
3. `copyWith` can change `expansionPolicy` independently of other fields.
4. `operator ==` and `hashCode` account for `expansionPolicy`.

### `test/manager/capsule_toast_coordinator_test.dart`

5. `expand(token)` is a no-op (record stays `compact`, no notify) when the
   active record's `expansionPolicy` is `compactOnly`.
6. `collapse(token)` is a no-op when the active record's `expansionPolicy` is
   `expandedOnly`.
7. `expand`/`collapse` behave exactly as today when `expansionPolicy` is
   `adaptive` (the default) — regression coverage.
8. `resolve()` from a `compactOnly` (or `expandedOnly`) loading record into a
   toast with a *different* `expansionPolicy` takes effect immediately: the
   new policy governs subsequent `expand`/`collapse` calls, not the old one.

### `test/widgets/capsule_toast_interaction_test.dart`

9. Tapping a `compactOnly` toast leaves it compact; tapping an `expandedOnly`
   toast leaves it expanded.
10. Long-pressing a `compactOnly` toast does not expand it.

## Documentation

- **README** — a short note under the toast configuration section
  introducing `expansionPolicy` and the three values, with the
  no-message-success example as motivation.
- **CHANGELOG** — a new entry: `CapsuleToastExpansionPolicy` and the
  `CapsuleToastData.expansionPolicy` field, defaulting to `adaptive` (fully
  backward compatible).

## Acceptance

- `CapsuleToastData.success(..., expansionPolicy: compactOnly)` cannot be
  expanded by tap, long-press, or `handle.expand()`.
- `CapsuleToastData.custom(..., expansionPolicy: expandedOnly, initialMode:
  expanded)` cannot be collapsed by tap or `handle.collapse()`.
- `expansionPolicy: adaptive` (the default) is behaviorally identical to the
  package's current behavior — no existing call site changes behavior.
- A restricted toast's policy does not constrain what it can `resolve()`
  into.
- `dart analyze` is clean and the full test suite passes.
