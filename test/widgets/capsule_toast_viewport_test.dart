// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/manager/capsule_toast_coordinator.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_viewport.dart';

void main() {
  testWidgets('viewport applies active toast placement theme', (tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    addTearDown(coordinator.dispose);
    coordinator.show(
      CapsuleToastData.neutral(
        title: 'Placed',
        persistent: true,
        theme: CapsuleToastThemeData(
          maximumWidth: 200,
          horizontalInset: 20,
          useSafeArea: true,
          verticalOffset: 8,
        ),
      ),
    );

    const Key childKey = ValueKey<String>('viewport-child');
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(300, 400),
          viewPadding: EdgeInsets.only(top: 30),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 300,
            height: 400,
            child: CapsuleToastViewport(
              coordinator: coordinator,
              child: const SizedBox(key: childKey, width: 250, height: 40),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(childKey)), const Size(200, 40));
    expect(tester.getTopLeft(find.byKey(childKey)), const Offset(50, 38));
  });

  testWidgets('viewport clamps exhausted space to non-negative constraints', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(100, 40);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    addTearDown(coordinator.dispose);
    coordinator.show(
      CapsuleToastData.neutral(
        title: 'Narrow',
        persistent: true,
        theme: CapsuleToastThemeData(
          horizontalInset: 80,
          useSafeArea: true,
          verticalOffset: 20,
        ),
      ),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(100, 40),
          viewPadding: EdgeInsets.only(top: 40),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 100,
            height: 40,
            child: CapsuleToastViewport(
              coordinator: coordinator,
              child: const SizedBox(width: 50, height: 30),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
