// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

void main() {
  testWidgets('100 enqueues never exceed maximumQueueLength 20', (
    WidgetTester tester,
  ) async {
    late BuildContext commandContext;
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return CapsuleToastHost(maximumQueueLength: 20, child: child!);
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

    final CapsuleToastManager manager = CapsuleToastHost.of(commandContext);

    for (int i = 0; i < 100; i++) {
      manager.show(
        CapsuleToastData.success(title: 'overflow $i'),
        queuePolicy: CapsuleToastQueuePolicy.enqueue,
      );
    }

    // 1 active + at most 20 queued; queueLength counts only queued records,
    // and the coordinator evicts so the queue holds exactly maximumQueueLength.
    expect(
      manager.queueLength,
      20,
      reason: 'the queue must never exceed maximumQueueLength',
    );
    await tester.pump();

    manager.clear();
    await tester.pump();
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(manager.queueLength, 0);
    expect(
      tester.binding.transientCallbackCount,
      0,
      reason: 'saturation must not leak tickers',
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
