# Capsule Toast Performance Assurance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add deterministic performance regression guards (widget tests), real-device frame-time benchmarks (`integration_test`), and performance documentation so users can be certain `capsule_toast` does not slow down their apps.

**Architecture:** Two independent assurance layers. (1) `test/performance/` widget tests that lock in the idle-cost contract (no tickers, no scheduled frames, no timers, no rebuild propagation) and prove churn/saturation/leak-free behavior — these run with plain `flutter test`, deterministic, no device. (2) `integration_test/benchmark/` benchmarks that measure build/layout/raster frame times on a real device against a no-host baseline, with report-only soft thresholds. A `doc/performance.md` documents the contract, the per-host object inventory, and how to run and read both layers.

**Tech Stack:** Flutter 3.44+, Dart 3.12+, `flutter_test` (leak tracking via `leak_tracker_flutter_testing`), `integration_test`.

## Global Constraints

- Runtime behavior of `lib/` must not change. Only tests, benchmarks, docs, and pubspec dev dependencies change.
- New Dart files start with the header `// Copyright 2026 The Capsule Toast Authors. All rights reserved.`
- Follow existing test conventions: reuse helpers from `test/support/test_app.dart` (e.g., `pumpToast`, `pumpToastHarness`, `capsuleToastTestApp`) where they fit.
- `flutter analyze` must stay clean; `flutter test` must stay green.
- Conventional commit messages (existing repo style: `test:`, `feat:`, `docs:`, `chore:`).
- Benchmarks run locally on a device/simulator: `flutter test integration_test/benchmark -d <device>`. No CI workflow in this iteration.
- Thresholds are soft: violations print warnings, never fail the run.

## File Structure

- Modify: `pubspec.yaml` — add dev deps `integration_test` (sdk) and `leak_tracker_flutter_testing: ^3.0.10`.
- Create: `test/performance/flutter_test_config.dart` — enables leak tracking for every test under `test/performance/`.
- Create: `test/performance/capsule_toast_idle_cost_test.dart` — idle scheduler certificate + no-rebuild-propagation probe.
- Create: `test/performance/capsule_toast_churn_test.dart` — 60 show/clear cycles return to idle.
- Create: `test/performance/capsule_toast_saturation_test.dart` — 100 enqueues never exceed `maximumQueueLength`.
- Create: `test/performance/capsule_toast_leak_test.dart` — host mount/unmount + toast cycles; framework leak reporter must stay silent.
- Create: `integration_test/benchmark/benchmark_harness.dart` — `BenchmarkApp`, `FrameTimingCollector`, percentile math, report printer, soft-threshold warnings.
- Create: `integration_test/benchmark/frame_time_benchmark_test.dart` — 5 scenarios (idle, entrance, exit, churn burst, saturation).
- Create: `doc/performance.md` — contract, inventory, how to run, measured-numbers table.
- Modify: `README.md` — add a Performance section linking `doc/performance.md`.

## Task 1: Baseline + dev dependencies + leak-tracking config

**Files:**
- Modify: `pubspec.yaml`
- Create: `test/performance/flutter_test_config.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: leak tracking active for all `test/performance/` tests (no imports needed by test files — it applies automatically).

- [ ] **Step 1: Confirm the baseline is green**

Run: `flutter test`
Expected: all existing tests pass.

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 2: Add dev dependencies**

Modify the `dev_dependencies:` section of `pubspec.yaml` to:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  integration_test:
    sdk: flutter
  leak_tracker_flutter_testing: ^3.0.10
```

- [ ] **Step 3: Resolve dependencies**

Run: `flutter pub get`
Expected: resolves cleanly.

- [ ] **Step 4: Create the leak-tracking config**

Create `test/performance/flutter_test_config.dart`:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  await testMain();
}
```

- [ ] **Step 5: Verify the config is picked up**

Create a scratch test `test/performance/_scratch_test.dart`:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scratch', (WidgetTester tester) async {
    expect(LeakTesting.enabled, isTrue);
  });
}
```

