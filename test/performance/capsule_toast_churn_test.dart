// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

void main() {
  testWidgets(
    '60 show/clear cycles under mixed queue policies return to idle',
    (WidgetTester tester) async {
      final BuildContext commandContext = await pumpToast(
        tester,
        CapsuleToastData.success(title: 'cycle 0'),
      );
      final CapsuleToastManager manager = CapsuleToastHost.of(commandContext);

      const List<CapsuleToastQueuePolicy> policies = <CapsuleToastQueuePolicy>[
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

        expect(
          manager.queueLength,
          0,
          reason: 'queue must be empty after cycle $cycle',
        );
        expect(
          tester.binding.transientCallbackCount,
          0,
          reason: 'no tickers may survive cycle $cycle',
        );
        expect(
          tester.binding.hasScheduledFrame,
          isFalse,
          reason: 'no frames may be scheduled after cycle $cycle',
        );
      }
    },
  );
}
