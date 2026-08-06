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
  run on any leaked coordinator, ticker, overlay entry, or record.

### Frame-time benchmarks (real device, report-only)

```sh
cd example
flutter test integration_test/benchmark -d <device>
```

Each scenario runs against the with-host and (for idle) no-host apps and
prints p50/p95/p99/max for build and raster in milliseconds, plus
the idle delta vs baseline and the dropped-frame ratio. Thresholds are soft:
violations print `WARNING:` lines and never fail the run.

## Measured numbers

iPhone 17 Pro simulator (iOS 26.1), Flutter 3.44.6, 2026-08-06.
Dropped-frame ratios on this run: 0-1.7%. Note the single entrance max
30.027ms outlier frame (p99 13.9ms).

| Scenario | Metric | p50 | p95 | p99 | max |
| --- | --- | --- | --- | --- | --- |
| idle baseline | build | 0.520 | 0.791 | 0.842 | 3.048 |
| idle with host | build | 0.366 | 0.606 | 0.696 | 0.698 |
| entrance | build | 1.905 | 4.853 | 13.915 | 30.027 |
| exit | build | 1.492 | 3.173 | 3.592 | 7.385 |
| churn burst | build | 2.018 | 3.020 | 4.090 | 15.610 |
| saturation | build | 1.923 | 3.294 | 8.815 | 8.943 |
