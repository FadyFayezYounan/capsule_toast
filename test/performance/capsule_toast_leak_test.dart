// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('30 host mount/unmount cycles leak nothing', (
    WidgetTester tester,
  ) async {
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

      CapsuleToastHost.of(
        commandContext,
      ).show(CapsuleToastData.success(title: 'mount $i'));
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

  testWidgets('50 show/clear cycles on a persistent host leak nothing', (
    WidgetTester tester,
  ) async {
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
