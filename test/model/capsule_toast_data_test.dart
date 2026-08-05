// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

Widget customBuilder(BuildContext context, CapsuleToastContentContext details) {
  return const SizedBox();
}

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

  test('structured factories reject empty visible or semantic text', () {
    expect(() => CapsuleToastData.success(title: ''), throwsAssertionError);
    expect(
      () => CapsuleToastData.success(title: 'Saved', message: ''),
      throwsAssertionError,
    );
    expect(
      () => CapsuleToastData.success(title: 'Saved', semanticAnnouncement: ''),
      throwsAssertionError,
    );
  });

  test('displayDuration must be positive when present', () {
    expect(
      () => CapsuleToastData.neutral(
        title: 'Invalid',
        displayDuration: Duration.zero,
      ),
      throwsAssertionError,
    );
  });

  test('copyWith cannot bypass structured invariants', () {
    final CapsuleToastData toast = CapsuleToastData.success(
      title: 'Saved',
      message: 'Available offline.',
    );

    expect(() => toast.copyWith(title: null), throwsAssertionError);
    expect(() => toast.copyWith(message: ''), throwsAssertionError);
    expect(
      () => toast.copyWith(semanticAnnouncement: ''),
      throwsAssertionError,
    );
  });

  test('copyWith cannot remove the last custom builder or announcement', () {
    final CapsuleToastData toast = CapsuleToastData.custom(
      semanticAnnouncement: 'Custom status.',
      compactBuilder: customBuilder,
    );

    expect(() => toast.copyWith(compactBuilder: null), throwsAssertionError);
    expect(
      () => toast.copyWith(semanticAnnouncement: null),
      throwsAssertionError,
    );
  });

  test('expansionPolicy defaults to adaptive', () {
    final CapsuleToastData toast = CapsuleToastData.success(title: 'Saved');

    expect(toast.expansionPolicy, CapsuleToastExpansionPolicy.adaptive);
  });

  test('compactOnly rejects an expanded initialMode', () {
    expect(
      () => CapsuleToastData.success(
        title: 'Saved',
        expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
        initialMode: CapsuleToastMode.expanded,
      ),
      throwsAssertionError,
    );
  });

  test('expandedOnly rejects a compact initialMode', () {
    expect(
      () => CapsuleToastData.success(
        title: 'Saved',
        expansionPolicy: CapsuleToastExpansionPolicy.expandedOnly,
      ),
      throwsAssertionError,
    );
  });

  test('expandedOnly accepts a matching expanded initialMode', () {
    final CapsuleToastData toast = CapsuleToastData.success(
      title: 'Saved',
      expansionPolicy: CapsuleToastExpansionPolicy.expandedOnly,
      initialMode: CapsuleToastMode.expanded,
    );

    expect(toast.expansionPolicy, CapsuleToastExpansionPolicy.expandedOnly);
    expect(toast.initialMode, CapsuleToastMode.expanded);
  });

  test('copyWith can change expansionPolicy independently', () {
    final CapsuleToastData toast = CapsuleToastData.success(title: 'Saved');
    final CapsuleToastData copy = toast.copyWith(
      expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
    );

    expect(copy.expansionPolicy, CapsuleToastExpansionPolicy.compactOnly);
    expect(copy.title, 'Saved');
  });

  test('operator == and hashCode account for expansionPolicy', () {
    final CapsuleToastData a = CapsuleToastData.success(title: 'Saved');
    final CapsuleToastData b = CapsuleToastData.success(
      title: 'Saved',
      expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
    );

    expect(a == b, isFalse);
    expect(a.hashCode == b.hashCode, isFalse);
  });
}
