// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:capsule_toast_example/capsule_toast_lab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lab demonstrates statuses queue and loading resolution', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CapsuleToastExampleApp());

    expect(find.text('Capsule Toast Lab'), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);
    expect(find.text('Loading → Success'), findsOneWidget);
    expect(find.text('Queue three'), findsOneWidget);
    expect(find.text('RTL'), findsOneWidget);
    expect(find.text('Reduced motion'), findsOneWidget);
    expect(find.text('Custom content'), findsOneWidget);
  });
}
