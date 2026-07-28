// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/capsule_toast_action.dart';
import '../model/capsule_toast_data.dart';
import '../model/capsule_toast_handle.dart';
import '../model/capsule_toast_types.dart';
import 'capsule_toast_manager.dart';
import 'capsule_toast_record.dart';

/// Host-owned FIFO toast queue with policy-driven promotion and completion.
final class CapsuleToastCoordinator extends ChangeNotifier
    implements CapsuleToastManager, CapsuleToastHandleDelegate {
  /// Creates a coordinator that retains at most [maximumQueueLength] queued
  /// records behind the active toast.
  CapsuleToastCoordinator({this.maximumQueueLength = 20})
    : assert(maximumQueueLength >= 0);

  /// Maximum number of records waiting behind [active].
  int maximumQueueLength;

  /// The record currently shown, if any.
  CapsuleToastRecord? active;

  final List<CapsuleToastRecord> _queue = <CapsuleToastRecord>[];
  int _nextToken = 0;
  bool _disposed = false;

  @override
  int get queueLength => _queue.length;

  @override
  CapsuleToastHandle show(
    CapsuleToastData toast, {
    CapsuleToastQueuePolicy queuePolicy = CapsuleToastQueuePolicy.enqueue,
  }) {
    _assertNotDisposed();
    final CapsuleToastRecord record = _createRecord(toast);
    if (active == null) {
      active = record;
      _notify();
      return record.handle;
    }

    switch (queuePolicy) {
      case CapsuleToastQueuePolicy.enqueue:
        _enqueue(record);
      case CapsuleToastQueuePolicy.replace:
        _completeRecord(active!, CapsuleToastDismissReason.replaced);
        active = record;
      case CapsuleToastQueuePolicy.clearAndShow:
        _completeQueued(CapsuleToastDismissReason.cleared);
        _completeRecord(active!, CapsuleToastDismissReason.replaced);
        active = record;
    }
    _notify();
    return record.handle;
  }

  @override
  void clear() {
    _assertNotDisposed();
    if (active == null && _queue.isEmpty) {
      return;
    }
    _completeQueued(CapsuleToastDismissReason.cleared);
    final CapsuleToastRecord? current = active;
    if (current != null && !current.isCompleted) {
      requestDismiss(current.token, CapsuleToastDismissReason.cleared);
    }
    _notify();
  }

  /// Updates [maximumQueueLength] and evicts oldest queued records if needed.
  void updateMaximumQueueLength(int value) {
    _assertNotDisposed();
    assert(value >= 0);
    maximumQueueLength = value;
    _enforceQueueLimit();
    _notify();
  }

  /// Invokes [action] when it matches the active record.
  void invokeAction(int token, CapsuleToastAction action) {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null || current.token != token) {
      return;
    }
    if (action.dismissOnInvoke) {
      current.selectedAction = action;
      requestDismiss(token, CapsuleToastDismissReason.actionSelected);
    }
    _invokeActionCallback(action);
    _notify();
  }

  /// Stores the first dismissal reason for [token] while exit is in progress.
  void requestDismiss(
    int token,
    CapsuleToastDismissReason reason, {
    double velocity = 0,
  }) {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null || current.token != token) {
      return;
    }
    if (current.pendingDismissal != null) {
      return;
    }
    current.pendingDismissal = reason;
    current.dismissalVelocity = velocity;
    _notify();
  }

  /// Requests a timeout dismissal for the active record.
  void timeoutActive() {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null) {
      return;
    }
    requestDismiss(current.token, CapsuleToastDismissReason.timedOut);
  }

  /// Completes the exiting active record and promotes the next queued record.
  void finishActiveExit() {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null) {
      return;
    }
    final CapsuleToastDismissReason reason =
        current.pendingDismissal ?? CapsuleToastDismissReason.dismissed;
    _completeRecord(current, reason);
    active = null;
    if (_queue.isNotEmpty) {
      active = _queue.removeAt(0);
    }
    _notify();
  }

  /// Completes every record with [reason] and disposes this coordinator.
  void disposeWithReason(CapsuleToastDismissReason reason) {
    if (_disposed) {
      return;
    }
    final CapsuleToastRecord? current = active;
    if (current != null) {
      _completeRecord(current, reason);
      active = null;
    }
    for (final CapsuleToastRecord record in _queue) {
      _completeRecord(record, reason);
    }
    _queue.clear();
    _disposed = true;
  }

  @override
  void dispose() {
    if (!_disposed) {
      disposeWithReason(CapsuleToastDismissReason.hostDisposed);
    }
    super.dispose();
  }

  @override
  void expand(int token) {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null || current.token != token || current.isCompleted) {
      return;
    }
    current.desiredMode = CapsuleToastMode.expanded;
    _notify();
  }

  @override
  void collapse(int token) {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null || current.token != token || current.isCompleted) {
      return;
    }
    current.desiredMode = CapsuleToastMode.compact;
    _notify();
  }

  @override
  void resolve(int token, CapsuleToastData toast) {
    _assertNotDisposed();
    final CapsuleToastRecord? current = active;
    if (current == null ||
        current.token != token ||
        current.isCompleted ||
        !current.isUnresolved) {
      return;
    }
    current.data = toast;
    current.clearUnresolved();
    current.revision += 1;
    current.desiredMode = toast.initialMode;
    _notify();
  }

  @override
  void dismiss(int token) {
    requestDismiss(token, CapsuleToastDismissReason.dismissed);
  }

  CapsuleToastRecord _createRecord(CapsuleToastData toast) {
    final int token = _nextToken++;
    return CapsuleToastRecord.create(token: token, data: toast, delegate: this);
  }

  void _enqueue(CapsuleToastRecord record) {
    _enforceQueueLimitBeforeAppend();
    if (_queue.length >= maximumQueueLength) {
      _completeRecord(record, CapsuleToastDismissReason.queueOverflow);
      return;
    }
    _queue.add(record);
  }

  void _enforceQueueLimitBeforeAppend() {
    while (_queue.length >= maximumQueueLength && _queue.isNotEmpty) {
      final CapsuleToastRecord overflowed = _queue.removeAt(0);
      _completeRecord(overflowed, CapsuleToastDismissReason.queueOverflow);
    }
  }

  void _enforceQueueLimit() {
    while (_queue.length > maximumQueueLength && _queue.isNotEmpty) {
      final CapsuleToastRecord overflowed = _queue.removeAt(0);
      _completeRecord(overflowed, CapsuleToastDismissReason.queueOverflow);
    }
  }

  void _completeQueued(CapsuleToastDismissReason reason) {
    for (final CapsuleToastRecord record in _queue) {
      _completeRecord(record, reason);
    }
    _queue.clear();
  }

  void _completeRecord(
    CapsuleToastRecord record,
    CapsuleToastDismissReason reason,
  ) {
    record.complete(reason);
  }

  void _invokeActionCallback(CapsuleToastAction action) {
    try {
      final Object? result = action.onPressed();
      if (result is Future<void>) {
        unawaited(
          result.catchError((Object error, StackTrace stackTrace) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stackTrace,
                library: 'capsule_toast',
              ),
            );
          }),
        );
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'capsule_toast',
        ),
      );
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _assertNotDisposed() {
    assert(
      !_disposed,
      'CapsuleToastCoordinator was disposed and cannot accept new work.',
    );
  }
}