Run: `flutter test test/performance/_scratch_test.dart`
Expected: PASS (proves `LeakTesting.enabled` is true inside this directory).

Delete `_scratch_test.dart`.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock test/performance/flutter_test_config.dart
git commit -m "test: enable leak tracking and integration_test for performance suite"
```

## Task 2: Idle scheduler certificate

**Files:**
- Create: `test/performance/capsule_toast_idle_cost_test.dart`

**Interfaces:**
- Consumes: `CapsuleToastHost` (package public API).
- Produces: the idle certificate — any future change that leaves a ticker running, a frame scheduled, or rebuilds app content while no toast is active fails these tests.

- [ ] **Step 1: Write the failing tests**

Create `test/performance/capsule_toast_idle_cost_test.dart`:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_presentation.dart';

void main() {
  testWidgets('host with no toast leaves the scheduler fully idle',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return CapsuleToastHost(child: child!);
        },
        home: const SizedBox(),
      ),
    );
    await tester.pump();

    expect(tester.binding.transientCallbackCount, 0,
        reason: 'no tickers may exist while no toast is active');
    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: 'an idle host must not schedule animation frames');

    final Finder presentationFinder = find.byType(CapsuleToastPresentation);
    expect(presentationFinder, findsOneWidget);
    final CapsuleToastPresentation presentation =
        tester.widget<CapsuleToastPresentation>(presentationFinder);
    expect(presentation.coordinator.active, isNull);
    expect(
      find.descendant(
        of: presentationFinder,
        matching: find.byType(SizedBox),
      ),
      findsOneWidget,
      reason: 'an idle presentation renders only SizedBox.shrink()',
    );

    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
  });

  testWidgets('idle host does not rebuild or relayout app content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return CapsuleToastHost(child: child!);
        },
        home: const _BuildProbe(),
      ),
    );
    await tester.pump();

    _BuildProbeState probe =
        tester.state<_BuildProbeState>(find.byType(_BuildProbe));
    final int buildsAfterMount = probe.builds;

    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    probe = tester.state<_BuildProbeState>(find.byType(_BuildProbe));
    expect(probe.builds, buildsAfterMount,
        reason: '60 idle frames must not rebuild app content');
  });
}

class _BuildProbe extends StatefulWidget {
  const _BuildProbe();

  @override
  State<_BuildProbe> createState() => _BuildProbeState();
}

class _BuildProbeState extends State<_BuildProbe> {
  int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds += 1;
    return const SizedBox();
  }
}
```

- [ ] **Step 2: Run and verify it passes**

Run: `flutter test test/performance/capsule_toast_idle_cost_test.dart`
Expected: PASS. If it fails, the current package already violates the idle contract — investigate before continuing.

- [ ] **Step 3: Commit**

```bash
git add test/performance/capsule_toast_idle_cost_test.dart
git commit -m "test: guard idle host scheduler cost"
```

## Task 3: Churn returns to idle

**Files:**
- Create: `test/performance/capsule_toast_churn_test.dart`

**Interfaces:**
- Consumes: `pumpToast` from `test/support/test_app.dart`, `CapsuleToastHost.of`, `CapsuleToastManager`, `CapsuleToastData.success`, `CapsuleToastQueuePolicy` (public API).
- Produces: the churn certificate — 60 show/clear cycles under all three queue policies must return the system to the idle certificate every cycle.

- [ ] **Step 1: Write the failing test**

