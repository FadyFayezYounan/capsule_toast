// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';

import '../model/capsule_toast_types.dart';

/// Animation phases for a single capsule toast presentation.
enum CapsuleLifecycleState {
  /// No toast is visible.
  hidden,

  /// Entrance seed geometry is active.
  seed,

  /// Compact layout is visible.
  compact,

  /// Expanded layout is visible.
  expanded,

  /// Exit collapse is in progress.
  collapsing,
}

/// Legal lifecycle transitions for one continuous capsule toast.
final class CapsuleLifecycle {
  CapsuleLifecycleState _state = CapsuleLifecycleState.hidden;
  CapsuleToastMode _mode = CapsuleToastMode.compact;
  CapsuleToastDismissReason? _pendingDismissal;

  /// Current animation phase.
  CapsuleLifecycleState get state => _state;

  /// Current compact or expanded layout mode.
  CapsuleToastMode get mode => _mode;

  /// First dismissal reason requested during the active presentation.
  CapsuleToastDismissReason? get pendingDismissal => _pendingDismissal;

  /// Starts a new presentation from [CapsuleLifecycleState.hidden].
  void begin(CapsuleToastMode mode) {
    if (!_requireState(
      CapsuleLifecycleState.hidden,
      transition: 'begin',
      legal: const <CapsuleLifecycleState>[CapsuleLifecycleState.hidden],
    )) {
      return;
    }
    _pendingDismissal = null;
    _mode = mode;
    _state = CapsuleLifecycleState.seed;
  }

  /// Completes entrance into the compact layout.
  void didAppear() {
    if (!_requireState(
      CapsuleLifecycleState.seed,
      transition: 'didAppear',
      legal: const <CapsuleLifecycleState>[CapsuleLifecycleState.seed],
    )) {
      return;
    }
    _state = CapsuleLifecycleState.compact;
  }

  /// Expands from the compact layout.
  void expand() {
    if (!_requireState(
      CapsuleLifecycleState.compact,
      transition: 'expand',
      legal: const <CapsuleLifecycleState>[CapsuleLifecycleState.compact],
    )) {
      return;
    }
    _mode = CapsuleToastMode.expanded;
    _state = CapsuleLifecycleState.expanded;
  }

  /// Collapses from the expanded layout.
  void collapse() {
    if (!_requireState(
      CapsuleLifecycleState.expanded,
      transition: 'collapse',
      legal: const <CapsuleLifecycleState>[CapsuleLifecycleState.expanded],
    )) {
      return;
    }
    _mode = CapsuleToastMode.compact;
    _state = CapsuleLifecycleState.compact;
  }

  /// Begins exit collapse and records the first [reason].
  void requestDismiss(CapsuleToastDismissReason reason) {
    if (!_requireState(
      null,
      transition: 'requestDismiss',
      legal: const <CapsuleLifecycleState>[
        CapsuleLifecycleState.compact,
        CapsuleLifecycleState.expanded,
      ],
    )) {
      return;
    }
    _pendingDismissal ??= reason;
    _state = CapsuleLifecycleState.collapsing;
  }

  /// Finishes exit and returns to [CapsuleLifecycleState.hidden].
  void didHide() {
    if (!_requireState(
      CapsuleLifecycleState.collapsing,
      transition: 'didHide',
      legal: const <CapsuleLifecycleState>[CapsuleLifecycleState.collapsing],
    )) {
      return;
    }
    _reset();
  }

  /// Returns to [CapsuleLifecycleState.hidden] without an exit ceremony.
  ///
  /// Used when a new presentation interrupts [CapsuleLifecycleState.collapsing]
  /// so the motion controller must not invoke its exit-completed callback.
  void abandon() {
    _reset();
  }

  void _reset() {
    _state = CapsuleLifecycleState.hidden;
    _mode = CapsuleToastMode.compact;
    _pendingDismissal = null;
  }

  bool _requireState(
    CapsuleLifecycleState? singleState, {
    required String transition,
    required List<CapsuleLifecycleState> legal,
  }) {
    final bool allowed = switch (singleState) {
      final CapsuleLifecycleState expected => _state == expected,
      null => legal.contains(_state),
    };
    if (allowed) {
      return true;
    }
    if (kDebugMode) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Invalid CapsuleLifecycle transition'),
        ErrorDescription('Cannot call $transition while in $_state.'),
        ErrorDescription('Legal states: ${legal.join(', ')}.'),
      ]);
    }
    return false;
  }
}
