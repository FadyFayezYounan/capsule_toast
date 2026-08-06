// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:capsule_toast/capsule_toast.dart';

/// MaterialApp with an optional CapsuleToastHost, plus a captured context
/// used by scenarios to reach CapsuleToastHost.of().
class BenchmarkApp extends StatelessWidget {
  BenchmarkApp({super.key, required this.withHost});

  /// Whether the CapsuleToastHost overlay layer is installed.
  final bool withHost;

  /// Populated with the home Builder's context after first build.
  final ValueNotifier<BuildContext?> homeContext = ValueNotifier<BuildContext?>(
    null,
  );

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
    for (final FrameTiming timing in timings)
      select(timing).inMicroseconds / 1000,
  ]..sort();
  final int index = (values.length * p).ceil().clamp(1, values.length) - 1;
  return values[index];
}

/// Fraction of frames whose actual build+raster work exceeded one 60Hz
/// frame budget (16667µs), ignoring emulation/simulator latency in
/// [FrameTiming.totalSpan].
double droppedFrameRatio(List<FrameTiming> timings) {
  if (timings.isEmpty) {
    return 1;
  }
  int dropped = 0;
  for (final FrameTiming timing in timings) {
    if (timing.buildDuration + timing.rasterDuration >
        const Duration(microseconds: 16667)) {
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
    'layout' => (FrameTiming t) => t.buildDuration,
    'raster' => (FrameTiming t) => t.rasterDuration,
    _ => (FrameTiming t) => t.buildDuration,
  };
}

double _maxMs(
  List<FrameTiming> timings,
  Duration Function(FrameTiming) select,
) {
  double max = 0;
  for (final FrameTiming timing in timings) {
    final double ms = select(timing).inMicroseconds / 1000;
    if (ms > max) {
      max = ms;
    }
  }
  return max;
}
