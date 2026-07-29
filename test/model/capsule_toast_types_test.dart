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

  group('CapsuleToastGlyph.resolveFor', () {
    test('maps every toast type to a paintable glyph', () {
      const CapsuleToastGlyph automatic = CapsuleToastGlyph.automatic;
      expect(
        automatic.resolveFor(CapsuleToastType.success),
        CapsuleToastGlyph.success,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.information),
        CapsuleToastGlyph.information,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.warning),
        CapsuleToastGlyph.warning,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.error),
        CapsuleToastGlyph.error,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.loading),
        CapsuleToastGlyph.loading,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.neutral),
        CapsuleToastGlyph.neutral,
      );
      expect(
        automatic.resolveFor(CapsuleToastType.custom),
        CapsuleToastGlyph.neutral,
      );
    });

    test('never resolves to automatic', () {
      for (final CapsuleToastType type in CapsuleToastType.values) {
        expect(
          CapsuleToastGlyph.automatic.resolveFor(type),
          isNot(CapsuleToastGlyph.automatic),
        );
      }
    });

    test('returns an explicit glyph unchanged', () {
      expect(
        CapsuleToastGlyph.connectivity.resolveFor(CapsuleToastType.success),
        CapsuleToastGlyph.connectivity,
      );
      expect(
        CapsuleToastGlyph.error.resolveFor(CapsuleToastType.success),
        CapsuleToastGlyph.error,
      );
    });
  });
}
