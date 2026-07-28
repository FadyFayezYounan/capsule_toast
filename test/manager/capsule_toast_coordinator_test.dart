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
    coordinator.show(
      CapsuleToastData.neutral(title: 'Second'),
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
    );
    coordinator.show(
      CapsuleToastData.neutral(title: 'Third'),
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
    );

    expect(coordinator.active!.data.title, 'First');
    expect(coordinator.queueLength, 2);
    first.dismiss();
    coordinator.finishActiveExit();
    expect(coordinator.active!.data.title, 'Second');
  });

  test('show replaces the active toast by default', () async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle first = coordinator.show(
      CapsuleToastData.neutral(title: 'First'),
    );
    coordinator.show(CapsuleToastData.success(title: 'Second'));

    expect((await first.closed).reason, CapsuleToastDismissReason.replaced);
    expect(coordinator.active!.data.title, 'Second');
    expect(coordinator.queueLength, 0);
  });

  test('replace completes old handle and retains queued order', () async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle first = coordinator.show(
      CapsuleToastData.neutral(title: 'First'),
    );
    coordinator.show(
      CapsuleToastData.neutral(title: 'Queued'),
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
    );
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
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
    );
    coordinator.show(
      CapsuleToastData.neutral(title: 'New queued'),
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
    );

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
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
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
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
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

  test('maximumQueueLength zero rejects enqueue without retaining', () async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator(
      maximumQueueLength: 0,
    );
    coordinator.show(CapsuleToastData.neutral(title: 'Active'));
    final CapsuleToastHandle rejected = coordinator.show(
      CapsuleToastData.neutral(title: 'Rejected'),
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
    );

    expect(coordinator.queueLength, 0);
    expect(
      (await rejected.closed).reason,
      CapsuleToastDismissReason.queueOverflow,
    );
  });

  test('resolve updates active loading record in place', () {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    final CapsuleToastHandle handle = coordinator.show(
      CapsuleToastData.loading(title: 'Loading'),
    );

    expect(coordinator.active!.isUnresolved, isTrue);
    expect(coordinator.active!.revision, 0);

    handle.resolve(CapsuleToastData.success(title: 'Done'));

    expect(coordinator.active!.isUnresolved, isFalse);
    expect(coordinator.active!.data.title, 'Done');
    expect(coordinator.active!.revision, 1);
    expect(coordinator.active!.desiredMode, CapsuleToastMode.compact);
    expect(handle.isClosed, isFalse);
  });

  test('invokeAction dismisses active record when configured', () {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
    coordinator.show(CapsuleToastData.neutral(title: 'Active'));
    final int token = coordinator.active!.token;
    var invoked = false;
    final CapsuleToastAction action = CapsuleToastAction(
      label: 'Retry',
      onPressed: () {
        invoked = true;
      },
    );

    coordinator.invokeAction(token, action);

    expect(invoked, isTrue);
    expect(
      coordinator.active!.pendingDismissal,
      CapsuleToastDismissReason.actionSelected,
    );
    expect(coordinator.active!.selectedAction, action);
  });

  test('updateMaximumQueueLength evicts oldest queued records', () async {
    final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator(
      maximumQueueLength: 3,
    );
    coordinator.show(CapsuleToastData.neutral(title: 'Active'));
    final CapsuleToastHandle firstQueued = coordinator.show(
      CapsuleToastData.neutral(title: 'First queued'),
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
    );
    coordinator.show(
      CapsuleToastData.neutral(title: 'Second queued'),
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
    );
    coordinator.show(
      CapsuleToastData.neutral(title: 'Third queued'),
      queuePolicy: CapsuleToastQueuePolicy.enqueue,
    );

    expect(coordinator.queueLength, 3);

    coordinator.updateMaximumQueueLength(1);

    expect(
      (await firstQueued.closed).reason,
      CapsuleToastDismissReason.queueOverflow,
    );
    expect(coordinator.queueLength, 1);
    expect(coordinator.active!.data.title, 'Active');

    coordinator.active!.handle.dismiss();
    coordinator.finishActiveExit();
    expect(coordinator.active!.data.title, 'Third queued');
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
