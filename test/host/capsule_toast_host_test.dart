// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

void main() {
  testWidgets('of returns the nearest host manager', (
    WidgetTester tester,
  ) async {
    late CapsuleToastManager outer;
    late CapsuleToastManager inner;

    await tester.pumpWidget(
      MaterialApp(
        home: CapsuleToastHost(
          child: Builder(
            builder: (BuildContext outerContext) {
              outer = CapsuleToastHost.of(outerContext);
              return CapsuleToastHost(
                child: Builder(
                  builder: (BuildContext innerContext) {
                    inner = CapsuleToastHost.of(innerContext);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(inner, isNot(same(outer)));
  });

  testWidgets('of explains how to install a missing host', (
    WidgetTester tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext value) {
          context = value;
          return const SizedBox();
        },
      ),
    );

    expect(
      () => CapsuleToastHost.of(context),
      throwsA(
        isA<FlutterError>().having(
          (FlutterError error) => error.message,
          'message',
          contains('MaterialApp.builder'),
        ),
      ),
    );
    expect(CapsuleToastHost.maybeOf(context), isNull);
  });

  testWidgets('toast animation does not rebuild the application child', (
    WidgetTester tester,
  ) async {
    int builds = 0;
    late BuildContext commandContext;
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return CapsuleToastHost(child: child!);
        },
        home: Builder(
          builder: (BuildContext context) {
            builds += 1;
            commandContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    CapsuleToastHost.of(
      commandContext,
    ).show(CapsuleToastData.success(title: 'Saved'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(builds, 1);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('disposing host completes active handles', (
    WidgetTester tester,
  ) async {
    late CapsuleToastHandle handle;
    await tester.pumpWidget(
      MaterialApp(
        home: CapsuleToastHost(
          child: Builder(
            builder: (BuildContext context) {
              handle = CapsuleToastHost.of(
                context,
              ).show(CapsuleToastData.success(title: 'Saved'));
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    final CapsuleToastResult result = await handle.closed;
    expect(result.reason, CapsuleToastDismissReason.hostDisposed);
  });
}
