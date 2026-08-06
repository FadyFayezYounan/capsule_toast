# Capsule Toast Performance Assurance Design

Date: 2026-08-06
Status: Approved for implementation planning

## Goal

Provide certainty that `capsule_toast` does not slow down apps that use it, through two complementary layers:

1. **Deterministic regression guards** — widget tests that fail in CI (or any `flutter test` run) the moment the package starts doing per-frame work, leaking resources, or propagating rebuilds when idle.
2. **Frame-time benchmarks** — `integration_test` on a real device/simulator that measures build/layout/raster cost of the package against a no-host baseline, reported with soft thresholds.

Both layers run locally for now. No GitHub Actions workflow in this iteration.

## Current Performance Facts (verified by reading the code)

- The motion ticker is created lazily (`_ensureTicker`) and stopped **and disposed** when idle (`_stopTickerIfIdle` in `capsule_motion_controller.dart:507`). No ticker exists while no toast is active.
- `LifecycleClock` is pure math (no `Timer`s anywhere in the package).
- `CapsuleToastCoordinator` is a plain `ChangeNotifier` with no timers.
- `CapsuleToastPresentation.build()` returns `SizedBox.shrink()` when `coordinator.active == null`.
- `_CapsuleToastScope.updateShouldNotify` returns `false` — host rebuilds cannot propagate into the app body.
- The always-in-tree cost is a constant: host `CustomMultiChildLayout` + one `Overlay` (one persistent `OverlayEntry`) + viewport `CustomMultiChildLayout` + `ListenableBuilder`.
- Per host, the package owns: 1 coordinator, 1 motion controller, 1 transient ticker. Content/glyph tickers exist only while a toast with animated content is visible.

The guards below lock these facts in so a future change cannot silently regress them.

## Section 1: Deterministic Regression Guards — `test/performance/`

Plain `flutter test` tests, no device, deterministic, fast.

### 1.1 Idle certificate

Pump a host with no toast, settle:

- `tester.binding.transientCallbackCount == 0` (no tickers).
- `tester.binding.hasScheduledFrame == false` (no scheduled animation frames).
- No pending `Timer`s. `testWidgets` already fails any test whose timers are still pending at teardown — the idle certificate relies on that automatic check (the test binding's `FakeAsync` is private, so there is no explicit in-test assertion).
- The presentation subtree renders `SizedBox.shrink()`.
- A build-count probe widget installed in the app body is **not** rebuilt across 60 subsequent idle pumps — proves no rebuild propagation into app content.

### 1.2 Churn

60+ show → settle → clear → settle cycles, mixing `replace`, `enqueue`, and `clearAndShow` queue policies. After each cycle:

- The idle certificate holds (ticker stopped and disposed, queue empty).
- No listener or controller accumulation (`coordinator` exposes `queueLength`; assert 0).

### 1.3 Queue saturation

- 100 enqueues against `maximumQueueLength: 20`.
- Queue never exceeds 20; overflow records complete with `CapsuleToastDismissReason.queueOverflow`.
- After `clear()` and settle, the idle certificate holds.

### 1.4 Leak / accumulation

- 30 host mount/unmount cycles, plus 50 show/clear cycles on a persistent host. `test/performance/flutter_test_config.dart` calls `LeakTesting.enable()` (leak tracking is opt-in; `leak_tracker_flutter_testing` added as a dev dependency), so every test in `test/performance/` is leak-checked automatically and the default reporter fails the run on any leaked coordinator, motion controller, ticker, overlay entry, or record. If the run reports framework-internal false positives, add targeted `IgnoredLeaks` entries with justification.
- Documents and asserts the per-host object inventory: exactly 1 coordinator + 1 motion controller + 1 transient ticker.

## Section 2: Frame-Time Benchmarks — `integration_test/benchmark/`

Adds `integration_test` (sdk) and `leak_tracker_flutter_testing` to dev dependencies.

### 2.1 Harness

A minimal benchmark app with two variants:

- **Baseline**: plain `MaterialApp`.
- **With host**: same app with `CapsuleToastHost` installed via `MaterialApp.builder` (the documented usage pattern).

Each scenario runs against both variants so the package's cost is measured as a **delta vs baseline**, not an absolute number.

### 2.2 Instrumentation

`WidgetsBinding.addTimingsCallback` accumulates `FrameTiming` per scenario window. Report p50 / p95 / p99 / max for build, layout, and raster.

### 2.3 Scenarios

1. **Idle** — 120 frames with no toast; measures the always-in-tree overhead.
2. **Entrance** — frames during the appearance animation.
3. **Exit** — frames during dismissal.
4. **Churn burst** — 60 back-to-back show/replace/clear; peak frame cost + dropped frames.
5. **Saturation** — 100 enqueues at max-queue-20; eviction cost stays flat (O(1)).

### 2.4 Output and thresholds

- Printed table: scenario × metric × percentile, plus delta vs baseline.
- Soft thresholds: generous enough to never flake on a slow simulator, strict enough to catch 10x-style regressions. Proposed starting values (tuned on first run): idle overhead p95 build+layout < 4ms; animation p99 < 30ms. Threshold violations print as loud warnings, not failures.
- Run: `flutter test integration_test/benchmark -d <device>`.

## Section 3: Documentation

### 3.1 `doc/performance.md` (new)

- The performance contract: zero per-frame work when idle; the only permanent cost is one layout + one overlay + one viewport in the tree.
- Per-host object inventory (answers the "lots of controllers" concern).
- How to run both layers and how to interpret the benchmark table.
- A "measured numbers" table to be filled in after the first benchmark run.

### 3.2 README

A short Performance section pointing to `doc/performance.md`.

## Non-Goals

- No GitHub Actions workflow (local-only runs chosen).
- No custom benchmarking framework — only `integration_test` + `FrameTiming`.
- No performance assertions on golden/widget layers.
- No changes to the package's runtime behavior — this iteration only adds tests, benchmarks, and documentation. If a benchmark reveals a regression, that is a follow-up design.

## Verification

- `flutter test` — all existing tests plus the new `test/performance/` guards pass.
- `flutter analyze` — clean.
- `flutter test integration_test/benchmark -d <device>` — runs, prints the table, fills in measured numbers in `doc/performance.md`.
