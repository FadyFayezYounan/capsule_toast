// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

void main() {
  test('semantic factories select type and leave copy caller-owned', () {
    final CapsuleToastData toast = CapsuleToastData.success(
      id: 'save',
      title: 'Saved',
      message: 'Your changes are available.',
    );

    expect(toast.id, 'save');
    expect(toast.type, CapsuleToastType.success);
    expect(toast.initialMode, CapsuleToastMode.compact);
    expect(toast.persistent, isFalse);
    expect(toast.title, 'Saved');
  });

  test('loading is persistent by default', () {
    final CapsuleToastData toast = CapsuleToastData.loading(title: 'Uploading');

    expect(toast.type, CapsuleToastType.loading);
    expect(toast.persistent, isTrue);
  });

  test('persistent and explicit duration are mutually exclusive', () {
    expect(
      () => CapsuleToastData.neutral(
        title: 'Invalid',
        persistent: true,
        displayDuration: Duration(seconds: 1),
      ),
      throwsAssertionError,
    );
  });

  test('negative displayDuration is rejected by constructor', () {
    expect(
      () => CapsuleToastData.neutral(
        title: 'Invalid',
        displayDuration: Duration(milliseconds: -1),
      ),
      throwsAssertionError,
    );
  });

  test('copyWith negative displayDuration throws', () {
    final CapsuleToastData toast = CapsuleToastData.success(title: 'Saved');

    expect(
      () => toast.copyWith(displayDuration: Duration(milliseconds: -1)),
      throwsAssertionError,
    );
  });
}
