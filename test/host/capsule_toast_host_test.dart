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

  testWidgets('host uses explicit full-size body and presentation slots', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Size? bodySize;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 320,
          height: 640,
          child: CapsuleToastHost(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                bodySize = constraints.biggest;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    expect(bodySize, const Size(320, 640));
    expect(tester.getSize(find.byType(Overlay)), const Size(320, 640));
    // The host owns exactly one slot layout, the one hosting the presentation
    // Overlay. CapsuleToastViewport contributes its own layout below that
    // Overlay, so scope the finder rather than counting globally.
    expect(
      find.ancestor(
        of: find.byType(Overlay),
        matching: find.byType(CustomMultiChildLayout),
      ),
      findsOneWidget,
    );
    expect(find.byType(Stack), findsNothing);
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

  testWidgets('toast content with a Tooltip-bearing widget builds without '
      'a "No Overlay widget found" error', (WidgetTester tester) async {
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

    CapsuleToastHost.of(commandContext).show(
      CapsuleToastData.custom(
        title: 'Dismissible',
        compactBuilder: (BuildContext context, _) {
          return IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close),
            onPressed: () {},
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.close), findsOneWidget);
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