Create `test/performance/capsule_toast_churn_test.dart`:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('60 show/clear cycles under mixed queue policies return to idle',
      (WidgetTester tester) async {
    final BuildContext commandContext = await pumpToast(
      tester,
      CapsuleToastData.success(title: 'cycle 0'),
    );
    final CapsuleToastManager manager =
        CapsuleToastHost.of(commandContext);

    const List<CapsuleToastQueuePolicy> policies =
        <CapsuleToastQueuePolicy>[
      CapsuleToastQueuePolicy.replace,
      CapsuleToastQueuePolicy.enqueue,
      CapsuleToastQueuePolicy.clearAndShow,
    ];

    for (int cycle = 1; cycle <= 60; cycle++) {
      manager.show(
        CapsuleToastData.success(title: 'cycle $cycle'),
        queuePolicy: policies[cycle % policies.length],
      );
      await tester.pump();
      // Settle the entrance animation.
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      manager.clear();
      await tester.pump();
      // Settle the exit animation.
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(manager.queueLength, 0,
          reason: 'queue must be empty after cycle $cycle');
      expect(tester.binding.transientCallbackCount, 0,
          reason: 'no tickers may survive cycle $cycle');
      expect(tester.binding.hasScheduledFrame, isFalse,
          reason: 'no frames may be scheduled after cycle $cycle');
    }
  });
}
```

- [ ] **Step 2: Run and verify it passes**

Run: `flutter test test/performance/capsule_toast_churn_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/performance/capsule_toast_churn_test.dart
git commit -m "test: guard churn returns to idle"
```

## Task 4: Queue saturation stays bounded

**Files:**
- Create: `test/performance/capsule_toast_saturation_test.dart`

**Interfaces:**
- Consumes: `CapsuleToastHost(maximumQueueLength: ...)`, `CapsuleToastManager`, `CapsuleToastQueuePolicy.enqueue`.
- Produces: the saturation certificate — the queue can never exceed `maximumQueueLength` and the system returns to idle after `clear()`.

- [ ] **Step 1: Write the failing test**

Create `test/performance/capsule_toast_saturation_test.dart`:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

void main() {
  testWidgets('100 enqueues never exceed maximumQueueLength 20',
      (WidgetTester tester) async {
    late BuildContext commandContext;
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return CapsuleToastHost(
            maximumQueueLength: 20,
            child: child!,
          );
        },
        home: Builder(
          builder: (BuildContext context) {
            commandContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();

    final CapsuleToastManager manager =
        CapsuleToastHost.of(commandContext);

    for (int i = 0; i < 100; i++) {
      manager.show(
        CapsuleToastData.success(title: 'overflow $i'),
        queuePolicy: CapsuleToastQueuePolicy.enqueue,
      );
    }

    // 1 active + at most 20 queued; queueLength counts only queued records.
    expect(manager.queueLength, 19,
        reason: 'the queue must never exceed maximumQueueLength');
    await tester.pump();

    manager.clear();
    await tester.pump();
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(manager.queueLength, 0);
    expect(tester.binding.transientCallbackCount, 0,
        reason: 'saturation must not leak tickers');
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
```

- [ ] **Step 2: Run and verify it passes**

Run: `flutter test test/performance/capsule_toast_saturation_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/performance/capsule_toast_saturation_test.dart
git commit -m "test: guard queue saturation bound"
```

## Task 5: Leak-free cycles

**Files:**
- Create: `test/performance/capsule_toast_leak_test.dart`

**Interfaces:**
- Consumes: leak tracking enabled by Task 1's `flutter_test_config.dart`; `pumpToast` from `test/support/test_app.dart`.
- Produces: exercises 30 host mounts/unmounts and 50 persistent-host show/clear cycles; the framework leak reporter (fails the run on any leaked coordinator, motion controller, ticker, overlay entry, or record) is the oracle.

- [ ] **Step 1: Write the test**

