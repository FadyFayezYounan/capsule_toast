// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

void main() {
  test('all public behavior enums remain exhaustive and ordered', () {
    expect(CapsuleToastType.values, <CapsuleToastType>[
      CapsuleToastType.success,
      CapsuleToastType.information,
      CapsuleToastType.warning,
      CapsuleToastType.error,
      CapsuleToastType.loading,
      CapsuleToastType.neutral,
      CapsuleToastType.custom,
    ]);
    expect(CapsuleToastQueuePolicy.values, <CapsuleToastQueuePolicy>[
      CapsuleToastQueuePolicy.enqueue,
      CapsuleToastQueuePolicy.replace,
      CapsuleToastQueuePolicy.clearAndShow,
    ]);
    expect(CapsuleToastDismissReason.values.length, 8);
  });

  test('action defaults to dismissing when invoked', () {
    final CapsuleToastAction action = CapsuleToastAction(
      label: 'Retry',
      onPressed: () {},
    );

    expect(action.semanticLabel, isNull);
    expect(action.dismissOnInvoke, isTrue);
  });
}
