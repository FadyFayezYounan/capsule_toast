// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/manager/capsule_toast_coordinator.dart';

void main() {
  test('enqueue is FIFO and queueLength excludes active', () async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle first = coordinator.show(
      CapsuleToastData.neutral(title: 'First'),
    );
    coordinator.show(CapsuleToastData.neutral(title: 'Second'));
    coordinator.show(CapsuleToastData.neutral(title: 'Third'));

    expect(coordinator.active!.data.title, 'First');
    expect(coordinator.queueLength, 2);
    first.dismiss();
    coordinator.finishActiveExit();
    expect(coordinator.active!.data.title, 'Second');
  });

  test('replace completes old handle and retains queued order', () async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle first = coordinator.show(
      CapsuleToastData.neutral(title: 'First'),
    );
    coordinator.show(CapsuleToastData.neutral(title: 'Queued'));
    coordinator.show(
      CapsuleToastData.error(title: 'Replacement'),
      queuePolicy: CapsuleToastQueuePolicy.replace,
    );

    expect((await first.closed).reason, CapsuleToastDismissReason.replaced);
    expect(coordinator.active!.data.title, 'Replacement');
    expect(coordinator.queueLength, 1);
  });

  test('overflow removes the oldest queued record', () async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator(
      maximumQueueLength: 1,
    );
    coordinator.show(CapsuleToastData.neutral(title: 'Active'));
    final CapsuleToastHandle overflowed = coordinator.show(
      CapsuleToastData.neutral(title: 'Old queued'),
    );
    coordinator.show(CapsuleToastData.neutral(title: 'New queued'));

    expect(
      (await overflowed.closed).reason,
      CapsuleToastDismissReason.queueOverflow,
    );
    expect(coordinator.queueLength, 1);
  });

  test('clearAndShow clears queued records and replaces active', () async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle active = coordinator.show(
      CapsuleToastData.neutral(title: 'Active'),
    );
    final CapsuleToastHandle queued = coordinator.show(
      CapsuleToastData.neutral(title: 'Queued'),
    );

    coordinator.show(
      CapsuleToastData.warning(title: 'Urgent'),
      queuePolicy: CapsuleToastQueuePolicy.clearAndShow,
    );

    expect((await active.closed).reason, CapsuleToastDismissReason.replaced);
    expect((await queued.closed).reason, CapsuleToastDismissReason.cleared);
    expect(coordinator.active!.data.title, 'Urgent');
    expect(coordinator.queueLength, 0);
  });

  test('host disposal completes active and queued handles', () async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle active = coordinator.show(
      CapsuleToastData.neutral(title: 'Active'),
    );
    final CapsuleToastHandle queued = coordinator.show(
      CapsuleToastData.neutral(title: 'Queued'),
    );

    coordinator.disposeWithReason(CapsuleToastDismissReason.hostDisposed);

    expect(
      (await active.closed).reason,
      CapsuleToastDismissReason.hostDisposed,
    );
    expect(
      (await queued.closed).reason,
      CapsuleToastDismissReason.hostDisposed,
    );
  });

  test('completed handles ignore later commands', () async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle handle = coordinator.show(
      CapsuleToastData.loading(title: 'Loading'),
    );
    coordinator.clear();
    coordinator.finishActiveExit();
    expect((await handle.closed).reason, CapsuleToastDismissReason.cleared);

    handle.expand();
    handle.resolve(CapsuleToastData.success(title: 'Too late'));
    handle.dismiss();

    expect(coordinator.active, isNull);
  });
}
