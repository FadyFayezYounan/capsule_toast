// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import 'benchmark_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('idle overhead: host vs baseline', (WidgetTester tester) async {
    final Map<String, List<FrameTiming>> results =
        <String, List<FrameTiming>>{};
    for (final bool withHost in const <bool>[false, true]) {
      results[withHost ? 'with host' : 'baseline'] = await _collectIdle(
        tester,
        withHost: withHost,
      );
    }

    final List<FrameTiming> baseline = results['baseline']!;
    final List<FrameTiming> host = results['with host']!;
    for (final String metric in const <String>['build', 'raster']) {
      printBenchmarkRow('idle baseline', metric, baseline);
      printBenchmarkRow('idle with host', metric, host);
    }

    final double deltaP95Build =
        (percentileMs(host, 0.95, (FrameTiming t) => t.buildDuration) -
        percentileMs(baseline, 0.95, (FrameTiming t) => t.buildDuration));
    if (deltaP95Build > 4) {
      printBenchmarkWarning(
        'idle p95 build delta is ${deltaP95Build.toStringAsFixed(3)}ms '
        '(budget 4ms). Investigate the always-in-tree host/overlay cost.',
      );
    }
  });

  testWidgets('entrance animation frames', (WidgetTester tester) async {
    final List<FrameTiming> timings = await _runHostedScenario(tester, (
      BuildContext context,
    ) {
      CapsuleToastHost.of(
        context,
      ).show(CapsuleToastData.success(title: 'entrance'));
    }, frames: 120);
    _reportAndWarn('entrance', timings);
  });

  testWidgets('exit animation frames', (WidgetTester tester) async {
    final List<FrameTiming> timings = await _runHostedScenario(
      tester,
      (BuildContext context) {
        CapsuleToastHost.of(
          context,
        ).show(CapsuleToastData.success(title: 'exit'));
      },
      frames: 60,
      then: (BuildContext context) => CapsuleToastHost.of(context).clear(),
    );
    _reportAndWarn('exit', timings);
  });

  testWidgets('churn burst: 60 replace-policy shows', (
    WidgetTester tester,
  ) async {
    final List<FrameTiming> timings = await _runHostedScenario(tester, (
      BuildContext context,
    ) {
      final CapsuleToastManager manager = CapsuleToastHost.of(context);
      for (int i = 0; i < 60; i++) {
        manager.show(
          CapsuleToastData.success(title: 'burst $i'),
          queuePolicy: CapsuleToastQueuePolicy.replace,
        );
      }
    }, frames: 120);
    _reportAndWarn('churn burst', timings);
  });

  testWidgets('saturation burst: 100 enqueues at max queue 20', (
    WidgetTester tester,
  ) async {
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
  // ignore: use_build_context_synchronously
  drive(context);
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  if (then != null) {
    // ignore: use_build_context_synchronously
    then(context);
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }
  await collector.stop();
  return collector.timings;
}

void _reportAndWarn(String scenario, List<FrameTiming> timings) {
  for (final String metric in const <String>['build', 'raster']) {
    printBenchmarkRow(scenario, metric, timings);
  }
  final double p99Build = percentileMs(
    timings,
    0.99,
    (FrameTiming t) => t.buildDuration,
  );
  if (p99Build > 30) {
    printBenchmarkWarning(
      '$scenario p99 build is ${p99Build.toStringAsFixed(3)}ms '
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
  print(
    '$scenario dropped-frame ratio: ${(dropped * 100).toStringAsFixed(1)}%',
  );
}
