// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:async';

import '../model/capsule_toast_action.dart';
import '../model/capsule_toast_data.dart';
import '../model/capsule_toast_handle.dart';
import '../model/capsule_toast_result.dart';
import '../model/capsule_toast_types.dart';

/// Mutable queue entry for one shown or waiting toast.
final class CapsuleToastRecord {
  /// Creates a record wired to [delegate] for live handle commands.
  factory CapsuleToastRecord.create({
    required int token,
    required CapsuleToastData data,
    required CapsuleToastHandleDelegate delegate,
  }) {
    final Completer<CapsuleToastResult> completer =
        Completer<CapsuleToastResult>();
    final CapsuleToastHandle handle = createCapsuleToastHandle(
      id: data.id,
      token: token,
      delegate: delegate,
      closed: completer.future,
      isCompleted: () => completer.isCompleted,
    );
    return CapsuleToastRecord._(
      token: token,
      data: data,
      handle: handle,
      completer: completer,
    );
  }

  CapsuleToastRecord._({
    required this.token,
    required this.data,
    required this.handle,
    required this._completer,
  }) : desiredMode = data.initialMode,
       revision = 0,
       dismissalVelocity = 0,
       _unresolved = data.type == CapsuleToastType.loading;

  /// Stable identity for coordinator routing.
  final int token;

  /// Current toast content; may be updated while active.
  CapsuleToastData data;

  /// Layout mode requested for this record.
  CapsuleToastMode desiredMode;

  /// Bumped when [data] is replaced in place (for example via [resolve]).
  int revision;

  /// First dismissal reason stored while exit animation runs.
  CapsuleToastDismissReason? pendingDismissal;

  /// Action associated with [CapsuleToastDismissReason.actionSelected].
  CapsuleToastAction? selectedAction;

  /// Upward swipe velocity captured at dismissal request time.
  double dismissalVelocity;

  final Completer<CapsuleToastResult> _completer;
  bool _unresolved;

  /// Whether this record still represents unresolved loading content.
  bool get isUnresolved => _unresolved;

  /// Live command surface for this record.
  final CapsuleToastHandle handle;

  /// Completes once when this record finishes its lifecycle.
  Future<CapsuleToastResult> get closed => _completer.future;

  /// Whether [closed] has already completed.
  bool get isCompleted => _completer.isCompleted;

  /// Clears the unresolved loading state after a successful [resolve].
  void clearUnresolved() {
    _unresolved = false;
  }

  /// Completes [closed] exactly once with [reason].
  void complete(CapsuleToastDismissReason reason) {
    if (_completer.isCompleted) {
      return;
    }
    _completer.complete(
      CapsuleToastResult(
        reason: reason,
        action: reason == CapsuleToastDismissReason.actionSelected
            ? selectedAction
            : null,
      ),
    );
  }
}
