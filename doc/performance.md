# Capsule Toast Performance

## The performance contract

- **Zero per-frame work when idle.** With no toast active there are no tickers
  (`transientCallbackCount == 0`), no scheduled animation frames, and no
  pending `Timer`s. The motion ticker is created lazily on the first `show`
  and stopped and disposed when the system returns to rest.
- **No timer-based bookkeeping.** `LifecycleClock` is pure arithmetic driven
  by the ticker; the package never spins up `Timer`s.
- **No rebuild propagation.** `CapsuleToastHost` rebuilds cannot mark your
  app content dirty; an idle host passes zero frames to the app body.
- **The only permanent cost** is the always-in-tree toast layer: one
  `CustomMultiChildLayout` (host), one `Overlay` with a single persistent
  entry, one viewport layout, and a `SizedBox.shrink()` presentation.

## Per-host object inventory

For every `CapsuleToastHost` in your app tree:

| Object | Count | Lifetime |
| --- | --- | --- |
| `CapsuleToastCoordinator` | 1 | Host lifetime |
| `CapsuleMotionController` | 1 | Host lifetime |
| Motion `Ticker` | 0–1 | Created lazily on first show; disposed when idle |
| `OverlayEntry` | 1 | Host lifetime |
| Content/glyph tickers | 0–N | Only while a toast with animated content is visible |

More hosts mean more coordinators/controllers, but each is cheap (plain
`ChangeNotifier`s) and none of them tick while idle.

## How the assurance is tested

### Regression guards (deterministic, no device)

```sh
flutter test test/performance
```

- `capsule_toast_idle_cost_test.dart` — idle scheduler certificate and the
  no-rebuild probe.
- `capsule_toast_churn_test.dart` — 60 show/clear cycles under mixed queue
  policies return to idle after every cycle.
- `capsule_toast_saturation_test.dart` — the queue never exceeds
  `maximumQueueLength`, even with 100 enqueues.
- `capsule_toast_leak_test.dart` — 30 host mount/unmount cycles and 50
  show/clear cycles; leak tracking is enabled for the whole directory by
  `flutter_test_config.dart`, and the framework's leak reporter fails the
  run on any leaked coordinator, motion controller, ticker, or overlay
  entry.

### Frame-time benchmarks (real device, report-only)

```sh
cd example
flutter test integration_test/benchmark -d <device>
```

Each scenario runs against the with-host and (for idle) no-host apps and
prints p50/p95/p99/max for build and raster in milliseconds, plus the
dropped-frame ratio, plus a WARNING when the idle p95 build delta vs
baseline exceeds its 4ms budget. Thresholds are soft: violations print
`WARNING:` lines and never fail the run.

The entrance scenario stops pumping (and stops collecting) as soon as the
active capsule's motion snapshot reports `isSettled`; the exit scenario
stops when the coordinator reports no active record. Both carry a 300-frame
backstop so a settle-detection bug can never hang the run. The churn and
saturation bursts keep flat 120-frame windows (a burst is a burst; mixing
is inherent there).

Thresholds:

- **Idle p95 build delta vs baseline: 4ms.** At sub-millisecond scale the
  idle delta is within measurement noise on simulators, so this tripwire
  only detects 10x-style regressions; p99/max are the reliable animation
  signals.
- **Animation p99 build: 30ms.**
- **Dropped-frame ratio: 10%.** A frame counts as dropped when its
  build+raster work exceeds 16667µs (one 60Hz frame).

## Measured numbers

iPhone 17 Pro simulator (iOS 26.1), Flutter 3.44.6, 2026-08-06.
Entrance and exit windows are gated on the animation settling (see
benchmarks below): entrance collects ~16-17 frames and exit collects the
entrance settle plus the exit completion (~22 frames), so p50/p95 report
animation frames only. In the entrance window the single cold-start frame
that first builds the toast subtree (29.8ms this run; 19.9-36.0ms across
runs) lands on p95/p99/max — a known one-off, not sustained cost (p50
3.3ms). Dropped-frame ratios this run: entrance 12.5% (the cold frame
exceeds one 60Hz budget; occasionally a second frame joins it), all other
scenarios 0%. The idle p95 build delta vs baseline (with host 0.833ms vs
baseline 0.779ms this run) flips sign run to run (±0.05ms): at
sub-millisecond scale it is measurement noise on simulators, so the 4ms
tripwire only detects 10x-style regressions, and p99/max are the reliable
animation signals.

| Scenario | Metric | p50 | p95 | p99 | max |
| --- | --- | --- | --- | --- | --- |
| idle baseline | build | 0.542 | 0.779 | 1.957 | 2.342 |
| idle with host | build | 0.582 | 0.833 | 1.010 | 1.022 |
| entrance | build | 3.268 | 29.830 | 29.830 | 29.830 |
| exit | build | 2.923 | 5.251 | 9.432 | 9.432 |
| churn burst | build | 2.701 | 4.635 | 6.119 | 12.464 |
| saturation | build | 2.726 | 4.053 | 7.186 | 7.900 |