Create `test/performance/capsule_toast_leak_test.dart`:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('30 host mount/unmount cycles leak nothing',
      (WidgetTester tester) async {
    for (int i = 0; i < 30; i++) {
      late BuildContext commandContext;
      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) {
            return CapsuleToastHost(child: child!);
          },
          home: Builder(
            builder: (BuildContext context) {
              commandContext = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();

      CapsuleToastHost.of(commandContext).show(
        CapsuleToastData.success(title: 'mount $i'),
      );
      await tester.pump();
      for (int j = 0; j < 8; j++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
    // Leak checking is enabled by test/performance/flutter_test_config.dart;
    // the framework's suite-level reporter fails this run on any leak.
  });

  testWidgets('50 show/clear cycles on a persistent host leak nothing',
      (WidgetTester tester) async {
    final BuildContext context = await pumpToast(
      tester,
      CapsuleToastData.success(title: 'persistent 0'),
    );
    final CapsuleToastManager manager = CapsuleToastHost.of(context);

    for (int i = 1; i <= 50; i++) {
      manager.show(
        CapsuleToastData.success(title: 'persistent $i'),
        queuePolicy: CapsuleToastQueuePolicy.replace,
      );
      await tester.pump();
      for (int j = 0; j < 10; j++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      manager.clear();
      await tester.pump();
      for (int j = 0; j < 10; j++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    expect(manager.queueLength, 0);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
```

- [ ] **Step 2: Run and verify**

Run: `flutter test test/performance/capsule_toast_leak_test.dart`
Expected: PASS.

If the run reports leaks: read the leak report. If a leak names a `capsule_toast` object (coordinator, motion controller, ticker, record, overlay entry), it is a real regression — stop and fix the leak in `lib/` before continuing. If it names framework-internal objects only (e.g., inspector, text input), add a targeted ignore in `test/performance/flutter_test_config.dart`:

```dart
LeakTesting.settings = LeakTesting.settings
    .withIgnored(...); // one entry per framework false positive, with comment
```

- [ ] **Step 3: Commit**

```bash
git add test/performance/capsule_toast_leak_test.dart
git commit -m "test: guard leak-free host cycles"
```

## Task 6: Benchmark harness

**Files:**
- Create: `integration_test/benchmark/benchmark_harness.dart`

**Interfaces:**
- Produces (consumed by Task 7):
  - `class BenchmarkApp extends StatelessWidget { const BenchmarkApp({super.key, required this.withHost}); final bool withHost; }` — pumps a `MaterialApp` whose home is a `Builder` that stores its context in a public `homeContext` field (see code below), and installs `CapsuleToastHost` via `MaterialApp.builder` when `withHost` is true.
  - `class FrameTimingCollector { FrameTimingCollector(); void start(); Future<void> stop(); List<FrameTiming> get timings; }` — wraps `WidgetsBinding.addTimingsCallback`.
  - `double percentileMs(List<FrameTiming> timings, double p, Duration Function(FrameTiming) select)` — pth percentile of a metric in milliseconds.
  - `double droppedFrameRatio(List<FrameTiming> timings)` — fraction of frames with `totalSpan > 16667µs`.
  - `void printBenchmarkRow(String scenario, String metric, double p50, double p95, double p99, double max)` and `void printBenchmarkWarning(String message)` — report formatting.

- [ ] **Step 1: Write the harness**

Create `integration_test/benchmark/benchmark_harness.dart`:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:capsule_toast/capsule_toast.dart';

/// MaterialApp with an optional CapsuleToastHost, plus a captured context
/// used by scenarios to reach CapsuleToastHost.of().
class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key, required this.withHost});

  /// Whether the CapsuleToastHost overlay layer is installed.
  final bool withHost;

  /// Populated with the home Builder's context after first build.
  final ValueNotifier<BuildContext?> homeContext = ValueNotifier<BuildContext?>(null);

  @override
  Widget build(BuildContext context) {
    final Widget home = Builder(
      builder: (BuildContext inner) {
        homeContext.value = inner;
        return const SizedBox.shrink();
      },
    );
    if (!withHost) {
      return MaterialApp(home: home);
    }
    return MaterialApp(
      builder: (BuildContext context, Widget? child) {
        return CapsuleToastHost(child: child!);
      },
      home: home,
    );
  }
}

/// Accumulates FrameTiming samples while started.
class FrameTimingCollector {
  FrameTimingCollector();

  final List<FrameTiming> _timings = <FrameTiming>[];
  bool _collecting = false;

  void _handleTimings(List<FrameTiming> timings) {
    if (_collecting) {
      _timings.addAll(timings);
    }
  }

  void start() {
    _collecting = true;
    WidgetsBinding.instance.addTimingsCallback(_handleTimings);
  }

  Future<void> stop() async {
    _collecting = false;
    WidgetsBinding.instance.removeTimingsCallback(_handleTimings);
  }

  List<FrameTiming> get timings => List<FrameTiming>.unmodifiable(_timings);
}

/// pth percentile (0..1) of [select] over [timings], in milliseconds.
double percentileMs(
  List<FrameTiming> timings,
  double p,
  Duration Function(FrameTiming) select,
) {
  if (timings.isEmpty) {
    return double.nan;
  }
  final List<double> values = <double>[
    for (final FrameTiming timing in timings) select(timing).inMicroseconds / 1000,
  ]..sort();
  final int index = (values.length * p).ceil().clamp(1, values.length) - 1;
  return values[index];
}

/// Fraction of frames whose total span exceeds one 60Hz vsync (16667µs).
double droppedFrameRatio(List<FrameTiming> timings) {
  if (timings.isEmpty) {
    return 1;
  }
  int dropped = 0;
  for (final FrameTiming timing in timings) {
    if (timing.totalSpan > const Duration(microseconds: 16667)) {
      dropped += 1;
    }
  }
  return dropped / timings.length;
}

/// Prints one report row aligned as `<scenario> <metric> p50 p95 p99 max`.
void printBenchmarkRow(
  String scenario,
  String metric,
  List<FrameTiming> timings,
) {
  // ignore: avoid_print
  print(
    '${scenario.padRight(14)} ${metric.padRight(8)} '
    '${percentileMs(timings, 0.50, _metric(metric)).toStringAsFixed(3).padLeft(8)} '
    '${percentileMs(timings, 0.95, _metric(metric)).toStringAsFixed(3).padLeft(8)} '
    '${percentileMs(timings, 0.99, _metric(metric)).toStringAsFixed(3).padLeft(8)} '
    '${_maxMs(timings, _metric(metric)).toStringAsFixed(3).padLeft(8)}',
  );
}

void printBenchmarkWarning(String message) {
  // ignore: avoid_print
  print('WARNING: $message');
}

Duration Function(FrameTiming) _metric(String metric) {
  return switch (metric) {
    'build' => (FrameTiming t) => t.buildDuration,
    'layout' => (FrameTiming t) => t.layoutDuration,
    'raster' => (FrameTiming t) => t.rasterDuration,
    _ => (FrameTiming t) => t.buildDuration,
  };
}

double _maxMs(List<FrameTiming> timings, Duration Function(FrameTiming) select) {
  double max = 0;
  for (final FrameTiming timing in timings) {
    final double ms = select(timing).inMicroseconds / 1000;
    if (ms > max) {
      max = ms;
    }
  }
  return max;
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add integration_test/benchmark/benchmark_harness.dart
git commit -m "feat: add frame-time benchmark harness"
```

## Task 7: Benchmark scenarios

**Files:**
- Create: `integration_test/benchmark/frame_time_benchmark_test.dart`

**Interfaces:**
- Consumes: everything produced by Task 6; `CapsuleToastData` factories; `CapsuleToastQueuePolicy`.
- Produces: the runnable benchmark — `flutter test integration_test/benchmark -d <device>` prints a per-scenario table plus baseline deltas and soft-threshold warnings.

- [ ] **Step 1: Write the scenarios**

Create `integration_test/benchmark/frame_time_benchmark_test.dart`:

```dart
// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import 'benchmark_harness.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('idle overhead: host vs baseline', (WidgetTester tester) async {
    final Map<String, List<FrameTiming>> results = <String, List<FrameTiming>>{};
    for (final bool withHost in const <bool>[false, true]) {
      results[withHost ? 'with host' : 'baseline'] = await _collectIdle(
        tester,
        withHost: withHost,
      );
    }

    final List<FrameTiming> baseline = results['baseline']!;
    final List<FrameTiming> host = results['with host']!;
    for (final String metric in const <String>['build', 'layout', 'raster']) {
      printBenchmarkRow('idle baseline', metric, baseline);
      printBenchmarkRow('idle with host', metric, host);
    }

    final double deltaP95BuildLayout = (percentileMs(
              host,
              0.95,
              (FrameTiming t) => t.buildDuration + t.layoutDuration,
            ) -
            percentileMs(
              baseline,
              0.95,
              (FrameTiming t) => t.buildDuration + t.layoutDuration,
            ));
    if (deltaP95BuildLayout > 4) {
      printBenchmarkWarning(
        'idle p95 build+layout delta is ${deltaP95BuildLayout.toStringAsFixed(3)}ms '
        '(budget 4ms). Investigate the always-in-tree host/overlay cost.',
      );
    }
  });

  testWidgets('entrance animation frames', (WidgetTester tester) async {
    final List<FrameTiming> timings = await _runHostedScenario(
      tester,
      (BuildContext context) {
        CapsuleToastHost.of(context).show(
          CapsuleToastData.success(title: 'entrance'),
        );
      },
      frames: 120,
    );
    _reportAndWarn('entrance', timings);
  });

  testWidgets('exit animation frames', (WidgetTester tester) async {
    final List<FrameTiming> timings = await _runHostedScenario(
      tester,
      (BuildContext context) {
        CapsuleToastHost.of(context).show(
          CapsuleToastData.success(title: 'exit'),
        );
      },
      frames: 60,
      then: (BuildContext context) => CapsuleToastHost.of(context).clear(),
    );
    _reportAndWarn('exit', timings);
  });

  testWidgets('churn burst: 60 replace-policy shows', (WidgetTester tester) async {
    final List<FrameTiming> timings = await _runHostedScenario(
      tester,
      (BuildContext context) {
        final CapsuleToastManager manager = CapsuleToastHost.of(context);
        for (int i = 0; i < 60; i++) {
          manager.show(
            CapsuleToastData.success(title: 'burst $i'),
            queuePolicy: CapsuleToastQueuePolicy.replace,
          );
        }
      },
      frames: 120,
    );
    _reportAndWarn('churn burst', timings);
  });

  testWidgets('saturation burst: 100 enqueues at max queue 20',
      (WidgetTester tester) async {
    final List<FrameTiming> timings = await _runHostedScenario(
      tester,
      (BuildContext context) {
        final CapsuleToastManager manager = CapsuleToastHost.of(context);
        for (int i = 0; i < 100; i++) {
          manager.show(
            CapsuleToastData.success(title: 'saturation $i'),
            queuePolicy: CapsuleToastQueuePolicy.enqueue,
          );
        }
      },
      frames: 120,
      then: (BuildContext context) => CapsuleToastHost.of(context).clear(),
    );
    _reportAndWarn('saturation', timings);
  });
}

Future<List<FrameTiming>> _collectIdle(
  WidgetTester tester, {
  required bool withHost,
}) async {
  final BenchmarkApp app = BenchmarkApp(withHost: withHost);
  await tester.pumpWidget(app);
  await tester.pump(const Duration(milliseconds: 100));

  final FrameTimingCollector collector = FrameTimingCollector()..start();
  for (int i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await collector.stop();
  return collector.timings;
}

Future<List<FrameTiming>> _runHostedScenario(
  WidgetTester tester,
  void Function(BuildContext context) drive, {
  required int frames,
  void Function(BuildContext context)? then,
}) async {
  final BenchmarkApp app = BenchmarkApp(withHost: true);
  await tester.pumpWidget(app);
  await tester.pump(const Duration(milliseconds: 100));

  final BuildContext context = app.homeContext.value!;
  final FrameTimingCollector collector = FrameTimingCollector()..start();
  drive(context);
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  if (then != null) {
    then(context);
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }
  await collector.stop();
  return collector.timings;
}

void _reportAndWarn(String scenario, List<FrameTiming> timings) {
  for (final String metric in const <String>['build', 'layout', 'raster']) {
    printBenchmarkRow(scenario, metric, timings);
  }
  final double p99BuildLayout = percentileMs(
    timings,
    0.99,
    (FrameTiming t) => t.buildDuration + t.layoutDuration,
  );
  if (p99BuildLayout > 30) {
    printBenchmarkWarning(
      '$scenario p99 build+layout is ${p99BuildLayout.toStringAsFixed(3)}ms '
      '(budget 30ms).',
    );
  }
  final double dropped = droppedFrameRatio(timings);
  if (dropped > 0.1) {
    printBenchmarkWarning(
      '$scenario dropped-frame ratio is ${(dropped * 100).toStringAsFixed(1)}% '
      '(budget 10%).',
    );
  }
  // ignore: avoid_print
  print('$scenario dropped-frame ratio: ${(dropped * 100).toStringAsFixed(1)}%');
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 3: Run on a device**

Run: `flutter test integration_test/benchmark -d <device>` (use any connected simulator/device; on macOS: `-d macos` or an iOS simulator).

Expected: prints five scenario tables (idle baseline, idle with host, entrance, exit, churn burst, saturation) with p50/p95/p99/max columns in ms, the idle delta, and any `WARNING:` lines. No test failures.

If the idle p95 build+layout delta exceeds 4ms, or any animation p99 exceeds 30ms, do not change code in this task — the numbers go into `doc/performance.md` (Task 8) and are the starting point for a follow-up optimization design.

- [ ] **Step 4: Commit**

```bash
git add integration_test/benchmark/frame_time_benchmark_test.dart
git commit -m "feat: add frame-time benchmark scenarios"
```

## Task 8: Performance documentation

**Files:**
- Create: `doc/performance.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: Task 7's measured numbers (optional — the table ships as a template even if no device was available).

- [ ] **Step 1: Write `doc/performance.md`**

Create `doc/performance.md`:

```markdown
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
flutter test integration_test/benchmark -d <device>
```

Each scenario runs against the with-host and (for idle) no-host apps and
prints p50/p95/p99/max for build, layout, and raster in milliseconds, plus
the idle delta vs baseline and the dropped-frame ratio. Thresholds are soft:
violations print `WARNING:` lines and never fail the run.

## Measured numbers

Filled in on the first benchmark run (device, date):

| Scenario | Metric | p50 | p95 | p99 | max |
| --- | --- | --- | --- | --- | --- |
| idle baseline | build+layout | | | | |
| idle with host | build+layout | | | | |
| entrance | build+layout | | | | |
| exit | build+layout | | | | |
| churn burst | build+layout | | | | |
| saturation | build+layout | | | | |
```

- [ ] **Step 2: Fill in measured numbers**

If a device was available in Task 7, copy the printed values into the table (and note the device and date). If not, leave the template and note it in the commit message.

- [ ] **Step 3: Add the README section**

Append a `## Performance` section to `README.md`:

```markdown
## Performance

`capsule_toast` performs zero per-frame work when idle — no tickers, no
timers, no rebuild propagation — and its only permanent cost is a single
overlay layer. Regression guards and frame-time benchmarks verify this
continuously. See [doc/performance.md](doc/performance.md) for the full
contract, the per-host object inventory, and how to run the benchmarks.
```

- [ ] **Step 4: Full verification**

Run: `flutter analyze`
Expected: no issues.

Run: `flutter test`
Expected: all tests pass, including the new `test/performance/` guards.

- [ ] **Step 5: Commit**

```bash
git add doc/performance.md README.md
git commit -m "docs: document performance contract and benchmarks"
```

## Self-Review Notes

- **Spec coverage:** idle certificate (1.1) → Task 2; churn (1.2) → Task 3; saturation (1.3) → Task 4; leak (1.4) → Task 5; harness + scenarios (2.1–2.4) → Tasks 6–7; docs (3.1–3.2) → Task 8; dev deps (2.0) → Task 1.
- **Known deviation from spec:** the spec's `fake_async` plan was replaced by the framework's automatic pending-timer teardown check (the test binding's `FakeAsync` is private); `LeakTesting.collectGarbage()` was replaced by directory-scoped `LeakTesting.enable()` (leak tracking is opt-in). The spec was updated to match.
- **Type consistency:** `BenchmarkApp.homeContext` is a `ValueNotifier<BuildContext?>`; `FrameTimingCollector` exposes `start()/stop()/timings`; `percentileMs`/`droppedFrameRatio`/`printBenchmarkRow`/`printBenchmarkWarning` signatures are used identically in Task 7.
