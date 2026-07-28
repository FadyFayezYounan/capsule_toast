// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

void main() {
  setUp(installExactGoldenComparator);
  testWidgets('seed geometry matches the reference', (
    WidgetTester tester,
  ) async {
    await pumpGoldenGrid(tester, <CapsuleToastData>[
      CapsuleToastData.information(title: 'Backup ready'),
    ], seedClipSize: const Size(84, 34));

    await expectLater(
      find.byKey(goldenBoundaryKey),
      matchesGoldenFile('goldens/capsule_toast_seed.png'),
    );
  });

  testWidgets('compact semantic states match the reference', (
    WidgetTester tester,
  ) async {
    await pumpGoldenGrid(tester, <CapsuleToastData>[
      CapsuleToastData.success(title: 'Saved'),
      CapsuleToastData.information(title: 'New information'),
      CapsuleToastData.warning(title: 'Connection unstable'),
      CapsuleToastData.error(title: 'Upload failed'),
      CapsuleToastData.loading(title: 'Uploading'),
      CapsuleToastData.neutral(title: 'Draft available'),
    ]);

    await expectLater(
      find.byKey(goldenBoundaryKey),
      matchesGoldenFile('goldens/capsule_toast_compact_states.png'),
    );
  });

  testWidgets('expanded semantic states match the reference', (
    WidgetTester tester,
  ) async {
    await pumpGoldenGrid(tester, <CapsuleToastData>[
      CapsuleToastData.success(
        title: 'Saved',
        message: 'Your changes are stored locally.',
        initialMode: CapsuleToastMode.expanded,
        primaryAction: CapsuleToastAction(label: 'View', onPressed: noop),
        secondaryAction: CapsuleToastAction(label: 'Dismiss', onPressed: noop),
      ),
      CapsuleToastData.information(
        title: 'Backup ready',
        message: 'Two files were added.',
        initialMode: CapsuleToastMode.expanded,
        primaryAction: CapsuleToastAction(label: 'Open', onPressed: noop),
        secondaryAction: CapsuleToastAction(label: 'Later', onPressed: noop),
      ),
      CapsuleToastData.warning(
        title: 'Connection unstable',
        message: 'Changes will sync when the network recovers.',
        initialMode: CapsuleToastMode.expanded,
        primaryAction: CapsuleToastAction(label: 'Retry', onPressed: noop),
        secondaryAction: CapsuleToastAction(label: 'Dismiss', onPressed: noop),
      ),
      CapsuleToastData.error(
        title: 'Upload failed',
        message: 'Check the connection and try again.',
        initialMode: CapsuleToastMode.expanded,
        primaryAction: CapsuleToastAction(label: 'Retry', onPressed: noop),
        secondaryAction: CapsuleToastAction(label: 'Dismiss', onPressed: noop),
      ),
      CapsuleToastData.loading(
        title: 'Uploading',
        message: 'Keeping this capsule open until resolve.',
        initialMode: CapsuleToastMode.expanded,
      ),
      CapsuleToastData.neutral(
        title: 'Draft available',
        message: 'Resume editing when you are ready.',
        initialMode: CapsuleToastMode.expanded,
        primaryAction: CapsuleToastAction(label: 'Open', onPressed: noop),
        secondaryAction: CapsuleToastAction(label: 'Discard', onPressed: noop),
      ),
    ]);

    await expectLater(
      find.byKey(goldenBoundaryKey),
      matchesGoldenFile('goldens/capsule_toast_expanded_states.png'),
    );
  });

  testWidgets('loading resolve matches the reference', (
    WidgetTester tester,
  ) async {
    await pumpGoldenGrid(tester, <CapsuleToastData>[
      CapsuleToastData.loading(title: 'Uploading'),
      CapsuleToastData.success(title: 'Uploaded'),
    ]);

    await expectLater(
      find.byKey(goldenBoundaryKey),
      matchesGoldenFile('goldens/capsule_toast_loading_resolve.png'),
    );
  });

  testWidgets('rtl and large text match the reference', (
    WidgetTester tester,
  ) async {
    await pumpGoldenGrid(
      tester,
      <CapsuleToastData>[
        CapsuleToastData.information(
          title: 'تم الحفظ',
          message: 'تمت إضافة ملفين.',
          initialMode: CapsuleToastMode.expanded,
          primaryAction: CapsuleToastAction(label: 'فتح', onPressed: noop),
          secondaryAction: CapsuleToastAction(label: 'لاحقاً', onPressed: noop),
        ),
        CapsuleToastData.success(
          title: 'Saved with a longer title for scale',
          compactAction: CapsuleToastAction(label: 'Undo', onPressed: noop),
        ),
      ],
      textDirection: TextDirection.rtl,
      textScaler: const TextScaler.linear(2),
    );

    await expectLater(
      find.byKey(goldenBoundaryKey),
      matchesGoldenFile('goldens/capsule_toast_rtl_large_text.png'),
    );
  });

  testWidgets('reduced motion matches the reference', (
    WidgetTester tester,
  ) async {
    await pumpGoldenGrid(tester, <CapsuleToastData>[
      CapsuleToastData.success(title: 'Saved'),
      CapsuleToastData.information(
        title: 'Backup ready',
        message: 'Two files were added.',
        initialMode: CapsuleToastMode.expanded,
        primaryAction: CapsuleToastAction(label: 'Open', onPressed: noop),
      ),
      CapsuleToastData.loading(title: 'Uploading'),
    ], disableAnimations: true);

    await expectLater(
      find.byKey(goldenBoundaryKey),
      matchesGoldenFile('goldens/capsule_toast_reduced_motion.png'),
    );
  });
}
