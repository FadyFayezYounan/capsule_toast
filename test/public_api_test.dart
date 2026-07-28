// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:capsule_toast/capsule_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('README setup compiles against the public barrel', (
    tester,
  ) async {
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

    // Factories are not const; README samples omit const accordingly.
    final CapsuleToastHandle handle = CapsuleToastHost.of(
      commandContext,
    ).show(CapsuleToastData.success(title: 'Saved'));
    expect(handle.closed, isA<Future<CapsuleToastResult>>());
  });
}
