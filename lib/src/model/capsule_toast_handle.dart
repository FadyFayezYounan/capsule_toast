// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:async';

import 'capsule_toast_data.dart';
import 'capsule_toast_result.dart';

/// Commands routed from a visible toast back to its host coordinator.
abstract interface class CapsuleToastHandleDelegate {
  /// Requests expanded layout for the toast identified by [token].
  ///
  /// A no-op if that toast's [CapsuleToastData.expansionPolicy] is
  /// [CapsuleToastExpansionPolicy.compactOnly].
  void expand(int token);

  /// Requests compact layout for the toast identified by [token].
  ///
  /// A no-op if that toast's [CapsuleToastData.expansionPolicy] is
  /// [CapsuleToastExpansionPolicy.expandedOnly].
  void collapse(int token);

  /// Replaces unresolved toast data for the toast identified by [token].
  void resolve(int token, CapsuleToastData toast);

  /// Requests dismissal for the toast identified by [token].
  void dismiss(int token);
}

/// Live command surface for one shown toast record.
abstract interface class CapsuleToastHandle {
  /// Optional stable identifier copied from the toast data.
  Object? get id;

  /// Completes once when the toast record finishes its lifecycle.
  Future<CapsuleToastResult> get closed;

  /// Whether [closed] has already completed.
  bool get isClosed;

  /// Requests expanded layout for this toast when it is active.
  ///
  /// A no-op if this toast's [CapsuleToastData.expansionPolicy] is
  /// [CapsuleToastExpansionPolicy.compactOnly].
  void expand();

  /// Requests compact layout for this toast when it is active.
  ///
  /// A no-op if this toast's [CapsuleToastData.expansionPolicy] is
  /// [CapsuleToastExpansionPolicy.expandedOnly].
  void collapse();

  /// Replaces unresolved toast content while preserving this handle.
  void resolve(CapsuleToastData toast);

  /// Requests explicit dismissal of this toast when it is active.
  void dismiss();
}

/// Concrete handle that forwards commands to a [CapsuleToastHandleDelegate].
final class _CapsuleToastHandle implements CapsuleToastHandle {
  _CapsuleToastHandle({
    required this.id,
    required this._token,
    required this._delegate,
    required this._closed,
    required this._isCompleted,
  });

  @override
  final Object? id;

  final int _token;
  final CapsuleToastHandleDelegate _delegate;
  final Future<CapsuleToastResult> _closed;
  final bool Function() _isCompleted;

  @override
  Future<CapsuleToastResult> get closed => _closed;

  @override
  bool get isClosed => _isCompleted();

  @override
  void expand() {
    if (isClosed) {
      return;
    }
    _delegate.expand(_token);
  }

  @override
  void collapse() {
    if (isClosed) {
      return;
    }
    _delegate.collapse(_token);
  }

  @override
  void resolve(CapsuleToastData toast) {
    if (isClosed) {
      return;
    }
    _delegate.resolve(_token, toast);
  }

  @override
  void dismiss() {
    if (isClosed) {
      return;
    }
    _delegate.dismiss(_token);
  }
}

/// Creates a [CapsuleToastHandle] bound to [token] and [delegate].
CapsuleToastHandle createCapsuleToastHandle({
  required Object? id,
  required int token,
  required CapsuleToastHandleDelegate delegate,
  required Future<CapsuleToastResult> closed,
  required bool Function() isCompleted,
}) {
  return _CapsuleToastHandle(
    id: id,
    token: token,
    delegate: delegate,
    closed: closed,
    isCompleted: isCompleted,
  );
}
