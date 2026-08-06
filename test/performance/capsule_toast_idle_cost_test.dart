// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_presentation.dart';

void main() {
  testWidgets('host with no toast leaves the scheduler fully idle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return CapsuleToastHost(child: child!);
        },
        home: const SizedBox(),
      ),
    );
    await tester.pump();

    expect(
      tester.binding.transientCallbackCount,
      0,
      reason: 'no tickers may exist while no toast is active',
    );
    expect(
      tester.binding.hasScheduledFrame,
      isFalse,
      reason: 'an idle host must not schedule animation frames',
    );

    final Finder presentationFinder = find.byType(CapsuleToastPresentation);
    expect(presentationFinder, findsOneWidget);
    final CapsuleToastPresentation presentation = tester
        .widget<CapsuleToastPresentation>(presentationFinder);
    expect(presentation.coordinator.active, isNull);
    expect(
      find.descendant(of: presentationFinder, matching: find.byType(SizedBox)),
      findsOneWidget,
      reason: 'an idle presentation renders only SizedBox.shrink()',
    );

    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
  });

  testWidgets('idle host does not rebuild or relayout app content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return CapsuleToastHost(child: child!);
        },
        home: const _BuildProbe(),
      ),
    );
    await tester.pump();

    _BuildProbeState probe = tester.state<_BuildProbeState>(
      find.byType(_BuildProbe),
    );
    final int buildsAfterMount = probe.builds;

    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    probe = tester.state<_BuildProbeState>(find.byType(_BuildProbe));
    expect(
      probe.builds,
      buildsAfterMount,
      reason: '60 idle frames must not rebuild app content',
    );
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
